#!/usr/bin/env python3
"""Flat-shaded STL renderer used for the images in docs/img/renders/.

Needs numpy, matplotlib and Pillow. Examples (from the repo root):
  python3 tools/render_stl.py box.png "" stl/                      # assembled box
  python3 tools/render_stl.py parts.png "" stl/ --explode 35       # six pieces pulled apart
  python3 tools/render_stl.py pair.png "" stl/body_knife_A.stl stl/body_knife_B.stl --offsetB 25 --elev 38 --azim -50
The second argument (title) is unused and kept for compatibility.
"""
import sys, struct, glob, os, argparse
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

def load(f):
    d = open(f, 'rb').read()
    if d[:5] == b'solid' and b'facet' in d[:300]:
        v = [list(map(float, l.split()[1:])) for l in d.decode().splitlines() if l.strip().startswith('vertex')]
        return np.array(v).reshape(-1, 3, 3)
    n = struct.unpack('<I', d[80:84])[0]
    a = np.frombuffer(d[84:84 + n * 50], dtype=np.dtype([('n', '<3f4'), ('v', '<9f4'), ('a', '<u2')]))
    return a['v'].reshape(-1, 3, 3).astype(float)

COL = {'knife_A': '#4e79a7', 'knife_B': '#76b7b2', 'fork_A': '#f28e2b', 'fork_B': '#edc948',
       'spoon_A': '#e15759', 'spoon_B': '#b07aa1'}

ap = argparse.ArgumentParser()
ap.add_argument('out'); ap.add_argument('title')
ap.add_argument('files', nargs='+')
ap.add_argument('--explode', type=float, default=0)
ap.add_argument('--elev', type=float, default=32); ap.add_argument('--azim', type=float, default=-128)
ap.add_argument('--mono', action='store_true')
ap.add_argument('--zoom', type=float, nargs=6, default=None, help='x0 x1 y0 y1 z0 z1 crop')
ap.add_argument('--size', type=float, nargs=2, default=[12, 8])
ap.add_argument('--offsetB', type=float, default=0, help='shift *_B parts in +x (for STLs not in assembled coords)')
a = ap.parse_args()

fs = []
for p in a.files:
    fs += sorted(glob.glob(os.path.join(p, 'body_*.stl'))) if os.path.isdir(p) else [p]

fig = plt.figure(figsize=a.size, dpi=220)
ax = fig.add_subplot(111, projection='3d')
light = np.array([0.4, -0.6, 0.9]); light /= np.linalg.norm(light)
allp = []
for f in fs:
    key = os.path.basename(f)[5:-4] if os.path.basename(f).startswith('body_') else 'x'
    t = load(f)
    if a.offsetB and key.endswith('_B'): t = t + np.array([a.offsetB, 0, 0])
    if a.explode:
        c = t.reshape(-1, 3).mean(0); c[2] = 0
        cx = np.array([104.0, 151.5, 0])
        t = t + (c - cx) * a.explode / 100.0
    if a.zoom:
        x0, x1, y0, y1, z0, z1 = a.zoom
        cen = t.mean(1)
        keep = (cen[:, 0] > x0) & (cen[:, 0] < x1) & (cen[:, 1] > y0) & (cen[:, 1] < y1) & (cen[:, 2] > z0) & (cen[:, 2] < z1)
        t = t[keep]
        if not len(t): continue
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    n /= (np.linalg.norm(n, axis=1, keepdims=True) + 1e-12)
    shade = 0.45 + 0.55 * np.abs(n @ light)
    base = np.array(matplotlib.colors.to_rgb('#9aa5b1' if a.mono else COL.get(key, '#9aa5b1')))
    cols = np.clip(base[None, :] * shade[:, None], 0, 1)
    pc = Poly3DCollection(t, facecolors=cols, edgecolors=cols, linewidths=0.3)
    ax.add_collection3d(pc)
    allp.append(t.reshape(-1, 3))
P = np.vstack(allp); mn, mx = P.min(0), P.max(0)
ax.set_xlim(mn[0], mx[0]); ax.set_ylim(mn[1], mx[1]); ax.set_zlim(mn[2], mx[2])
ax.set_box_aspect(tuple(mx - mn), zoom=1.0)
ax.view_init(elev=a.elev, azim=a.azim)
ax.set_axis_off()
plt.subplots_adjust(0, 0, 1, 1)
fig.savefig(a.out, facecolor='white')
from PIL import Image, ImageChops
im = Image.open(a.out).convert('RGB'); b = ImageChops.difference(im, Image.new('RGB', im.size, 'white')).getbbox()
im.crop((max(b[0]-40,0), max(b[1]-40,0), min(b[2]+40,im.width), min(b[3]+40,im.height))).save(a.out)
print('wrote', a.out)
