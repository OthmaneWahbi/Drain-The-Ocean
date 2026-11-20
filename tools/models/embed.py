# Convertit un glTF/GLB (fichiers externes : .bin, textures) en un GLB autonome.
import sys, os, pygltflib as G
src, dst = sys.argv[1], sys.argv[2]
g = G.GLTF2().load(src)
base = os.path.dirname(src)
g.convert_buffers(G.BufferFormat.BINARYBLOB)
# Les images externes deviennent des bufferViews dans le blob.
blob = bytearray(g.binary_blob() or b"")
for im in g.images:
    if im.uri and not im.uri.startswith("data:"):
        data = open(os.path.join(base, im.uri), "rb").read()
        while len(blob) % 4: blob.append(0)
        g.bufferViews.append(G.BufferView(buffer=0, byteOffset=len(blob), byteLength=len(data)))
        blob += data
        im.bufferView = len(g.bufferViews) - 1
        im.mimeType = "image/png" if im.uri.lower().endswith(".png") else "image/jpeg"
        im.uri = None
g.buffers[0].byteLength = len(blob)
g.set_binary_blob(bytes(blob))
g.save_binary(dst)
print("ok", dst, len(blob))
