# Cutlery Box — Construction Story

A running log of how this 3D-printed, graduated, 3-chamber cutlery box came to
be: the design decisions, the dead ends, the real-world test results, and the
lessons learned along the way. Kept so it can be shared later.

---

## Origin: three hung sessions

The whole thing started, oddly, as a debugging request. Three earlier design
sessions had "hung." The diagnosis: each had popped a multiple-choice question
and was waiting on the answer, but the answer never got routed back — so the
sessions sat on a dangling question, and any text typed into them bounced back
as "No response requested." They were effectively dead. Rather than revive them,
we rebuilt the design fresh in a working session — this one.

---

## The vision and the hard constraint

**Goal:** a box for disposable cutlery with **three graduated chambers** —
knife, fork, spoon — each holding roughly **3 side-by-side columns** of its type,
so 9 columns of cutlery total. Chambers widen from knife → fork → spoon.

**The constraint that shaped everything:** the printer is a **120 × 120 × 120 mm**
cube (an AOSEED), but disposable cutlery is ~190 mm long and the full box is
~300 mm wide. So the box can't be printed in one piece in *either* direction.

### Milestones

- **Graduated open chambers.** Cutlery naturally settles into columns, so we
  dropped internal sub-dividers — each chamber is a single open bay sized for ~3
  columns. Simpler, more capacity.
- **Shared single walls.** Between chambers we used one shared wall (not two) to
  maximize interior space.
- **Tiling for the bed.** The box splits into a **3 × 2 grid**: 3 chambers
  across the width × 2 halves along the length = **6 printed body pieces**, each
  fitting the 120 mm bed.
- **Choosing the structure (Option 3).** Three options were rendered and
  compared: (1) separate trays, (2) separate trays that lock together, (3) one
  connected box with shared single dividers. **Option 3 won** — maximum interior
  space, one rigid unit.

---

## The joinery: flush, hidden dovetails

Everything assembles by **lowering pieces straight down** — every joint is a
vertical sliding dovetail, embedded *inside* the walls so nothing protrudes and
the bays stay clear.

- **A/B halves** (the length split) join across the middle seam via dovetails
  embedded in the four thick **lengthwise walls**.
- **Chamber-to-chamber** joins happen the same way but across the chamber
  boundary, with the dovetail embedded inside the thick **end walls** — a nice
  symmetry: the lengthwise joint lives in the lengthwise walls, the cross joint
  lives in the end walls. Both fully flush, only a small mating tab visible on a
  neighbour's edge.

The chamber connectors went through a few placements before landing here:
first mid-bay (intruded into the open bay — rejected), then tucked into the
closed-end corners, then finally embedded *within* the end walls so they read
exactly like the A/B joint. Walls were thickened to 6 mm specifically so a
dovetail fits entirely inside them.

---

## Comfort details

- **Top-rim chamfer (1 mm, 45°)** on the inner and outer top edges — the edges
  your hand meets when loading and grabbing cutlery. Inside-bottom corners left
  square to keep capacity.
- **Joint-top chamfer (0.5 mm)** on the small dovetail tops so the rim stays
  clean across the joints. (A full 1 mm collapsed the tiny tabs, so the bevel
  auto-shrinks for thin features.)

---

## Printing strategy

- **Rainbow / gradient filament**, and a debate about orientation: printing
  on-side would make the colour sweep *across the chambers*, but needs
  supports/raft for the open troughs. Printing **floor-down** (as modeled) has
  **zero overhangs** — every wall vertical, floor flat on the bed, chamfer
  narrowing upward — so **no supports, no raft**. We chose floor-down; the
  rainbow becomes clean horizontal bands sweeping up the walls.
- A useful reminder surfaced: with gradient filament, dovetail *fit* is a model
  property (`DT_CLR` clearance), not a slicer setting — so the test print
  shouldn't be "fixed" with perimeters or flow.

---

## ⭐ HIGHLIGHT — The empty corners and the boolean-union lesson

The first real test print (the bottom 14 mm of a knife piece) exposed the single
most important engineering lesson of the project.

**Symptom:** the two corners where the long walls meet the end wall came out
**hollow/empty**, even though they looked solid in Tinkercad. In the AOSEED
slicer the short wall looked "see-through" depending on the viewing angle.

**Root cause:** the generator built the box as many **overlapping separate
solids** and relied on the slicer to merge ("union") them. Sophisticated slicers
do this happily. But where two walls occupied the *same volume* at a corner, the
AOSEED's fill rule behaves like **even-odd**: a region covered twice counts as
*outside* → hollow. The "two chamfered beams intersecting" look at the rim was
the same thing — the un-merged internal faces showing through.

**The proper fix would be a boolean union** (merge all overlapping solids into
one watertight manifold). That normally means a CAD/CSG library
(manifold3d / trimesh / OpenSCAD) — but the build environment here was offline
and none could be installed.

