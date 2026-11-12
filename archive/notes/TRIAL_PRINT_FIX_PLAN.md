# Trial-Print Debrief & Fix Plan

Diagnosis of the first trial print (AOSEED FDM, gradient filament), with ranked
fixes for the next run. **Settings fixes** can be applied immediately in the
slicer. **Design fixes** require a `cutlery_box.scad` edit and are flagged for the
sequential merge (do NOT edit the model from this analysis — the lid task is
modifying it in parallel).

Geometry figures below are computed from the live parameters in `cutlery_box.scad`
(`HOST_T 6`, `DT_NECK 1.2`, `DT_FLARE 2.1`, `DT_DEPTH 5`, `DT_CLR 0.4`,
`CAP_SLANT_DEG 50`, `CHAMFER 1.0`, `BASE 3`, `LAP_Z 1.5`, `LAP_LEN 6`).

---

## Issue 1 — Bulged / curved base corner

**What I see:** outward splay confined to the bottom ~1–3 mm of layers at the
base corner and the bottom of the wall-to-wall corner; the wall above is straight.

**Diagnosis:** classic **elephant's foot** (first-layer over-squish), *not* warp.
Warp would lift the corner up and bow the base concave; here it spreads out/down.
The model has square inside-bottom corners by design, so squish shows up here.

**Root cause (ranked):** (1) first layer over-squished — Z-offset/nozzle too low;
(2) bed too hot / weak cooling on the lowest layers; (3) first-layer flow too high.

**Fixes — SETTINGS (do these, no model change):**
1. Enable **elephant-foot compensation**: Cura "Initial Layer Horizontal Expansion"
   = **−0.15 to −0.20 mm**; PrusaSlicer/Orca "Elephant foot compensation"
   = **0.15–0.20 mm**.
2. Re-level / nudge **Z-offset up ~0.02–0.04 mm** and/or drop **first-layer flow
   to ~95%**.
3. **Lower bed temp ~5 °C after layer 1**; ensure part-cooling fan is on for the
   lower layers so corners firm up.

