#!/usr/bin/env python3
"""Verify the Option-A dovetail change by reproducing the .scad polygon math
and drawing the top-down cross-section (old vs new). No OpenSCAD needed."""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Rectangle

HOST_T = 6.0
DEPTH  = 5.0

def profile(neck, flare, clr):
    # female socket trapezoid (matches dt_prism_*: neck at seam x=0, flare at tip x=DEPTH)
    sock = [(0, -(neck+clr)), (DEPTH, -(flare+clr)), (DEPTH, (flare+clr)), (0, (neck+clr))]
    male = [(0, -neck), (DEPTH, -flare), (DEPTH, flare), (0, neck)]
    ear_tip = HOST_T/2 - (flare + clr)   # thinnest ear (at the tip)
    hook    = flare - neck
    return sock, male, ear_tip, hook

cases = [("BEFORE  (flare 2.1, clr 0.4)", 1.2, 2.1, 0.4),
         ("AFTER — Option A  (flare 1.7, clr 0.3)", 1.2, 1.7, 0.3)]

fig, axes = plt.subplots(1, 2, figsize=(11, 5.2), sharey=True)
for ax, (title, neck, flare, clr) in zip(axes, cases):
    sock, male, ear, hook = profile(neck, flare, clr)
    # host wall (full 6 mm across y), shown over the dovetail depth
    ax.add_patch(Rectangle((0, -HOST_T/2), DEPTH+0.6, HOST_T, facecolor="#c9c9c9",
                           edgecolor="k", lw=1.5, zorder=1))
    # socket void cut from the wall
    ax.add_patch(Polygon(sock, closed=True, facecolor="white", edgecolor="k",
                         lw=1.2, ls=(0,(4,3)), zorder=2))
    # male tail seated in it (with clearance gap)
    ax.add_patch(Polygon(male, closed=True, facecolor="#9ec6f0", edgecolor="#1f6fc4",
                         lw=1.4, alpha=0.9, zorder=3))
    # ear dimension at the tip (both sides)
    yb = flare+clr
    for s in (+1, -1):
        ax.annotate("", xy=(DEPTH, s*HOST_T/2), xytext=(DEPTH, s*yb),
                    arrowprops=dict(arrowstyle="<->", color="crimson", lw=1.6))
    ax.text(DEPTH-0.15, (HOST_T/2+yb)/2, f"ear\n{ear:.1f} mm", color="crimson",
            ha="right", va="center", fontsize=11, fontweight="bold")
    ax.text(DEPTH/2, 0, "male\ntail", ha="center", va="center", fontsize=9, color="#0d3f73")
    ax.text(0.1, HOST_T/2+0.15, "seam face", fontsize=8, color="dimgray")
    ax.text(0.1, -HOST_T/2-0.45, "outer / bay face", fontsize=8, color="dimgray")
    ax.set_title(f"{title}\nhook {hook:.1f} mm", fontsize=10)
    ax.set_xlim(-0.5, DEPTH+1.2); ax.set_ylim(-4.2, 4.2)
    ax.set_aspect("equal"); ax.set_xlabel("depth into wall (mm)")
    ax.grid(alpha=0.25)
axes[0].set_ylabel("across wall thickness — 6 mm total (mm)")
fig.suptitle("Female dovetail in a 6 mm wall — ear doubles 0.5 → 1.0 mm (wall unchanged)",
             fontsize=12, fontweight="bold")
fig.tight_layout(rect=(0,0,1,0.95))
out = "dovetail_optionA_verify.png"
fig.savefig(out, dpi=130)

# numeric assertions
for title, neck, flare, clr in cases:
    _,_,ear,hook = profile(neck,flare,clr)
    print(f"{title:42s} ear={ear:.2f}mm  hook={hook:.2f}mm  socket_tip={2*(flare+clr):.2f}mm  male_neck_full={2*neck:.2f}mm")
print("Saved", out)