**The fix we used instead:** redesign so the solids **abut** (touch and share a
face) rather than **overlap**. Even-odd fills abutting solids correctly, because
the doubled crossing at a shared face keeps the parity consistent. Concretely:
the lengthwise walls now *start at* the end-wall thickness instead of running
through it. We also forced **correct outward normals** on every solid and gave
the end walls a **4-edge top chamfer** so the outer corners miter cleanly.

**Result:** all six pieces verified **watertight** (every edge shared an even
number of times, zero open edges), corners solid, chamfers mitered — without any
CSG library.

> **Lesson:** "It looks fine in the CAD viewer" ≠ "it slices solid." Overlapping
> solids are a trap on simpler slicers. Either boolean-union into one manifold,
> or design parts to abut, never overlap.

---

## ⭐ HIGHLIGHT — Test results and sizing insights

The same first print produced the other crucial insight: **the chambers were too
narrow.** Only two knives fit side by side; the third wouldn't go in even with
zero play.

**Real measured cutlery (bounding boxes, mm):**

| Item  | Length | Width | Height |
|-------|--------|-------|--------|
| Knife | 188    | 19    | 3      |
| Fork  | 180    | 29    | ~15    |
| Spoon | 165    | 34    | ~10    |

The original columns were **17 mm** — narrower than a 19 mm knife, so 3-across
was impossible. Re-derived from the real numbers (column = cutlery width + play),
anchored on the play that "felt right" for two knives (~12 mm of slack per
chamber):

| Chamber | New bay | Columns        | Printed piece |
|---------|---------|----------------|----------------|
| Knife   | 69 mm   | 3 × 19 + ~12   | 86 mm          |
| Fork    | 99 mm   | 3 × 29 + ~12   | 110 mm         |
| Spoon   | 111 mm  | 3 × 34 + ~9    | 117 mm         |

> **Insight:** the **spoon is the binding constraint** — its printed piece must
> stay under the 120 mm bed, so its per-column play is trimmed to ~3 mm
> (piece = 117 mm). Knife and fork have room to spare.

> **Insight:** measure the *actual* objects before sizing. The graduated-column
> idea was right, but the first numbers were guesses and a 2 mm error per column
> is the difference between "3 fit" and "3 don't."

Length was fine: the 196 mm interior swallows the 188 mm knife with ~8 mm to
spare.

---

## ⭐ HIGHLIGHT — Clean corners need one continuous outline

A second print review caught a subtler version of the corner problem. With the
overlaps fixed, the corners were *solid* — but the comfort chamfer didn't turn
the corner cleanly. Each wall beveled its own top edges independently, so where
the long wall met the end wall the two bevels collided into a little diagonal
notch instead of the top rim staying a continuous **L** with the chamfer
wrapping around it (an inner-L and an outer-L of bevel).

**Why:** you can't get a mitred chamfer by beveling separate wall blocks — at a
corner every edge is *partly* exposed and *partly* abutting a neighbour, so
per-wall chamfering always leaves an artifact.

