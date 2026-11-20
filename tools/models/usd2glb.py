# Convertit un .usda de Quaternius (couleurs par matériau, sans texture) en GLB à aplats.
# Un nœud par Xform de premier niveau (ex. « Windmill », « Windmill_Blades »), sommets dans le
# repère du monde (Y en haut), normales plates. Usage : usd2glb.py source.usda sortie.glb
import sys, numpy as np, pygltflib as G
from pxr import Usd, UsdGeom, UsdShade
src, dst = sys.argv[1], sys.argv[2]
st = Usd.Stage.Open(src)
cache = UsdGeom.XformCache()
up = UsdGeom.GetStageUpAxis(st)
def matcolor(prim):
    mat, _ = UsdShade.MaterialBindingAPI(prim).ComputeBoundMaterial()
    if not mat: return (0.7, 0.7, 0.7), "default"
    for c in mat.GetPrim().GetAllChildren():
        sh = UsdShade.Shader(c)
        if sh:
            i = sh.GetInput('diffuseColor')
            if i and i.Get() is not None: return tuple(i.Get()), mat.GetPrim().GetName()
    return (0.7, 0.7, 0.7), mat.GetPrim().GetName()
root = st.GetDefaultPrim()
groups = []  # (nom, {(couleur, nom matériau): [positions]})
for top in root.GetChildren():
    if not top.IsA(UsdGeom.Xform): continue
    g = {}
    for prim in Usd.PrimRange(top):
        if not prim.IsA(UsdGeom.Mesh): continue
        m = UsdGeom.Mesh(prim)
        pts = m.GetPointsAttr().Get()
        if pts is None: continue
        M = np.array(cache.GetLocalToWorldTransform(prim))
        P = np.c_[np.array(pts, dtype=np.float64), np.ones(len(pts))] @ M
        P = P[:, :3]
        if up == 'Z': P = P[:, [0, 2, 1]] * np.array([1, 1, -1])
        counts = list(m.GetFaceVertexCountsAttr().Get()); idx = list(m.GetFaceVertexIndicesAttr().Get())
        faces = []; o = 0
        for c in counts: faces.append(idx[o:o + c]); o += c
        assign = {}
        for s in UsdGeom.Subset.GetAllGeomSubsets(m):
            col = matcolor(s.GetPrim())
            for fi in s.GetIndicesAttr().Get(): assign[fi] = col
        base = matcolor(prim)
        for fi, f in enumerate(faces):
            key = assign.get(fi, base)
            lst = g.setdefault(key, [])
            for k in range(1, len(f) - 1):
                lst += [P[f[0]], P[f[k]], P[f[k + 1]]]
    groups.append((top.GetName(), g))
gl = G.GLTF2(); blob = b''; mats = {}
gl.scenes = [G.Scene(nodes=[])]
for name, g in groups:
    prims = []
    for (col, mname), pos in g.items():
        pos = np.array(pos, dtype=np.float32)
        tri = pos.reshape(-1, 3, 3); n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
        n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
        nor = np.repeat(n, 3, axis=0).astype(np.float32)
        for arr in (pos, nor):
            b = arr.tobytes(); gl.bufferViews.append(G.BufferView(buffer=0, byteOffset=len(blob), byteLength=len(b))); blob += b
            acc = G.Accessor(bufferView=len(gl.bufferViews) - 1, componentType=G.FLOAT, count=len(arr), type='VEC3')
            if arr is pos: acc.min = pos.min(0).tolist(); acc.max = pos.max(0).tolist()
            gl.accessors.append(acc)
        if (col, mname) not in mats:
            mats[(col, mname)] = len(gl.materials)
            gl.materials.append(G.Material(name=mname, pbrMetallicRoughness=G.PbrMetallicRoughness(baseColorFactor=[*col, 1], metallicFactor=0, roughnessFactor=0.9)))
        prims.append(G.Primitive(attributes=G.Attributes(POSITION=len(gl.accessors) - 2, NORMAL=len(gl.accessors) - 1), material=mats[(col, mname)]))
    if not prims: continue
    gl.meshes.append(G.Mesh(name=name, primitives=prims))
    gl.nodes.append(G.Node(name=name, mesh=len(gl.meshes) - 1))
    gl.scenes[0].nodes.append(len(gl.nodes) - 1)
gl.buffers = [G.Buffer(byteLength=len(blob))]; gl.set_binary_blob(blob); gl.save_binary(dst)
print(dst, [(n, sum(len(p) for p in g.values()) // 3) for n, g in groups])
