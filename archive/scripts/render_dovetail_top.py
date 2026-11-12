#!/usr/bin/env python3
"""
Render / screenshot the TOP of the A/B sliding-dovetail joint on the knife
pieces, zoomed in on the connection point, so the top-of-joint transition can be
reviewed visually as the design is iterated.

WHY THIS EXISTS
---------------
Everything about the box is good except the seamless transition at the very top
of the dovetail joint where two pieces meet. This script makes that exact region
easy to look at: it imports `build_box` (so it ALWAYS reflects the current
parameters / geometry — no stale STLs), rebuilds the real knife A and knife B
meshes, drops them into their true assembled positions (B shifted +HALF_LEN in
X, exactly like build_box.assemble), and renders tight, zoomed views of the top
of the A/B dovetail seam.

Rendering uses matplotlib's mplot3d (the same look as the existing
preview_*/check*.png renders) — no external CAD libs, std scientific stack only.

OUTPUT (written next to this script)
------------------------------------
  dovetail_top_knife_AB.png            summary grid: both A/B dovetail hosts,
                                       each shown angled + top-down
  dovetail_top_knife_AB_lefthost.png   big close-up of the outer-wall A/B joint
  dovetail_top_knife_AB_righthost.png  big close-up of the divider-wall A/B joint
  dovetail_top_knife_A.png             knife_A alone, top edge at the seam
  dovetail_top_knife_B.png             knife_B alone, top edge at the seam

A and B are drawn in two colours (A=indigo, B=copper) so the seam line and the
top-of-joint transition read clearly.

RE-RUN after any design change:
    python3 render_dovetail_top.py
"""
import os
import importlib.util
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

HERE = os.path.dirname(os.path.abspath(__file__))

