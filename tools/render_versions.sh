#!/bin/bash
# Render every archived model version (v1-v25) with OpenSCAD, at the spots that
# changed between versions: whole box, rim seam over a divider, hinge wall (seen
# at the cut edge of knife_A), and the finger notch with its clips.
#
# Needs OpenSCAD installed (macOS app or `openscad` on PATH). Run from the repo root:
#   bash tools/render_versions.sh            # writes to renders/ (git-ignored)
# Takes a few minutes. Camera format: eye_x,eye_y,eye_z,center_x,center_y,center_z.
set -u
cd "$(dirname "$0")/.."
OS=$(command -v openscad || ls -d /Applications/OpenSCAD*.app/Contents/MacOS/OpenSCAD 2>/dev/null | head -1)
[ -n "$OS" ] && [ -x "$OS" ] || { echo "OpenSCAD not found. Install it or edit OS= in this script."; exit 1; }
OUT=${1:-renders}; mkdir -p "$OUT"
render() { # file version view part camera size
  "$OS" -q -o "$OUT/$2_$3.png" -D "part=\"$4\"" --camera="$5" --imgsize="$6" --colorscheme=Tomorrow "$1" 2>/dev/null \
    && echo "   $3 ok" || echo "   $3 FAILED"
}
for f in archive/versions/*.scad archive/versions/*/*.scad; do
  v=$(basename "$f" .scad); echo "== $v"
  render "$f" "$v" box   assembly -201.5,-284.6,398,104,151.5,25 1600,1100
  render "$f" "$v" seam  assembly 134.8,139.1,99,104,183,54      1000,750
  render "$f" "$v" hinge knife_A  14.1,118.8,58.3,4,81,50         1000,750
  render "$f" "$v" notch assembly 131.7,124.9,97,205,151.5,52     1000,750
done
echo "Done: $(ls "$OUT" | wc -l) images in $OUT/"
