# cutlery_box v24 — STABLE

Snapshot: `cutlery_box_v24_stable.scad` (exact copy of `cutlery_box.scad` at this point).
Verified STL set: `openscad/stl_v24_stable/` (also copied to the top-level `body_*.stl`).
Date: 2026-06-23.

## What changed vs v23_stable (trial-print fixes)

1. **Dovetail Option A** — `DT_FLARE 2.1→1.7`, `DT_CLR 0.4→0.3` (neck unchanged).
   Female socket tip 5.0→4.0 mm in the 6 mm wall → **ears 0.5→1.0 mm** (both the
   inner ear and the outer skin). Fixes the floppy "two thin walls", the wiggle/
   pull-out, and the joint showing from outside. Undercut hook 0.9→0.5 mm (fine for
   a vertical sliding dovetail). Male and female track the same params, so they stay
   matched. Option B (1.2 mm ears) documented in-file for a future trial.

2. **Corner keys at the lap crossings** — new `corner_key` module + `CORNER_CLIP`.
   The dangling thin tab at each A/B-seam × divider crossing is replaced by a SOLID
   full-height base corner on the divider-owning piece, with the neighbour's chamber
   shelf clipped back by `LAP_CLR`:
   - knife/fork → solid on `knife_A`, clip `fork_A`
   - fork/spoon → solid on `fork_A`, clip `spoon_A`

Not changed (by decision): the long-edge half-lap stays flat (file the support
residue by hand — a 45° ramp was rejected as a warp risk). Issue 1 (elephant's
foot) is slicer-side only.

## Verification (this snapshot)

- All six pieces fit the 120 mm bed: max footprint spoon = 110 × 119 mm; height 58 mm.
- Watertight: 5/6 clean. `spoon_B` has one 0.01 mm sliver edge in the lid-ledge zone
  (z≈54) — sub-resolution, slicer auto-heals, unrelated to these edits.
- (OpenSCAD render done by the user; F6 looked good.)

## Print plan

1. Slicer (X-PRINT Expert): elephant-foot/initial-layer horizontal expansion
   −0.15…−0.20 mm, first-layer flow ~95%, bed −5 °C after layer 1, good re-level.
2. **Test the `knife_A` + `knife_B` pair first** — confirm the dovetail slides snug
   and holds, the joint is invisible outside, and the corner/lap clean up with a file.
3. If good, print the remaining four. If the dovetail still feels thin, swap to
   Option B (one-line change) and re-test.