# ----------------------------------------------------------------- load build_box
def load_build_box():
    spec = importlib.util.spec_from_file_location(
        "build_box", os.path.join(HERE, "build_box.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

BB = load_build_box()

# ----------------------------------------------------------------- geometry setup
def knife_layout():
    """Return the LAYOUT entry for the knife chamber."""
    for L in BB.LAYOUT:
        if L["name"] == "knife":
            return L
    raise RuntimeError("no knife chamber in layout")

def knife_parts():
    """Build the real knife A and knife B meshes (current parameters)."""
    L = knife_layout()
    a = BB.build_body(L["ci"], "A")
    b = BB.build_body(L["ci"], "B")
    return a, b

def tris_array(mesh, dx=0.0):
    """Mesh.tris -> (N,3,3) float array, optionally shifted +dx in X (assembly)."""
    arr = np.array(mesh.tris, dtype=float)        # (N,3,3): tri, vert, xyz
    if dx:
        arr = arr.copy()
        arr[:, :, 0] += dx
    return arr

# ----------------------------------------------------------------- rendering core
LIGHT = np.array([0.4, -0.6, 0.8])
LIGHT = LIGHT / np.linalg.norm(LIGHT)

def shade(tris, base_rgb):
    """Flat per-face shading from a single light, returns (N,4) face colours."""
    v0, v1, v2 = tris[:, 0], tris[:, 1], tris[:, 2]
    n = np.cross(v1 - v0, v2 - v0)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    ln[ln == 0] = 1.0
    n = n / ln
    inten = np.abs(n @ LIGHT)                      # abs: light both faces
    inten = 0.35 + 0.65 * inten                    # ambient + diffuse
    base = np.array(base_rgb)
    cols = np.clip(inten[:, None] * base[None, :], 0, 1)
    return np.concatenate([cols, np.ones((len(cols), 1))], axis=1)

def clip_whole(tris, xlim=None, ylim=None, zlim=None, pad=0.5):
    """Keep ONLY triangles all of whose vertices fall inside the given bounds.
    Whole-triangle clipping (vs centroid) avoids ragged half-cut triangles at
    the edge of the view, which were making earlier close-ups look broken."""
    keep = np.ones(len(tris), dtype=bool)
    for ax_i, lim in ((0, xlim), (1, ylim), (2, zlim)):
        if lim is None:
            continue
        lo, hi = lim
        v = tris[:, :, ax_i]
        keep &= (v >= lo - pad).all(axis=1) & (v <= hi + pad).all(axis=1)
    return tris[keep]

COL_A = (0.20, 0.28, 0.62)     # knife A — indigo
COL_B = (0.70, 0.42, 0.20)     # knife B — copper (so the seam reads clearly)

def draw_into(ax, pieces, xlim, ylim, zlim, elev, azim, title,
              clip=("y", "z")):
    """Draw `pieces` into a 3D axes with true geometric box aspect (undistorted).
    `clip` says which axes to whole-triangle clip on — default Y (isolate one
    host) and Z (keep the top band). X is left unclipped so the full key/hat and
    socket/pocket stay intact in the frame."""
    cx = xlim if "x" in clip else None
    cy = ylim if "y" in clip else None
    cz = zlim if "z" in clip else None
    for tris, rgb in pieces:
        t = clip_whole(tris, cx, cy, cz)
        if len(t) == 0:
            continue
        fc = shade(t, rgb)
        coll = Poly3DCollection(
            t, facecolors=fc, edgecolors=(0, 0, 0, 0.30), linewidths=0.2)
        ax.add_collection3d(coll)
    ax.set_xlim(*xlim); ax.set_ylim(*ylim); ax.set_zlim(*zlim)
    ax.set_box_aspect((xlim[1]-xlim[0], ylim[1]-ylim[0], zlim[1]-zlim[0]))
    ax.view_init(elev=elev, azim=azim)
    ax.set_xlabel("X (len)", fontsize=8, labelpad=-2)
    ax.set_ylabel("Y (wid)", fontsize=8, labelpad=-2)
    ax.set_zlabel("Z (ht)", fontsize=8, labelpad=-2)
    ax.tick_params(labelsize=6)
    ax.set_title(title, fontsize=9.5)

def render(pieces, xlim, ylim, zlim, elev, azim, title, fname, clip=("y", "z")):
    """Single-panel figure."""
    fig = plt.figure(figsize=(8, 6.5), dpi=130)
    ax = fig.add_subplot(111, projection="3d")
    draw_into(ax, pieces, xlim, ylim, zlim, elev, azim, title, clip)
    out = os.path.join(HERE, fname)
    fig.tight_layout(); fig.savefig(out, bbox_inches="tight"); plt.close(fig)
    print(f"wrote {fname}")
    return out

def render_grid(panels, fname, suptitle, ncols, figsize):
    """panels: list of dicts (pieces,xlim,ylim,zlim,elev,azim,title[,clip])."""
    nrows = (len(panels) + ncols - 1) // ncols
    fig = plt.figure(figsize=figsize, dpi=130)
    for i, p in enumerate(panels):
        ax = fig.add_subplot(nrows, ncols, i + 1, projection="3d")
        draw_into(ax, p["pieces"], p["xlim"], p["ylim"], p["zlim"],
                  p["elev"], p["azim"], p["title"], p.get("clip", ("y", "z")))
    fig.suptitle(suptitle, fontsize=13)
    out = os.path.join(HERE, fname)
    fig.tight_layout(); fig.savefig(out, bbox_inches="tight"); plt.close(fig)
    print(f"wrote {fname}")
    return out

# ----------------------------------------------------------------- views
EXPLODE = 16.0     # how far to pull B back (+X) for the exploded mating views

def main():
    L = knife_layout()
    seam = BB.HALF_LEN                 # A/B mating face (X)
    top = BB.BODY_H                    # rim height (Z)
    depth = BB.DT_DEPTH
    hosts = L["hosts"]
    yL = min(hosts)                    # outer-wall host
    yR = max(hosts)                    # divider host

    a_mesh, b_mesh = knife_parts()
    A = tris_array(a_mesh)                            # knife_A (fixed)
    B_mated = tris_array(b_mesh, dx=BB.HALF_LEN)      # assembled
    B_expl  = tris_array(b_mesh, dx=BB.HALF_LEN + EXPLODE)   # pulled apart
    MATED = [(A, COL_A), (B_mated, COL_B)]
    EXPL  = [(A, COL_A), (B_expl,  COL_B)]

    # Tight box around the TOP of the joint. X is clipped too, so the long walls
    # are cut away and we see a clean cross-section of the hat seating in the
    # pocket (the long wall faces are few/large triangles and only add clutter).
    band = 9.0                         # how far down from the rim to show
    zlim = (top - band, top + 2.0)
    win = BB.HOST_T / 2.0 + 2.5        # Y window: full wall width + margin
    xl_mated = (seam - 6, seam + depth + 3)
    xl_expl  = (seam - 6, seam + EXPLODE + depth + 3)
    CLIP = ("x", "y", "z")

    def panel(pieces, yc, xl, elev, azim, title, clip=CLIP):
        return dict(pieces=pieces, xlim=xl, ylim=(yc - win, yc + win),
                    zlim=zlim, elev=elev, azim=azim, title=title, clip=clip)

    # ---- summary grid: per host, EXPLODED (shows hat + pocket) and MATED -----
    panels = []
    for lab, yc in (("OUTER-WALL", yL), ("DIVIDER", yR)):
        panels.append(panel(EXPL,  yc, xl_expl, 20, -62,
                            f"{lab} (y≈{yc:.0f}) — EXPLODED: A key ↔ B socket"))
        panels.append(panel(MATED, yc, xl_mated, 22, -62,
                            f"{lab} (y≈{yc:.0f}) — MATED (assembled)"))
        panels.append(panel(MATED, yc, xl_mated, 86, -90,
                            f"{lab} (y≈{yc:.0f}) — MATED top-down (rim line)"))
    render_grid(panels, "dovetail_top_knife_AB.png",
                "Knife A/B — TOP of seam: comfort chamfer flows over the male key "
                "(A=indigo, B=copper).  X-clipped: top cross-section of the joint",
                ncols=3, figsize=(15, 9))

    # ---- big per-host: exploded beside mated --------------------------------
    for lab, yc, fname in (("OUTER-WALL", yL, "dovetail_top_knife_AB_lefthost.png"),
                           ("DIVIDER",    yR, "dovetail_top_knife_AB_righthost.png")):
        render_grid(
            [panel(EXPL,  yc, xl_expl, 18, -62,
                   f"{lab} dovetail (y≈{yc:.0f}) — EXPLODED"),
             panel(MATED, yc, xl_mated, 20, -62,
                   f"{lab} dovetail (y≈{yc:.0f}) — MATED")],
            fname, f"Knife A/B top — {lab} dovetail   (A=indigo, B=copper)",
            ncols=2, figsize=(13, 6))

    # ---- each piece alone (outer host): male key with chamfer (A), socket (B) -
    render([(A, COL_A)], xl_mated, (yL - win, yL + win), zlim,
           elev=18, azim=-58,
           title="Knife A — male key, comfort chamfer flows over its top",
           fname="dovetail_top_knife_A.png")
    render([(B_mated, COL_B)], xl_mated, (yL - win, yL + win), zlim,
           elev=18, azim=-122,
           title="Knife B — female socket, full rim chamfer intact",
           fname="dovetail_top_knife_B.png")

    print("\nGeometry summary (current parameters):")
    print(f"  seam (A/B) X={seam:.1f}  rim Z={top:.1f}  hosts Y={yL:.0f},{yR:.0f}")
    print(f"  hat=chamfer-over-male-key  DT_DEPTH={depth}  DT_NECK={BB.DT_NECK}"
          f"  DT_FLARE={BB.DT_FLARE}  DT_CLR={BB.DT_CLR}  CHAMFER={BB.CHAMFER}")

if __name__ == "__main__":
    main()