**The fix:** stop treating the walls as separate blocks. Each piece's walls are
now unioned into a **single continuous outline polygon** (computed from the wall
rectangles), extruded as one solid, and the chamfer is broken by **insetting
that whole outline** — so the bevel follows the wall all the way around and
mitres at every corner automatically. This needed three small home-grown
geometry routines, since no CAD library was available: a rectangle-union
outliner, a polygon inset, and an ear-clipping triangulator (the outline is
non-convex, so a simple fan won't triangulate its top/bottom faces).

Dovetail features (male tabs, female sockets) are deliberately left *out* of the
outline and added as their own solids, so the outline stays a clean rectilinear
shape and the corners come out crisp.

> **Lesson:** a chamfer that has to wrap a corner is a property of the *outline*,
> not of the individual walls. Model the boundary as one path and offset it.

Also clarified in the same review: the "empty space" visible at a dovetail on a
single piece is the **female receiving socket** — it must be open so the mating
tab slides straight down into it, and it closes up when the two pieces are
assembled. Not a defect.

## The port to OpenSCAD — "cut-from-solid"

`build_box.py` (hand-meshed, abutting solids) got us watertight parts, but it
could never keep the 1 mm rim chamfer **continuous across a dovetail joint**:
where a flared socket corner crosses the sloped chamfer you need a true boolean
intersection, and hand-meshing doesn't have one. So the model was ported to
**OpenSCAD** (`openscad/cutlery_box.scad`), which has a real CSG/boolean kernel
(CGAL). The new approach is **cut-from-solid**:

1. Build the **entire box as one solid, with the chamfer already on it**.
2. `difference()` out vertical `/_\` dovetail prisms that run from just above the
   base up through the rim — this both **forms the sliding-dovetail joints** and
   **splits the box into the 6 bed pieces**.

Because the cut is a real boolean through an already-chamfered solid, the sloped
chamfer↔slot edge is produced for free → the rim chamfer stays continuous across
every joint, with none of the old sliver hacks. The chamfer itself is a smooth
45° bevel built from `hull()` frustums of convex rectangles (no stepped
staircase), which also keeps `box()` a clean manifold so the per-part booleans
resolve reliably. Every parameter carried over from `build_box.py`; a `part`
Customizer dropdown selects which of the six to render/export.

## The half-lap base joint (anti-warp)

Neighbouring base plates now overlap as a **horizontal half-lap (shiplap)** at
mid-base height (`LAP_Z = BASE/2 = 1.5 mm`): the shelf-owner keeps its bottom
half extending past the seam; the neighbour has its bottom half removed there and
lands flat on the shelf. Because the lap faces are **horizontal**, they don't
bind the vertical-drop assembly. Shingle direction is **female-first** (matching
the no-notch dovetail order, which lowers the male piece onto the female): the B
half owns the A/B shelf, the upper chamber owns the chamber shelf; assembly order
is spoon → fork → knife, B before A. The spoon seam uses a smaller lap
(`LAP_LEN_FS = 2 mm`) because the spoon piece is already 117 mm of the 120 mm bed.

## ⭐ HIGHLIGHT — The zero-thickness "flap" bug (and why watertight checks missed it)

**Symptom.** In OpenSCAD's preview, the fork and spoon pieces showed **blue
back-face planes** at their chamber-seam corners (knife pieces were clean). When
exported and imported into Tinkercad, those planes got "thickened" into phantom
solid **boxes** that appeared to rise only **partway up the wall** (~30 mm on the
B-halves) — a "chunky mid-height step block."

**Why it hid for so long.** Standard checks all *passed*: zero degenerate
triangles, zero open/boundary edges, and **edge-manifold** (every edge shared by
exactly two faces) — i.e. "watertight." The defect was a **doubled front+back
sheet on the same plane** — a zero-*thickness* flap. It has volume zero, so
top-face histograms and vertical ray-casts found no solid there; it's
edge-manifold, so the watertight test was happy. It only shows up with an
**overlapping opposite-face detector** (coplanar +normal and −normal triangles
whose 2D projections overlap).

**Root cause.** Each chamber divider wall is owned by the **lower** chamber
(knife owns the knife/fork divider; fork owns the fork/spoon divider). The
**upper** piece's splitting `cell()` boundary was laid *exactly* on that
divider's far face (`fork` cell started at `FORK_Y0 = 81`, `spoon` at
`SPOON_Y0 = 186`). `intersection(box(), cell)` along a plane **coincident with an
existing box face** makes CGAL keep a **zero-thickness copy** of that wall face —
open chamber on one side, discarded divider on the other. knife never flapped
because it *owns* its divider, so solid sits behind the cut. On the B-halves the
ghost face was truncated by the chamfer cut, which is where the deceptive
diagonal "~30 mm" edge came from.

**The fix (`SEAM_EPS = 0.02`).** Nudge the four upper-chamber cut planes a hair
**into the open bay** (`FORK_Y0 + SEAM_EPS`, `SPOON_Y0 + SEAM_EPS`). At
y = 81.02 / 186.02 the box has only floor there — no vertical wall face — so no
ghost face can survive. The chamber lap shelf was extended `+2·SEAM_EPS` past the
seam so it still overlaps the nudged body floor (no floating shelf), and the A/B
lap shelf was given a `+EPS` interpenetration into its own body so it fuses
instead of abutting on a coincident plane. Verified clean: **0 flaps on all six
pieces** after re-export; user confirmed the phantom boxes are gone.

> **Lesson:** "watertight + edge-manifold" is **not** the same as "valid solid."
> A coincident-coplanar cut plane can leave a zero-thickness sheet that passes
> both tests but is a real defect downstream. Never split a solid on a plane that
> coincides with one of its own faces — offset the cut by an epsilon into open
> space, and make unions interpenetrate rather than abut.

## Hiding the dovetail on the top edge (the "hat")

With the joints working, the last cosmetic issue was that each dovetail showed its
**trapezoid outline on the top rim** — a little zig-zag seam. Fix: on the **male**
piece, extend the wall's **full-width top** across the key footprint so the key is
capped flush and continuous with the wall top; on the **female** piece, cut a
matching **top recess** (`cap + CAP_CLR`) so the cap drops straight in as the piece
lowers. The cap is added *inside* the `box()` intersection, so it inherits the
continuous chamfer for free. Result: the top reads as one surface with a **single
straight seam line** at the cap tip; the dovetail joinery lives entirely below it.
Applied to all joints that surface on the top edge — the A/B seam keys **and** the
chamber keys.

**Self-supporting underside (printability).** A full-width cap sitting on the
narrower dovetail neck would leave a **flat 90° underside shelf** — an overhang
that needs support material when printing floor-down. So the cap underside is
**ramped**: it rises from the dovetail-neck half-width (`CAP_FOOT`) out to the full
wall half-width at **`CAP_SLANT_DEG` from horizontal** (built as
`hull(narrow bottom slab, full-width top box)`; the narrow slab is buried inside the
tail so its only flat face is internal). Default **60°** (steeper than the 45°
printable limit, chosen for margin — "be safe"), tunable 55–60°. The steeper ramp
needs more vertical room, so **`CAP_H` was raised to 5 mm** (the ramp finishes at
z ≈ 56.1, leaving the 57–58 chamfer at full width with ~0.9 mm margin; an `assert`
fires if the angle is ever too steep for `CAP_H`). The **female recess gets the
same ramp + `CAP_CLR`**, so the slanted cap still seats flush, the wall stays full
width (the female keeps its wall *outside* the ramp), and the female pocket is a
wedge that's wide at the bottom → also self-supporting.

Manifold-safety held to the flap-fix standard: the cap starts `EPS` inside its own
wall (no coincident face), the ramp faces are sloped (can't coincide with any
axis-aligned box face), and the recess flanks sit outside the wall in open air
(nothing to coincide with). Re-verified (voxel/analytic): cap underside **60°
from horizontal with 0 mm exposed flat overhang**, female recess **0 mm** flat
overhang, bed-fit unchanged (caps reuse the key tips → no bounding-box growth), and
vertical-drop clearance holds at all seven joints. The final zero-flap confirmation
runs on the user's F6 re-export.

**Two later refinements (after reviewing a labeled cross-section):**

- *Merge the ramp top into the chamfer base ("remove a staircase step").* The cap
  ramp now reaches full width **exactly at the lower chamfer line** (`CAP_ZRAMP =
  BODY_H − CHAMFER = 57`) instead of ~1 mm below it, so the "ramp-top" and
  "chamfer-base" reference lines coincide and the top loses one horizontal step.
  `CAP_H` is now **derived** from the angle (so this stays true if the slant
  changes); at 60° it works out to **≈2.73 mm**.
- *Kill the feather edge.* Where the female recess used to taper to a zero-thickness
  knife edge at the wall face, the cap now stops **`FEATHER_MIN + CAP_CLR`** short of
  the wall edge (`CAP_HW = HOST_T/2 − FEATHER_MIN − CAP_CLR = 2.2`), so the female
  keeps a solid **`FEATHER_MIN` = 0.5 mm vertical land** (a clean printable rib, faces
  up/inward — no new overhang) instead of a fragile feather. The cap is relieved to
  match, so it still seats with `CAP_CLR`. Re-verified: 0 mm female horizontal
  overhang, 0.5 mm land, all seven drops clear, rim continuous.
- *Tried and REVERTED — full-chamfer "Option A" and the flared nose.* Two further passes
  were attempted and then rolled back because they added complexity/artifacts for little
  gain: (1) **Option A** rebuilt the cap as a narrow ramp + a full-wall-width chamfer block
  so `box()` bevelled both long edges continuously and added nose-chamfer cutters — but the
  widen-back left a ~0.8 mm down-facing ledge, and (2) a **50° flared nose** replaced the
  square nose. The user judged the nose surgery unnecessary ("you only needed to cut along
  the orange") and asked to go back. **Reverted to the state below:** the narrow
  (`CAP_HW = 2.2`) self-supporting hat with the 60° shoulder ramp, C-merged-into-B, the
  0.5 mm feather land, long edges chamfered as they were before Option A (cap-sliver + gap
  + female-land — acceptable), and a **plain square nose**. No `NOSE_*` params, no nose
  cutters, no full-width chamfer block. Saved as the known-good snapshot
  `openscad/cutlery_box_v2.scad`. Re-verified: 0 mm female overhang, 60° shoulder, all
  seven drops clear, bed-fit OK (spoon ~118), rim continuous (single seam, line C gone).
- *Final cap shape — full-width, 50° ramp to the outer corner (no step).* After looking
  at a labelled cross-section, the user chose: the cap reaches the **FULL wall width** at
  the chamfer base, and its underside is **ONE 50° ramp straight to the chamfer's outer
  corner** (no little horizontal step) down to the dovetail neck. This makes the outer top
  edge read as the wall extended (no recessed sliver — the "negative→positive" fix) and the
  male underside a single clean self-supporting ramp (50° from horizontal = 40° from
  vertical, well inside the FDM limit). `CAP_HW = HOST_T/2`, `CAP_SLANT_DEG = 50`,
  `FEATHER_MIN` removed. **Accepted tradeoff:** with no step, the female wall tapers to a
  thin feather at z≈57 (gradual, hidden in the joint) — the user OK'd this in exchange for
  the solid top. Square nose retained. Verified: shoulder 50°, all seven drops clear,
  bed-fit OK (spoon ~118), rim continuous (single seam). Snapshot `openscad/cutlery_box_v3.scad`.
- *Female recess to the corner too (mirror the male).* v3 still had the female recess sized
  `cap + CAP_CLR`, so its ramp crossed the wall edge at z≈56.3 — well below the chamfer
  corner — leaving a vertical lip on the female (the male cap reached the corner at z57 but
  the female didn't). Fix: the recess now reaches the wall edge **at the corner**
  (`CAP_ZRAMP_R = CAP_ZRAMP`, recess top width `CAP_HW + EPS` instead of `+ CAP_CLR`), so
  the female opening ramps to ~z57 like the male; the play is kept on the lower ramp + floor.
  Verified: female top now ~57 at the joint (was 56.2), all seven drops clear, bed-fit OK,
  rim continuous. Snapshot `openscad/cutlery_box_v4.scad`.

## Version snapshots

- **`openscad/cutlery_box_v1.scad`** — known-good baseline = the OpenSCAD
  cut-from-solid model **after the zero-thickness-flap fix** but **before the
  top-edge "hat"/cap work**. All six pieces verified flap-free, watertight, bed-fit,
  and drop-clear at this snapshot. Roll back to this if the cap work ever needs to
  be reverted.
- **`openscad/cutlery_box_v2.scad`** — earlier known-good = the narrow hat (60° shoulder,
  0.5 mm feather land, square nose).
- **`openscad/cutlery_box_v3.scad`** — full-width cap, 50° ramp to the corner (male side),
  but the female recess still topped out below the corner (vertical lip).
- **`openscad/cutlery_box_v4.scad`** — ✅ **PRINT-READY RELEASE (body only, NO LID).** v3
  **plus the female recess also ramping to the chamfer corner** (mirror of the male;
  vertical lip removed). All six exported STLs certified watertight / 2-manifold / 0 flaps /
  bed-fit OK (see the certification milestone above). This is the version to slice and print
  (floor-down, no supports). Mirrored by the release copy
  **`openscad/cutlery_box_PRINT_READY_no_lid.scad`**. (No longer the live file — see v5.)
- **`openscad/cutlery_box_v5_lid.scad`** — v4 plus the first LID pass (segmented hinge
  groove, 3 mm ledges). Superseded by v6.
- **`openscad/cutlery_box_v10_lid.scad`** — current LIVE = v9 with the hinge relief rebuilt
  as **one straight ~45° ramp** from the journal's inner-top up to the inner rim (replacing
  the small corner triangle, which left a kink in the cap underside that a swinging lid would
  catch on). The ramp rises toward the inner edge — matching the lid's rotation about the
  journal — keeps the cap full directly over the bullnose (retention survives), and at ~45°
  it's **self-supporting** (prints clean). Removed the now-unused `GROOVE_MOUTH_EASE`/
  `EPX_MOUTH`. Verified: monotonic ramp (no kink), cap retains, single connected mass (no
  sliver), hinge overhangs ≤0.4 mm + the journal bore top is a ~2 mm bridge (PETG-printable),
  bed-fit ≤120, drop CLEAR.
- **`openscad/cutlery_box_v9_lid.scad`** — v8 with the journal **set back 2 mm**, corner-to-corner. Key insight from this round: the lead-in slot
  (the "rectangular depression") is what makes the lid retain — setting the journal back from
  the face puts the retaining **cap (x3–5) clear of the swing relief** (which lives at the
  inner edge), so the cap holds the bullnose. A journal flush at the face looked cleaner but
  the relief + inner rim chamfer ate the cap → no retention. So: 2 mm lead-in slot → half-
  cylinder journal at x4 → angled triangle relief above for the hinge swing. `GROOVE_DEPTH=3`
  (2 mm lead-in + 1 mm radius), `GROOVE_END_INSET=0` (runs to the corners). Verified: cap
  solid over the bullnose (retains), swing relief at the inner edge, ~3 mm wall behind, single
  connected mass (no sliver), bed-fit ≤120, drop CLEAR. **Tunable:** `GROOVE_MOUTH_EASE` sets
  the open angle (bigger = wider swing, but trades cap/retention) — confirm the angle on a print.
- **`openscad/cutlery_box_v8_lid.scad`** — v7 plus the **recessed, capped hinge**. The journal was reaching the rim (top at z58) and breaking the chamfer with no
  material over the bullnose — it wouldn't retain the lid. Now `LID_RECESS = 2.0`: the lid
  top sits at **z56 (2mm below the rim)**, the journal centre drops to z55 so its **top is at
  z56, fully capped** by the z56–58 wall — the rim now holds the bullnose when the lid is
  raised. Insertion is **tilt-in** (raise to the open angle, slide the bullnose under the cap,
  swing down). The mouth-ease moved to relieve the cap's inner-bottom corner and tapers from
  1.2mm at the inner face to ~0.2mm at the journal (retain + swing). Clip dropped to retain
  the lid top at z56 (no longer protrudes above the rim → fork_B back to 58mm). Inner dividers
  now lower to z54 (their hidden A/B caps are removed but the lid covers them; joint engages
  z3–54). Verified: journal capped, single connected mass at all ends/seams (no sliver),
  bed-fit ≤120, 7-joint drop CLEAR. **Watch on print:** the cap underside is a ~2mm overhang
  over the journal (a short bridge) — chamfer it if it sags. Still F6 to certify on STLs.
- **`openscad/cutlery_box_v7_lid.scad`** — v6 plus the **groove-end fix**:
  the eased mouth now eases the **slot inner-top edge** (`EPX_MOUTH = POCKET_CX`) instead of
  the pocket back, which removes a thin undercut lip (a near-zero-thickness feather that read
  as a "floating" bit at the corner — a real flap risk), and the groove now **starts one
  chamfer past the corner** (`GROOVE_END_INSET = CHAMFER + 1`, → y=8). 3D connected-component
  flood-fill at both groove ends and all seam crossings shows a **single solid mass (no
  detached sliver)**; 4 mm wall behind the groove; cross-sections all single contiguous
  outlines. Re-verified bed-fit/drop/overhang/invariants; still F6 to certify on real STLs.
- **`openscad/cutlery_box_v6_lid.scad`** — lid refined per design review:
  **ledges narrowed to 2 mm and inset from the corners**, **hinge groove now CONTINUOUS**
  end-to-end (y≈7→296) with a **tapered eased mouth** at each end, and **clean corners**
  (the wall's 1 mm chamfer wraps every corner; the old stub is gone). Identical to the live
  `openscad/cutlery_box.scad`. Re-verified: bed-fit ≤120, 7-joint drop clearance, overhang
  unchanged, ledges self-supporting, ~4 mm wall behind the groove with no outside breach.
  The continuous groove shaves only the top ~2.4 mm inner tips of the two chamber dovetails
  (≥2.6 mm wall remains at the seams in the voxel model) — the **flap/cap-feather
  certification at those seams still needs an F6 export** (the cap feather is thin there).

## The LID (box features for an ordered flat sheet)

The lid is a flat **ordered ~2 mm PETG/Tritan sheet**, bullnose-polished edges (r=1.0) —
not printed. The box gets the receiving features (all at the top, above the dovetails/
half-lap, so the vertical-drop assembly and the hidden hat/chamfer are untouched):
- **Perimeter support ledge** at z=56 (lid underside) — 45° self-supporting brackets on the
  clip end wall + the two short walls; lid rests flush (top at the rim, z=58).
- **Hinge groove** on one 303 mm end wall (default −x): 1 mm straight lead-in + a 1 mm
  journal half-cylinder the bullnose edge rolls in, with a 45° mouth-ease so the rigid sheet
  swings up and lifts out. **Continuous** end-to-end (y≈7→296), inset 1 mm from each short
  wall, with the eased mouth tapered out over 4 mm at each end; ~4 mm wall left behind it.
  It shaves only the top ~2.4 mm inner tips of the two chamber dovetails (engagement below
  z≈55.6 intact). New params: `GROOVE_END_INSET`, `GROOVE_TAPER`.
- **Lowered inner dividers** to z=56 (mid-support, no sag; outer walls stay full height).
- **Retaining clip** (one, 18 mm, centred on the +x end wall at the fork): 0.4 mm ramped lip
  cams the lid under on close; **finger scallop** (16 mm dish) aligned with it to lift.
- Tunable params at the top of the .scad (`LID_T, LID_PLAY, HINGE_AT_MINUS_X, LEDGE_W,
  GROOVE_*, CLIP_*, SCALLOP_*`).

**Ordered sheet spec: 196.5 mm (hinge↔clip) × 290 mm × 2.0 mm, all four edges bullnose
r1.0, polished.** (Drops into the 196×291 opening; hinge edge engages ~1 mm into the
groove, clip edge tucks under the lip, ~0.5 mm clearance on the short ends.)

## ⭐ MILESTONE — all six exported STLs certified

The user F6-exported all six parts from the v4 model and they passed the full
detector suite (run on the actual exported meshes, not the replica):

| piece | tris | degenerate | open edges | non-manifold | flaps | Euler | bbox X/Y/Z |
|-------|------|-----------|-----------|--------------|-------|-------|------------|
| knife_A | 192 | 0 | 0 | 0 | 0 | 2 | 109/86/58 |
| knife_B | 242 | 0 | 0 | 0 | 0 | 2 | 110/86/58 |
| fork_A  | 208 | 0 | 0 | 0 | 0 | 2 | 109/116/58 |
| fork_B  | 232 | 0 | 0 | 0 | 0 | 2 | 110/116/58 |
| spoon_A | 160 | 0 | 0 | 0 | 0 | 2 | 109/119/58 |
| spoon_B | 186 | 0 | 0 | 0 | 0 | 2 | 110/119/58 |

Every piece is **watertight** (0 open edges), **2-manifold** (every edge shared by
exactly 2 faces; **Euler V−E+F = 2** → a single closed shell, no holes/handles),
**0 zero-thickness flaps** (the original defect is gone), **0 degenerate triangles**,
and **bed-fit** OK (largest = spoon 119 mm Y, B-halves 110 mm X — all < 120 mm).
(Note: an early pass flagged a few "non-manifold" edges; that was a vertex-welding
rounding artifact in the checker at 3-decimal precision — at 5 decimals they vanish.)

## Where it stands

- 6 body pieces, each fits the 120 mm bed, print floor-down with no supports.
- Watertight **and** flap-free (zero-thickness defect eliminated) — **certified on the
  actual exported STLs**.
- One rigid assembled unit via flush hidden dovetails (A/B + chamber-to-chamber),
  with the dovetail joinery now hidden under a continuous, capped top rim (full-width
  cap, 50° self-supporting shoulder, female recess mirrored to the corner).
- Half-lap base seams keep neighbouring plates coplanar (anti-warp).
- Sized to real cutlery for 3 columns per chamber; comfort-chamfered rim.

**Open items:** print-verify the capped joints on a fresh test print, then design
the **lid** — the user can order a custom-size sheet of food-grade cut plastic
(no sharp edges, durable), so the next step is deciding the lid mechanism
(attach/seal/slide), whether it's printed, the ordered sheet, or a combination,
and the retention/seating features on the box rim.

---

## Technical reference

- **`openscad/cutlery_box.scad`** — the live, parametric, cut-from-solid model
  (OpenSCAD/CGAL). Set `part` (or use the Customizer dropdown) and export each of
  the six. `openscad/cutlery_box_v1.scad` is the pre-cap snapshot.
- `build_box.py` — the original self-contained hand-mesh generator (Python stdlib
  only). Superseded by the OpenSCAD port but kept as the source of all parameters.
- Key parameters: `HOST_T` (6 mm wall), `BASE` (3 mm floor), `COMP_H` (55 mm
  height), `HALF_LEN` (104 mm); dovetail `DT_DEPTH/NECK/FLARE`, `DT_CLR`
  (0.4 mm flank clearance), `DT_DEPTH_RELIEF` (0.3 mm socket back relief);
  `CHAMFER` (1 mm rim); half-lap `LAP_LEN`/`LAP_LEN_FS`/`LAP_Z`/`LAP_CLR`;
  `SEAM_EPS` (0.02 mm cut-plane nudge — the flap fix); hidden cap `CAP_SLANT_DEG`
  (60° self-supporting underside), `CAP_FOOT` (= `DT_NECK`), `CAP_CLR` (0.3 mm),
  `FEATHER_MIN` (0.5 mm female land); `CAP_H` is derived (≈2.73 mm — ramp tops at the
  chamfer base) and `CAP_HW` (2.2 mm cap half-width) leaves the feather land. The nose is
  left plain/square (the `NOSE_*` params and nose cutters were tried and reverted).
- Geometry approach: one chamfered solid, `difference()`-d by vertical dovetail
  prisms to both form the joints and split the pieces; smooth chamfer from
  `hull()` frustums. Cut planes are kept off coincident box faces (`SEAM_EPS`) and
  all unions interpenetrate by an epsilon → no zero-thickness flaps.
- Verification tooling (this repo's history): an **overlapping opposite-face flap
  detector**, edge-manifold/open-edge check, a voxel CSG re-implementation for
  bed-fit, vertical-drop-clearance, and top-rim continuity.

---

## ★ STABLE BASELINE — v23_stable (2026-06-23)

**File:** `openscad/cutlery_box_v23_stable.scad` (identical to `cutlery_box.scad` at this point).

First fully stable lid design. Locked-in features:
- Recessed clear-sheet lid (LID_T=2, LID_RECESS=2 → lid top z56, rim z58).
- Capped journal hinge on the −x long wall (2 mm setback → half-cylinder bore → swing-relief ramp), runs straight to the wall ends, capped by the short walls; rim chamfer continuous through all divider junctions (both A and B sides).
- Hidden-dovetail "hat" caps on inner divider A/B center seams (50° self-supporting underside).
- Two **light detent clips** (CLIP_LIP=0.3, self-supporting; 0.3 mm overhang prints without support) flanking an **elliptical finger notch** (NOTCH_W=20, NOTCH_ARCH=4) in the +x clip wall.
- Support rail (lid_ledge) cut away across the notch span so a fingertip reaches under the lid edge; rail still pinches the lid against the clips everywhere else.
- `assembly()` renders the true 6 parts.

Verified: SCAD brace/paren/bracket balance OK; def-before-use OK; analytic + focused voxel renders.

**Next step:** iterate on the lid/clip/notch from feedback after the initial physical prints. Branch from the STABLE file — do not overwrite it. Pending before mass export: rebuild the voxel verifier and run the full flap/manifold/watertight/bed-fit/drop certification on all six parts (needs F6-exported STLs).

---

## ⭐ HIGHLIGHT — Second trial print: tuning the dovetail with a fit test rig (2026-06-23)

The second trial reprinted the two fork pieces after the Option-A dovetail change
(`DT_FLARE` 2.1→1.7, `DT_CLR` 0.4→0.3, growing the female ears 0.5→1.0 mm). The
**female side came out exactly right** — firm, no longer flimsy, and visually
integrated into the wall face. That socket is now **locked: do not touch it.**

But shrinking the flare also shrank the **male**, and the male went too far the
other way: it drops in easily, then pulls straight back out under a light
perpendicular tug. The geometry says why:

| Part | Neck (full) | Flare (full) | vs. locked female cavity |
|------|-------------|--------------|--------------------------|
| Female cavity (locked) | 3.0 mm | 4.0 mm | — |
| New male (DT_FLARE 1.7) | 2.4 mm | 3.4 mm | **0.3 mm slop per side → loose** |
| Old male (DT_FLARE 2.1) | 2.4 mm | 4.2 mm | flare **0.1 mm too wide → binds, won't enter** |

So the old male's *flare* (the long, locking width) is wider than the new socket
and jams, while its *neck* (the short width at the wall face) drops in fine —
which is precisely what the print showed. The fix is asymmetric: **grow the male
only, leave the female alone** (decouple them so the good socket never moves).

> **Insight:** once the female is dialed in, never re-tune it to chase the male.
> Hold the cavity fixed and move the male toward it. The right male is "female
> cavity minus a small per-side slide clearance."

### The fit test rig

Rather than guess one male size and burn a full reprint, we built a **male-fit
test rig**: four short (20 mm, not full-height) male coupons, each a bare dovetail
tongue on a grip, at graduated per-side clearances against the locked female
cavity. Each coupon is **pip-coded** (1–4 raised dots on the grip) so it's
identifiable after it comes off the bed.

| Pips | Clearance / side | Male neck / flare (full) |
|------|------------------|---------------------------|
| 1 | 0.20 mm | 2.60 / 3.60 mm (loosest) |
| 2 | 0.15 mm | 2.70 / 3.70 mm |
| 3 | 0.10 mm | 2.80 / 3.80 mm |
| 4 | 0.05 mm | 2.90 / 3.90 mm (tightest) |

Procedure: print all four, slide each tongue into the already-printed (and loved)
fork female socket, and pick the **highest pip count that still slides by hand but
resists the perpendicular pull.** That clearance becomes the model's new male
size; the female stays as-is.

- Generator: `make_dovetail_rig.py` (pure stdlib, emits binary STL directly — no
  OpenSCAD export needed). Output: `dovetail_fit_test_rig.stl` (~94 mm row, prints
  floor-down, no support). Coupons print tongue-up to match real layer orientation.

> **Insight:** when one mating half is already perfect, test the other half in
> isolation with a cheap graduated coupon against the *real* printed part — far
> faster and more reliable than re-deriving clearances on paper or reprinting a
> whole piece per guess.

### Side note from the same print: flat lap steps trap support

The fork/spoon base lap had been converted to a **45° ramped lap** (Issue 5) and
printed support-free this round. The lap steps still left **flat** (the A/B
mid-seam, the knife/fork divider) again trapped support in their shallow pockets
that could not be cleaned out — confirming the ramp is not merely nicer but the
actual fix. So **all** the base laps are now ramped (Issue 6): `fs_wedge`/`fs_pocket`
reused at the knife/fork divider, and new `ab_wedge`/`ab_pocket` (X-Z profile,
prism along Y) for the three A/B-seam laps. Each 6 mm lap shortens to ~1.5 mm of
engagement to keep a true 45° — a little anti-warp grip traded for support-free
printing.

> **Caveat (A/B seam):** the A/B lap was originally kept flat *on purpose* —
> horizontal faces don't bind during the straight-down drop of the B row onto the
> A row, whereas two 45° faces can cam. The 0.2 mm clearance should absorb it, but
> the A/B joint must be **assembly-tested** before the full six-piece run. The
> knife/fork lap, like fork/spoon, engages by lowering a neighbour in-row, so it
> carries the same low risk as the already-validated red lap.

See `TRIAL_PRINT_FIX_PLAN.md`, Issues 5–6.