**Design fix (only if settings don't fully solve it):** a 0.4–0.6 mm bottom outer
chamfer on the walls. Hold unless needed — this is a settings problem.

**Why it matters:** a splayed foot stops pieces sitting flush at seams and can
fight the half-lap and the bottom of the dovetail engagement.

---

## Issue 2 — Female dovetail prints as two thin walls; male pulls out  ★ priority

**What I see / user report:** the tail **slides** but **wiggles enough to pull
back out**; the female side **feels flimsy, like it'll snap**. Also, from the
**outside the joint is visible** — the two sides of the socket read as a separate
vertical strip, different in sheen/texture from the wall running into them. (Test
coupon was only the first ~5 mm of height.)

**Two requirements, then:** (a) **structural** — the female must hold the tail and
not feel fragile; (b) **cosmetic** — the exterior must read as one continuous wall,
no visible joint at the vertical seam edge.

**Diagnosis — DESIGN (confirmed by geometry):**
- Socket full width at the tail tip = `2 × (DT_FLARE + DT_CLR)` = **5.0 mm**, sunk
  into a **6.0 mm** wall, centered → only **0.5 mm of material on each side**: a
  0.5 mm inner ear AND a 0.5 mm **outer skin**.
- 0.5 mm ≈ one 0.4 mm nozzle line. The **inner ear** flexes → the tail wiggles/
  releases and feels fragile. The **outer skin** is one lonely perimeter over a
  5 mm-wide × 55 mm-tall void → it prints with a different sheen and shows the
  vertical seam lines → the joint is visible from outside. Same 0.5 mm, both
  symptoms.
- The flare angle is a normal **10.2° off the slide axis** (hook 0.9 mm/side), so
  the *angle* is fine — the **thin walls** are the failure. Can't be fixed in slicer.
- Note on "pulls out": real engagement is **55 mm**, not the 5 mm coupon — a full-
  height sliding dovetail is far stiffer (the tail can't lever out over 55 mm). So
  the coupon overstates the wiggle, but the flimsy ears are still the weak point.

**Decision: keep the wall at 6 mm (no boss) and shrink the tail instead.** The ear
budget is `ear = HOST_T/2 − (DT_FLARE + DT_CLR)`. The first print had a lot of slide
play, so we spend it: shrink the flare and tighten the clearance to grow the ears
without touching the 6 mm wall. (The 8 mm inner-boss idea is shelved — it intrudes
into the bay, which we don't want.)

**★ APPLIED — Option A** (`cutlery_box.scad`, dovetail block):
- `DT_FLARE 2.1 → 1.7`, `DT_CLR 0.4 → 0.3`, `DT_NECK` unchanged (1.2).
- → ear = 3 − (1.7 + 0.3) = **1.0 mm** (was 0.5) on both the inner ear and outer skin.
- Undercut hook = DT_FLARE − DT_NECK = **0.5 mm** (was 0.9) — lighter but fine for a
  *vertical sliding* dovetail (hold comes from the 55 mm slide length + snug fit).
- Male tail neck unchanged → male keeps its strength. Outer skin now 1.0 mm → joint
  reads as solid wall from outside.

**FUTURE TRIAL — Option B** (documented in the .scad, not applied): thicker ears
still, at the cost of a thinner male neck.
- `DT_NECK 1.2 → 1.0`, `DT_FLARE 2.1 → 1.5`, `DT_CLR 0.3`.
- → ear = 3 − (1.5 + 0.3) = **1.2 mm**; hook = 1.5 − 1.0 = 0.5 mm (same as A).
- Trade: male neck narrows 2.4 → 2.0 mm (full width), so the *male* gets a bit
  weaker. Try only if Option A's 1.0 mm ears still feel thin. Switch one option in
  at a time and re-test the knife pair.

**Rejected:** (a) global `HOST_T 6 → 8` — widens every wall, risks the spoon piece
past the 120 mm bed; (b) inner boss — intrudes into the bay; (c) offsetting the
socket outward — thins the inner ear and lets the tail lever out toward the bay.

---

## Issues 3 & 4 — Half-lap base step: floating lip / negative step needs support  ★ priority

These are **the same defect** in two places — the base half-lap, seen along the
edge (photo 3) and at the corner (photo 4). (Earlier I misread photo 3 as the
hidden-dovetail cap; it is not. The cap was **not** a reported problem.)

**What I see:** on the *receiving* pieces the half-lap leaves a **negative step —
empty space sitting on the bed — with the floor lip floating above it**. That lip
gets supported during printing, and because the support is buried in the shallow
pocket it won't pull out cleanly, leaving ridge lines along the edge (red) and
fused residue at the ends (yellow). At the corner the same lip reads as a dangling
tab.

**Diagnosis — DESIGN (confirmed by geometry):** `lap_neg_*` removes the **bottom
half** of the floor (z 0 → `LAP_Z` 1.5) over the lap region on the receiving
piece, to seat the other piece's tongue. That leaves the lip floating at **z 1.5 →
3.0 over a 6 mm (`LAP_LEN`) cantilever** with open air below. The lip's ceiling is
anchored on only one edge and overhangs ~6 mm, so it can't bridge support-free →
support is forced → it cannot be cleaned out of the pocket tidily.

**No clean settings fix:** the cantilever is one-sided (can't bridge), and
reorienting the piece would throw support under the dovetails instead.

**DECISIONS (split the two locations):**

*Issue 3 — the long edge step:* **keep the flat horizontal half-lap; hand-file the
support residue.** A 45° scarf/ramp was considered and **rejected** — it feathers
the lap edge to near-zero thickness on the bed, and thin feathered edges are the
worst for warping/curling. Trading a little hand-finishing for no warp risk is the
better deal. No model change.

*Issue 4 — the crossing corner:* **★ APPLIED — full-height corner key.** At each
A/B-seam × divider crossing the dangling thin tab is replaced by a **solid
full-height base corner on the divider-owning piece** (sits under that piece's own
divider wall → anchored, squared off, no dangle), and the neighbour's chamber shelf
is **clipped back by `LAP_CLR`** (the "negative") so nothing collides.
- knife/fork crossing → boss on **knife_A**; clip **fork_A**'s SEAM_KF chamber shelf.
- fork/spoon crossing → boss on **fork_A**; clip **spoon_A**'s SEAM_FS chamber shelf.
- New `corner_key(seam_x, lap_x, y0, y1)` module + `CORNER_CLIP` constant; bosses
  unioned AFTER the per-part cuts so the lap negatives don't eat them. B pieces are
  on the far side of the seam → untouched.
- Tradeoff: that 6 mm corner becomes a vertical solid (not a horizontal shingle), so
  its anti-lift there now relies on the neighbouring laps + chamber dovetails. Minor.

**Why the boss must be on the divider-owner:** the solid corner hangs from that
piece's own divider wall. Put it on the non-owner and it would float with no wall
above it. (Flipping boss/pocket would re-introduce a dangle on the other piece.)

**VERIFY (user):** OpenSCAD can't run in this sandbox. F5/F6 `knife_A`, `fork_A`,
`spoon_A`, and `assembly`; confirm each crossing corner is a clean solid square,
the clipped shelves clear it, and the assembly shows no overlap/gap. Watch the
console for any "not a valid 2-manifold".

---

## Next-print action list

**Apply now (slicer only):**
- Elephant-foot compensation −0.15..−0.20 mm; Z-offset up a hair; first-layer flow ~95%; bed −5 °C after layer 1 (Issue 1).
- Reprint a single joint pair (e.g. `knife_A` + `knife_B`) to re-test before committing all the filament.

**APPLIED to `cutlery_box.scad` (verify in OpenSCAD, then reprint the knife pair):**
- Option A dovetail: DT_FLARE 2.1→1.7, DT_CLR 0.4→0.3 → ears 0.5→1.0 mm (Issue 2). ★
- Full-height corner keys at both lap crossings + clipped neighbour shelves (Issue 4). ★

**Kept / by hand:**
- Issue 3 (long edge step): flat half-lap kept; file the support residue. No model change.
- Issue 1 (elephant's foot): slicer only — foot compensation, Z-offset, flow, bed temp.

**Future trial (documented, not applied):**
- Option B dovetail (1.2 mm ears, thinner male neck) — one-line swap in the .scad.

**Verification before the full 6-piece run:**
- Reprint one joint pair; confirm the dovetail now holds against a perpendicular pull, and the half-lap lip prints with no floating step and no support residue.

---

## Issue 5 — Fork/spoon base lap: trapped support → 45° ramped lap  ★ APPLIED

**Source:** second trial print of `fork_B` (the notch/clip piece). The fork/spoon
base lap's "negative" pocket filled with support that could not be cleaned out of
the shallow 1.5 mm-tall blind pocket. Same defect is present on `fork_A` at the
same seam. (User confirmed scope and orientation in review.)

**Decision — DESIGN, flagged for the sequential merge (do NOT edit the model here;
the lid task owns `cutlery_box.scad`).**

**Scope — fork/spoon seam (`SEAM_FS`) ONLY, this round.** The identical floating-
step lap also exists at the knife/fork divider (`SEAM_KF`, on `knife_A`/`knife_B`,
6 mm) and along the A/B mid-seam (`lap_*_X`, on all three A pieces, 6 mm). Those
are **deferred** — leave them flat half-laps for now. Do them in a later pass if
this works.

**Fix — replace the horizontal half-lap with a 45° ramped lap, Option 1 orientation.**
Cross-section is in the Y–Z plane at the seam; the prism runs along X.

- **Spoon owns a solid wedge** (sits flat on the bed): full height `LAP_Z` (1.5 mm)
  at the seam face (`y = SEAM_FS`), tapering linearly to **zero** a distance
  `RAMP = LAP_Z` (1.5 mm) into the fork bay (`y = SEAM_FS − LAP_Z`). Run == rise ==
  1.5 mm → a **true 45°**. No thin/feathered edge anywhere on the wedge.
- **Fork gets the complementary ramped pocket:** keeps full base thickness out into
  its bay (solid bed contact, `y < SEAM_FS − LAP_Z`); over the lap its underside is
  the 45° ramp rising from the bed up to `z = LAP_Z` at the seam. **No flat
  downward roof → prints with no support.** The fork lip at the seam is still the
  top `BASE − LAP_Z` = 1.5 mm, now ramp-backed instead of floating.
- **Orientation = Option 1** (confirmed): solid floor runs into the bay, ramp tucked
  at the divider, spoon wedge solid on the bed. (Option 2 — ramp opening into the
  bay — was rejected: it feathers the spoon tip to zero at the seam and thins the
  fork lip at the bay junction.)
- **Clearance:** keep a `LAP_CLR` (0.2 mm) gap — cut the fork pocket as the spoon
  wedge **enlarged by `LAP_CLR`** (same philosophy as today's `lap_neg_Y`, which
  removes `ln + LAP_CLR`). This also matters because assembly is a straight-down
  drop and two flush 45° faces would otherwise cam/jam; the 0.2 mm gap lets the
  wedge seat. The lap is for coplanarity/anti-warp, so light (non-pressed) contact
  is fine.
- **Engagement length** shrinks from `LAP_LEN_FS` (2 mm) to `LAP_Z` (1.5 mm) at
  these two laps — fine for an anti-warp feature, and the ramp actually keys the
  pieces in better than a flat shelf.

**Exact call sites to change (x-spans unchanged — only the shelf/neg shape):**

- `fork_A` — line ~687: `lap_neg_Y(SEAM_FS, 0, AB_SEAM, LAP_LEN_FS)` → ramped pocket.
- `fork_B` — line ~714: `lap_neg_Y(SEAM_FS, AB_SEAM, TOTAL_LEN, LAP_LEN_FS)` → ramped pocket.
- `spoon_A` — line ~732: `lap_shelf_Y(SEAM_FS, 0, AB_SEAM − CORNER_CLIP, LAP_LEN_FS)` → ramped wedge (keep the `− CORNER_CLIP` clip).
- `spoon_B` — line ~752: `lap_shelf_Y(SEAM_FS, AB_SEAM, TOTAL_LEN, LAP_LEN_FS)` → ramped wedge.

**Do NOT touch:** the `SEAM_KF` laps, any `lap_*_X` (A/B seam) laps, or the existing
fork/spoon `corner_key` (line ~690). Those stay as-is.

**As implemented in `cutlery_box.scad`** (modules `fs_wedge` / `fs_pocket` just below
`lap_neg_Y`; four call sites at `SEAM_FS` swapped). Built with `linear_extrude` +
`rotate([90,0,90])` (always manifold — no polyhedron winding to get wrong). The
axis mapping, 45° slope, and clearance were checked numerically (no OpenSCAD in the
authoring sandbox):

- `rotate([90,0,90])` maps the local `(y,z)` profile to world Y-Z and extrudes the
  prism along +X — verified world X span and ramp `dz/dy = 1.0` (true 45°).
- **Clearance:** the fork pocket is the wedge profile grown with `offset(delta=LAP_CLR)`
  → a **uniform 0.2 mm** gap along the slanted mating face (an inset version pinched
  to ~0.07 mm at the seam — a near-press fit — so it was rejected). Cost: lip thins
  from 1.5 → **~1.3 mm** near the seam (acceptable; the divider wall sits on it).

```scad
module fs_wedge(seam_y, x0, x1) {     // spoon-owned solid wedge, flat on bed
    translate([x0,0,0]) rotate([90,0,90]) linear_extrude(x1-x0)
        polygon([[seam_y-LAP_Z, 0], [seam_y+2*SEAM_EPS, 0], [seam_y+2*SEAM_EPS, LAP_Z]]);
}
module fs_pocket(seam_y, x0, x1) {    // fork negative = wedge grown by LAP_CLR
    translate([x0-EPS,0,0]) rotate([90,0,90]) linear_extrude((x1-x0)+2*EPS)
        offset(delta=LAP_CLR) polygon([[seam_y-LAP_Z,0],[seam_y,0],[seam_y,LAP_Z]]);
}
```

**VERIFY (user, OpenSCAD — can't run in this sandbox):** F5/F6 `fork_A`, `fork_B`,
`spoon_A`, `spoon_B`, and `assembly`. Confirm (1) on each fork piece the lap
underside is a clean 45° ramp down to the bed with **no flat roof**; (2) the spoon
wedge is a solid triangle sitting on the bed with no feathered tip; (3) assembled,
the wedge seats in the pocket with a ~0.2 mm gap (not a press fit); (4) no "not a
valid 2-manifold" in the console.

**Reprint note (carries over from Issue 2):** the new dovetail sockets are sized
for the **new** (Option A) male tail — the tip shrank 4.2 → 3.4 mm. **Old printed
males won't fit new females.** Reprint *both* halves of any joint pair together;
don't mix first-print and new pieces.

---

## Issue 6 — Angle ALL remaining base laps (knife/fork + A/B seam)  ★ APPLIED

The second trial confirmed flat lap steps trap unremovable support (the "stairs
step" on `fork_A`'s A/B seam). So the 45° ramp is extended from fork/spoon to
**every** base lap. (User: "do all.")

**Knife/fork divider (`SEAM_KF`, was 6 mm):** same orientation as fork/spoon
(upper chamber owns the wedge), so the existing modules are reused directly —
`fs_pocket` on `knife_A`/`knife_B` (the negatives), `fs_wedge` on `fork_A`/`fork_B`
(the shelves). x-spans/clips unchanged.

**A/B mid-seam (`AB_SEAM`, was 6 mm):** new modules `ab_wedge`/`ab_pocket` (profile
in X-Z, prism along Y, built `rotate([-90,0,0]) linear_extrude` — verified: world X
tip at `AB_SEAM−LAP_Z`, full `LAP_Z` at the seam, ramp `dz/dx = 1.0`, uniform
`offset(delta=LAP_CLR)` clearance). `ab_pocket` on the A pieces (`knife_A`,
`fork_A`, `spoon_A`), `ab_wedge` on the B pieces (`knife_B`, `fork_B`, `spoon_B`),
same y-spans/clips as the old `lap_*_X`.

All 14 base-lap call sites are now ramped; the flat `lap_shelf_*`/`lap_neg_*`
modules remain defined but unused. Engagement on the 6 mm laps shortens to ~1.5 mm
(true 45°) — minor anti-warp trade for support-free printing.

**★ ASSEMBLY CAVEAT — A/B seam only:** the A/B lap was originally flat *on purpose*
— horizontal faces don't bind during the straight-DOWN drop of the B row onto the
A row; two 45° faces can cam. The 0.2 mm clearance should absorb it, but **assembly-
test a full A-row + B-row stack before the six-piece run.** If it binds, the cheap
fix is more clearance on the A/B laps only (bump `LAP_CLR` for `ab_*`, or revert
just the three `ab_*` sites to flat from the `*_amber` backup). Knife/fork engages
in-row like fork/spoon → low risk.

**VERIFY (user, OpenSCAD):** F6 all six parts + `assembly`. On each negative side
(`knife_A/B` at the divider; `knife_A`,`fork_A`,`spoon_A` at the A/B seam) confirm a
clean 45° ramp to the bed, no flat roof; wedges solid on the bed; no "not a valid
2-manifold." Then **dry-fit an A row onto a B row** to check the A/B laps seat.
