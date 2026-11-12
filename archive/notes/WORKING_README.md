# Graduated 3-Chamber Cutlery Box — Option 3 (shared dividers)

A disposable-cutlery organizer: one connected box with **three graduated open
chambers** — knife, fork, spoon — separated by **shared single dividers** for
maximum interior space. Each chamber is a single open bay sized so the cutlery
naturally settles into ~3 columns (no sub-dividers). Tiles into pieces that each
fit a **120 × 120 × 120 mm** printer.

## The design

| Chamber | Bay width | Fits (measured cutlery) | Piece width |
|---------|-----------|--------------------------|-------------|
| Knife   | 69 mm     | 3 × 19 mm + ~12 play     | 86 mm       |
| Fork    | 99 mm     | 3 × 29 mm + ~12 play     | 110 mm      |
| Spoon   | 111 mm    | 3 × 34 mm + ~9 play      | 117 mm      |

Bay widths come from real measured cutlery; spoon play is trimmed so its printed
piece stays under the 120 mm bed (117 mm). Assembled interior length is
**196 mm** (fits a 188 mm knife); total width **303 mm**. Because that exceeds
the bed in both directions, the box splits into a grid:

- **3 chambers across the width** (knife / fork / spoon)
- **2 halves along the length** (A = near end, B = far end)

→ **6 body pieces** to print. The box also models the features that receive a
**lid** — a flat ~2 mm clear PETG/Tritan sheet ordered to size (the sheet itself
is not printed); the box has the hinge groove, support ledge, retention clips and
lift notch built in.

## Flush, hidden joinery

Every joint is a **vertical sliding dovetail embedded entirely inside a wall** —
nothing protrudes from an exterior face and nothing intrudes into a bay. All
dovetail-hosting walls are **6 mm thick** so the joint sits centred inside the
wall; the floor stays thin.

- **A/B halves** join across the mid seam via dovetails embedded in the four
  **lengthwise walls** (the two outer walls + the two shared dividers).
- **Chambers** join to each other the same way, but across the chamber
  boundary, with the dovetail embedded inside the thick **end walls** — running
  *within the outer wall*, just like the A/B joint runs within the lengthwise
  walls. One per shared seam per half, so each pair of chambers is tied at both
  the front and back end walls. The female socket is sunk inside the end wall;
  only a small tab shows on the neighbour's edge, so the exterior stays flush
  and the bays stay clear.

## Assembly

Every joint is a vertical sliding dovetail, so you assemble by dropping pieces
straight down:

1. Build the **A row**: set down `knife_A`, lower `fork_A` onto it (the lateral
   dovetails engage), then `spoon_A`.
2. Build the **B row** the same way.
3. Lower the whole **B row** straight down onto the **A row** — the three A/B
   dovetails engage together.

The result is one rigid unit: the knife seam is locked on both sides, and the
fork and spoon seams are now braced by their neighbours through the lateral
dovetails (no more single-sided wobble). The ordered clear sheet drops into the
hinge groove and is held by the retention clips.

A **comfort chamfer** (`CHAMFER = 1.0 mm`) is broken along the top rim of every
wall — the inner and outer top edges you handle when loading and grabbing
cutlery — and a smaller `JOINT_CHAMF = 0.5 mm` break is added to the dovetail
tops so the rim stays clean across the joints. The inside-bottom corners stay
square to keep maximum capacity.

## Files & layout

- `cutlery_box.scad` — **the live, parametric model** (OpenSCAD, cut-from-solid).
  The single source of truth for the geometry; set the `part` parameter (or use
  the Customizer dropdown) and export each of the six pieces.
- `cutlery_box_stls/` — the latest STLs exported from the live `cutlery_box.scad` (what you
  print). **Currently empty:** the live model has a design change (45° ramped laps)
  that hasn't been re-exported yet — regenerate from OpenSCAD to populate it.
- `previous-versions/` — every `cutlery_box_vN*.scad` snapshot and the `.bak`
  autosaves. `previous-versions/v24_stable/` bundles the last stable scad
  (`cutlery_box_v24_stable.scad`) with its verified 6-piece STL set.
- `make_dovetail_rig.py` — generates `dovetail_fit_test_rig.stl`, a small coupon
  for dialing in dovetail clearance before printing the real parts.
- `assembly.stl` — older assembled-view reference (pre-v24).
- `docs/` — write-ups: `CONSTRUCTION_STORY.md` (full design history),
  `TRIAL_PRINT_FIX_PLAN.md`, `v24_stable_NOTES.md`, `dremel-guide.md`
  (finishing), plus `docs/diagrams/` (renders) and `docs/feedback/` (screenshots).
- `archive/build_box.py` — the original self-contained Python generator (stdlib
  only). **Superseded by the OpenSCAD model** but kept as the reference for every
  parameter; `archive/render_dovetail_top.py` (old preview renderer) and
  `archive/verify_dovetail_optionA.py` (spent diagnostic) live here too.

## Printing

Print the pieces **floor-down, as modeled** (open top facing up, walls rising
vertically). In this orientation every surface is either flat on the bed or
vertical, the chamfer narrows toward the top, and the dovetails run straight up —
so **no supports and no raft are needed** for any of the six pieces.

With **rainbow / gradient filament** this gives horizontal colour bands sweeping
up the box walls (the gradient builds over the 58 mm height). Print the pieces
in one continuous run for a coherent colour progression.

- **Test one joint first.** Dovetail clearance is `DT_CLR = 0.3 mm` (Option A),
  chosen blind to your printer. Print `knife_A` + `knife_B` and check the slide
  fit before committing all the filament. Too tight → raise `DT_CLR`; too loose →
  lower it.
- **Tune anything** at the top of `cutlery_box.scad` — bay widths, height
  (`COMP_H`), wall thickness (`HOST_T`), chamfers, half length (`HALF_LEN`),
  dovetail params — then re-export the STLs.

## Generating the STLs

Open `cutlery_box.scad` in OpenSCAD, pick the piece with the `part` dropdown
(Customizer), then F6 and **File → Export → STL** into `cutlery_box_stls/`. To export all
six from the command line:

```bash
for p in knife_A knife_B fork_A fork_B spoon_A spoon_B; do openscad -o "cutlery_box_stls/body_$p.stl" -D "part=\"$p\"" cutlery_box.scad; done
```

Pieces are modelled in assembled coordinates (floor-down, z = 0 on the bed), so
importing all six together shows the assembled box; your slicer drops each onto
the plate for printing.
