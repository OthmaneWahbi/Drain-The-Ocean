"""Assemble les images du robot photographe en planches (3 × 3 par sujet) pour les regarder vite.

    python3 tools/planches.py DOSSIER_DES_IMAGES DOSSIER_DES_PLANCHES

Les images `robot_<sujet>_<vue>.png` d'un même sujet vont sur une planche `<sujet>.png`, chaque
vue réduite à 480 × 270 avec son nom écrit dessous. Les tours (`robot_tour_*`, `robot_nuit_*`)
vont sur des planches de 9.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

W, H = 480, 270


def sheet(paths, out):
    cols = 3
    rows = (len(paths) + cols - 1) // cols
    img = Image.new("RGB", (W * cols, (H + 18) * rows), (20, 20, 20))
    draw = ImageDraw.Draw(img)
    for i, p in enumerate(paths):
        x, y = (i % cols) * W, (i // cols) * (H + 18)
        img.paste(Image.open(p).convert("RGB").resize((W, H)), (x, y))
        draw.text((x + 4, y + H + 3), os.path.basename(p)[:-4], fill=(230, 230, 230))
    img.save(out)


def main(src, dst):
    os.makedirs(dst, exist_ok=True)
    groups = {}
    for name in sorted(os.listdir(src)):
        m = re.match(r"robot_(.+)_(\w+)\.png$", name)
        if not m:
            continue
        subject = m.group(1)
        groups.setdefault(subject, []).append(os.path.join(src, name))
    for subject, paths in groups.items():
        for k in range(0, len(paths), 9):
            sheet(paths[k:k + 9], os.path.join(dst, "%s%s.png" % (subject, "" if k == 0 else "_%d" % (k // 9))))
    print("%d planches" % len(groups))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
