#!/usr/bin/env python3
"""Z-buffer STL renderer used for the images in docs/img/renders/.

Orthographic view, flat shading, depth-based edge lines, one neutral colour by
default (the parts' print colours were never part of the design). --colors
gives each file its own colour, or a bottom-to-top gradient written
BOTTOM:TOP, to mimic the colour-change filament (used for the social preview).
Needs numpy and Pillow.

  python3 tools/render_stl.py out.png stl/                                 # whole box
  python3 tools/render_stl.py out.png stl/ --explode 30                    # pieces pulled apart
  python3 tools/render_stl.py out.png stl/ --center 104 3 50 --width 40    # close-up of one spot
  python3 tools/render_stl.py out.png a.stl b.stl --offsetB 104            # parts not in assembled position
  python3 tools/render_stl.py out.png a.stl b.stl --colors '#4f9a62:#3a7fa6' '#c9ccd1'  # per-file colours

--elev / --azim set the view direction in degrees (azimuth measured from +x).
"""
import argparse, glob, os, struct
import numpy as np
from PIL import Image, ImageFilter


def load(f):
    d = open(f, 'rb').read()
    if d[:5] == b'solid' and b'facet' in d[:300]:
        v = [list(map(float, l.split()[1:])) for l in d.decode().splitlines() if l.strip().startswith('vertex')]
        return np.array(v).reshape(-1, 3, 3)
    n = struct.unpack('<I', d[80:84])[0]
    a = np.frombuffer(d[84:84 + n * 50], dtype=np.dtype([('n', '<3f4'), ('v', '<9f4'), ('a', '<u2')]))
    return a['v'].reshape(-1, 3, 3).astype(float)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('files', nargs='+')
    ap.add_argument('--elev', type=float, default=35)
    ap.add_argument('--azim', type=float, default=-125)
    ap.add_argument('--center', type=float, nargs=3)
    ap.add_argument('--width', type=float, help='visible width in mm (close-up)')
    ap.add_argument('--px', type=int, default=1400, help='output width in pixels')
    ap.add_argument('--aspect', type=float, default=0.75, help='height / width for close-ups')
    ap.add_argument('--explode', type=float, default=0, help='percent to push pieces apart')
    ap.add_argument('--offsetB', type=float, default=0, help='shift *_B parts in +x')
    ap.add_argument('--color', default='#c9ccd1')
    ap.add_argument('--colors', nargs='+', help='one colour per file (after directory expansion), or BOTTOM:TOP')
    ap.add_argument('--bg', default='#ffffff')
    a = ap.parse_args()

    fs = []
    for p in a.files:
        fs += sorted(glob.glob(os.path.join(p, 'body_*.stl'))) if os.path.isdir(p) else [p]
    if a.colors and len(a.colors) != len(fs):
        ap.error('--colors needs %d entries, one per file: %s' % (len(fs), ' '.join(os.path.basename(f) for f in fs)))
    tris = []
    for f in fs:
        t = load(f)
        if a.offsetB and os.path.basename(f).endswith('_B.stl'):
            t = t + [a.offsetB, 0, 0]
        tris.append(t)
    if a.explode:
        allc = np.vstack([t.reshape(-1, 3) for t in tris])
        mid = (allc.min(0) + allc.max(0)) / 2; mid[2] = 0
        out = []
        for t in tris:
            c = t.reshape(-1, 3).mean(0); c[2] = 0
            out.append(t + (c - mid) * a.explode / 100)
        tris = out
    T = np.vstack(tris)
    fid = np.concatenate([np.full(len(t), k) for k, t in enumerate(tris)])

    # camera basis
    el, az = np.radians(a.elev), np.radians(a.azim)
    view = -np.array([np.cos(el) * np.cos(az), np.cos(el) * np.sin(az), np.sin(el)])  # direction camera looks
    right = np.cross(view, [0, 0, 1]); right /= np.linalg.norm(right)
    up = np.cross(right, view)
    P = T.reshape(-1, 3)
    if a.center is not None:
        c = np.array(a.center); w = a.width; h = w * a.aspect
    else:
        u = P @ right; v = P @ up
        c = None
        umin, umax, vmin, vmax = u.min(), u.max(), v.min(), v.max()
        pad = 0.04 * (umax - umin)
        w = umax - umin + 2 * pad; h = vmax - vmin + 2 * pad
        cu, cv = (umin + umax) / 2, (vmin + vmax) / 2
    SS = 2
    W = a.px * SS; H = int(round(W * h / w))
    if c is not None:
        cu, cv = c @ right, c @ up
    sx = W / w
    U = (T @ right - cu) * sx + W / 2
    V = -(T @ up - cv) * sx + H / 2
    D = T @ view  # larger = farther
    n = np.cross(T[:, 1] - T[:, 0], T[:, 2] - T[:, 0])
    n /= np.linalg.norm(n, axis=1, keepdims=True) + 1e-12
    facing = n @ view
    n[facing > 0] *= -1  # make all normals face the camera (meshes may have mixed winding)
    L1 = np.array([0.35, -0.55, 0.75]); L1 /= np.linalg.norm(L1)
    L2 = -view
    shade = 0.30 + 0.45 * np.clip(n @ L1, 0, 1) + 0.30 * np.clip(n @ L2, 0, 1)

    zbuf = np.full((H, W), np.inf); ibuf = np.full((H, W), -1, int)
    for i in range(len(T)):
        x, y, z = U[i], V[i], D[i]
        x0, x1 = int(max(np.floor(x.min()), 0)), int(min(np.ceil(x.max()), W - 1))
        y0, y1 = int(max(np.floor(y.min()), 0)), int(min(np.ceil(y.max()), H - 1))
        if x0 > x1 or y0 > y1:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        den = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
        if abs(den) < 1e-9:
            continue
        w0 = ((y[1] - y[2]) * (xs - x[2]) + (x[2] - x[1]) * (ys - y[2])) / den
        w1 = ((y[2] - y[0]) * (xs - x[2]) + (x[0] - x[2]) * (ys - y[2])) / den
        w2 = 1 - w0 - w1
        m = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        if not m.any():
            continue
        zz = w0 * z[0] + w1 * z[1] + w2 * z[2]
        sub = zbuf[y0:y1 + 1, x0:x1 + 1]
        upd = m & (zz < sub - 1e-7)
        sub[upd] = zz[upd]
        ibuf[y0:y1 + 1, x0:x1 + 1][upd] = i

    rgb = lambda h: np.array([int(h[k:k + 2], 16) for k in (1, 3, 5)]) / 255
    bg = rgb(a.bg)
    img = np.tile(bg, (H, W, 1))
    hit = ibuf >= 0
    if a.colors:
        # world z of each visible pixel, for bottom-to-top gradients
        ys, xs = np.nonzero(hit)
        uu = (xs + 0.5 - W / 2) / sx + cu; vv = -(ys + 0.5 - H / 2) / sx + cv
        zw = right[2] * uu + up[2] * vv + view[2] * zbuf[ys, xs]
        zmin, zmax = T[..., 2].min(), T[..., 2].max()
        tz = np.clip((zw - zmin) / (zmax - zmin + 1e-9), 0, 1)[:, None]
        lo = np.array([rgb(c.split(':')[0]) for c in a.colors]); hi = np.array([rgb(c.split(':')[-1]) for c in a.colors])
        f = fid[ibuf[ys, xs]]
        col = lo[f] * (1 - tz) + hi[f] * tz
        img[ys, xs] = np.clip(col * shade[ibuf[ys, xs]][:, None] * 1.15, 0, 1)
    else:
        img[hit] = np.clip(rgb(a.color)[None, :] * shade[ibuf[hit]][:, None] * 1.15, 0, 1)
    # edge lines: depth jumps and crease between differently-oriented faces
    nmap = np.zeros((H, W, 3)); nmap[hit] = n[ibuf[hit]]
    zf = np.where(hit, zbuf, zbuf[hit].max() + 50 if hit.any() else 0)
    edge = np.zeros((H, W), bool)
    tol = 0.6 * (w / 400 if a.center is not None else 1.0)
    for dy, dx in ((0, 1), (1, 0)):
        zb = np.roll(zf, (-dy, -dx), (0, 1)); nb = np.roll(nmap, (-dy, -dx), (0, 1))
        hb = np.roll(hit, (-dy, -dx), (0, 1))
        e = (hit != hb) | (np.abs(zf - zb) > tol) | (((nmap * nb).sum(2) < 0.95) & hit & hb)
        edge |= e
    edge[-1, :] = edge[:, -1] = False
    img[edge] = img[edge] * 0.35
    im = Image.fromarray((img * 255).astype(np.uint8)).resize((a.px, int(round(a.px * H / W))), Image.LANCZOS)
    im.save(a.out, optimize=True)
    print('wrote', a.out, im.size, len(T), 'triangles')


if __name__ == '__main__':
    main()
