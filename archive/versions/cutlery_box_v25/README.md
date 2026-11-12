# cutlery_box v25

Snapshot of `cutlery_box.scad` + the 6 exported body STLs at the v25 point.
Date: 2026-06-24.

## What changed vs v24

1. **Dovetail joint tightened — "key #2"** (after full-height slide testing).
   The male tail was too loose at 0.3 mm/side (it popped when pulled), so the per-side
   slide clearance was tightened **0.3 → 0.15** by growing the male tail
   (`DT_NECK` 1.2 → 1.35, `DT_FLARE` 1.7 → 1.85). The **female socket is unchanged**
   (still 1.5 / 2.0 half-width), so already-printed female parts still fit. `CAP_FOOT`
   was pinned to 1.2 so the hidden-cap recess on the female side is also untouched.

2. **45° triangular ramped base laps** (the "triangular base").
   The flat half-laps at the **A/B mid-seam** and the **fork/spoon seam** were replaced
   with triangular 45° wedge/pocket laps (`ab_wedge`/`ab_pocket`, `fs_wedge`/`fs_pocket`).
   Each wedge sits flat on the bed and ramps at 45°, so the laps print with **no support**
   — fixing the blind-pocket support-packing seen on `fork_B` in v24.

(Plus minor in-file comment/cleanup edits.)

## Notes

- STLs here were re-exported from this scad by the user (OpenSCAD F6).
- Female dovetail side is considered FINAL from v24; only the male side changed in v25,
  so v24 female prints remain compatible.
