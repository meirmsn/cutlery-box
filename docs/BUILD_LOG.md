# Build log

How a box for disposable cutlery went from a chat to a six-piece print in daily use, and what that taught. Design dates come from the project files' timestamps (US Pacific time; the design notes in the archive are dated in UTC, so some say a day later). Later dates come from the photos. The close-up photos of test pieces were taken afterwards, of the leftover prints, and are placed where those prints belong in the story.

[← back to README](../README.md)

**Contents:** [Why](#why) · [The plan](#the-plan-june-19) · [First test prints](#first-test-prints-june-20) · [Rebuilding in OpenSCAD](#rebuilding-in-openscad-june-21) · [Trial pieces](#trial-pieces-june-22) · [Fitting the dovetails](#fitting-the-dovetails-june-2324) · [Printing](#printing-the-pieces-late-june) · [Finishing](#finishing-dremel-and-glue-late-june) · [Living with it](#living-with-it-july-onward) · [What I learned](#what-i-learned) · [Next version](#next-version)

---

## Why

We use disposable cutlery from time to time, and it never had a good home. It comes in cardboard boxes that fall apart, or thin plastic boxes that crack into sharp pieces, and neither can be washed. Over the years I looked on Amazon and found organizers for real cutlery, but they hold too few pieces, don't lock or open too easily, and aren't made for a pile of disposable cutlery. My own fixes, a box with dividers made from plastic offcuts and tape, were flimsy and not very hygienic.

I always thought this should exist, but never had the time to design it in CAD. My son has a small 3D printer, and in June 2026 I wanted to see how fast I could design and iterate on one with plain Claude, used in ordinary chat: no text-to-CAD tools, no CAD plugins and no special workflow. At the time I didn't know text-to-CAD tools existed. It turned out to be fast, fun, and it solved the problem.

## The plan (June 19)

**The constraint that shaped everything:** the printer, my son's AOSEED X-MAKER JOY AI+, builds at most 120 × 120 × 120 mm. Disposable cutlery is about 190 mm long, and a box for three types side by side is about 300 mm wide. It can't print in one piece in either direction.

<p align="center"><img src="../photos/printer.jpg" alt="The X-MAKER JOY AI+ printer, door open, with its build plate" width="240"></p>

So the box is cut into a grid: three compartments across, two halves (A and B) along the length, six pieces in all, each small enough for the printer. Neighbouring compartments share one wall to save space, and there are no dividers inside a compartment.

Each compartment was sized for **three columns** of its cutlery type, using measurements of our cutlery plus published sizes:

| | Length | Width | Compartment (3 columns + play) |
|---|---|---|---|
| Knife | 188 mm | 19 mm | 69 mm |
| Fork | 180 mm | 29 mm | 99 mm |
| Spoon | 165 mm | 34 mm | 111 mm |

That makes the compartments different widths, narrowest for knives and widest for spoons. The interior is 196 mm long, enough for a 188 mm knife.

![First render of the six-piece layout](img/2026-06-19_first-model.png)

The first version was a Python script, written by Claude, that wrote triangle meshes directly with no CAD software. Every piece is joined to its neighbours by vertical sliding dovetails hidden inside the walls, so you build the box by lowering pieces straight down.

## First test prints (June 20)

Rather than print a whole piece, the first tests were short slices of a piece: enough height to check the corners and the joints.

<p align="center"><img src="../photos/process/IMG_8075.jpg" alt="Early test print: a short slice of one piece, with the infill visible in the cut walls" width="360"></p>

**Hollow corners.** The corners where the walls meet came out empty, even though they looked solid on screen. The script built each wall as a separate solid, overlapping at the corners, and left it to the slicer to merge them. This slicer treats a region covered twice as *outside*, so every overlap printed as a hole. The fix was walls that meet edge to edge instead of overlapping.

![Two ways to build a corner: on screen they look the same, but only one prints solid](img/hollow-corner-explained.png)

**Too narrow.** The first column widths were too tight: only two knives fit across, not three. The compartments were re-derived from the measurements in the table above. At first, two knives side by side seemed about right, with room for fingers to grab them; once the walls were full height, the narrow compartment turned out hard to grab knives from.

<p align="center"><img src="../photos/process/first-print-knives.jpg" alt="The first test print of the knife compartment, where the hollow corners showed: two knives fit side by side, a third didn't" width="360"></p>

> **Lesson:** "looks solid on screen" is not "slices solid." And measure the real objects before sizing anything.

## Rebuilding in OpenSCAD (June 21)

The Python script couldn't keep the rim's chamfer (the small bevel along the top edge) continuous where a joint crosses it, because that needs a true cut of one solid by another. So the model was rebuilt in OpenSCAD, which can do that:

1. Build the whole box as a single solid, chamfered rim included.
2. Cut it apart with dovetail-shaped blocks. The same cuts form the joints and split the box into six pieces.

![Dovetail keys on two of the pieces](img/2026-06-21_dovetail-keys.png)

**A defect every check missed.** Two pieces showed a ghost face that Tinkercad turned into a solid block halfway up the wall. All the standard mesh checks passed. The cause was a cut plane lying exactly on an existing wall face, which leaves behind a sheet of zero thickness. Moving those cut planes 0.02 mm into open space fixed it.

![The zero-thickness face before and after the fix](img/2026-06-21_zero-thickness-flap.png)
*Left: the paper-thin face, in red. Right: gone after moving the cut 0.02 mm.*

**Straight edges on top.** In the first versions the dovetail ran all the way up, so its trapezoid showed on the top of the rim. Now the male piece carries a cap the full width of the wall and the female piece has a matching recess, so the rim shows one straight seam and the joint sits underneath. The cap's underside slopes at 50° so it prints without support.

![Close-up of the same rim seam in four versions: the dovetail outline shows on top in the first, then a single straight line](img/renders/seam-top-progression.png)
*The same spot on the rim, where two pieces meet over a divider. In the Python version the dovetail's outline shows on top. From v4 the cap hides it under one straight line. In the later versions with lid features (v24 shown) the divider is also lowered, as described below.*

![Cross-section of the capped joint](img/2026-06-21_hidden-cap-section.png)

The overall shape barely changed from here to the final version; nearly all the later work was at the joints and the rim. (All renders here are plain grey, as the model looked while designing. Colour only arrived with the filament.)

![Renders of the saved versions from June 20 to June 24](img/renders/progression.png)

## Trial pieces (June 22)

Versions 5 to 23 added features for a flat clear lid, all cut into the top of the walls. No lid has been made yet (see [Living with it](#living-with-it-july-onward)), so these are designed but untested:

- **A support rail** along three inside walls for the lid to rest on, so the lid sits 2 mm below the rim. Its underside slopes at 45° so it prints without support.
- **A hinge groove** along one long wall: a half-round channel the lid's rounded edge sits in, set back behind a short slot so the rim covers it and should hold the lid when it's raised. A half circle alone wouldn't let the lid swing, so above it the groove opens up at an angle. That angle is meant to let the lid tilt up on its hinge and also lift right out, so the box can be left open on a table for people to help themselves.
- **Two light clips** on the opposite wall, with a lip of only 0.3 mm, so the lid should click shut but open easily.
- **A finger notch** between the clips, where your thumb goes to lift the lid, with the rail cut away there so a fingertip can get under the edge. Until v20 there was one clip and a small finger scallop instead.

![The hinge wall in four versions: a plain wall, then the groove with its round channel and angled opening](img/renders/hinge-wall-progression.png)
*The hinge wall, seen at the edge where the piece was cut. The Python script and v4 have a plain wall; v24 and v25 have the final groove: the round channel the lid edge sits in, and the angled opening above it.*

![The hinge groove in six versions from June 21 to 22, seen at the cut edge](img/renders/hinge-groove-progression.png)
*How the groove got there, the same wall in OpenSCAD renders. v4 has no groove. v5 cuts it in three short segments, one per compartment, stopping short of the joints, so here it barely shows. v6 makes it one round channel along the whole wall, open at the rim. v8 drops it 2 mm so the rim covers it and should hold the lid's edge when the lid is raised. v9 sets it back 2 mm behind a slot so that cover actually holds, and v10 opens it above with one straight ramp so the lid can swing up without catching.*

![The finger notch and clips in four versions from June 22](img/renders/notch-progression.png)
*The clip wall, seen from inside. v19 still has the first design: one wider clip and a small finger scallop. v20 replaces it with a notch cut through the rim between two clips, v21 arches the notch, and v22 cuts the rail away under it.*

| The finger notch and the two clips, rendered | The same notch, printed |
|---|---|
| ![Render of the finger notch with a clip on each side and the rail below](img/renders/notch-and-clips_v25.png) | ![The finger notch in the printed clip wall](../photos/process/IMG_8119.jpg) |

Then came the first trial pieces, with four problems. The annotations are from that day.

| Problem | Cause | Fix |
|---|---|---|
| Base corners splaying outward | Elephant's foot: the first layers squash out | Slicer settings: 0.15–0.20 mm elephant's-foot compensation, slightly less plastic on the first layer, cooler bed after it |
| Dovetail socket flimsy, and visible from outside | Only 0.5 mm of wall each side of the socket, about one line of extruded plastic | Smaller dovetail and tighter clearance: 1.0 mm of wall each side |
| Support material stuck under the base joints | The flat overlapping base joint left a floating lip that needed support inside a pocket | All base joints changed to 45° wedges, which need no support |
| Thin tab dangling where two seams cross | Two overlapping joints at the same corner | A solid full-height corner on one of the two pieces |

| Elephant's foot | Socket visible from outside |
|---|---|
| ![Elephant's foot at a base corner, circled](img/2026-06-22_trial-elephants-foot.jpg) | ![Dovetail seam visible on the outside wall](img/2026-06-22_trial-dovetail-seam.jpg) |
| **Support stuck in a base joint** | **Dangling tab at a seam corner** |
| ![Support residue along a base joint, circled](img/2026-06-22_trial-lap-support.jpg) | ![Thin tab at the corner where two seams cross, circled](img/2026-06-22_trial-corner-tab.jpg) |

**Warping.** Some pieces also lifted at the corners while printing, so the bottom edge no longer lies flat:

<p align="center"><img src="../photos/process/IMG_8082.jpg" alt="A test piece held edge-on: its bottom edge curls up at the corner instead of lying flat" width="360"></p>

## Fitting the dovetails (June 23–24)

This took the most rounds. The first joints slid in but wobbled and pulled back out. Making them tighter fixed one print and jammed the next: sometimes there was good friction and sometimes none, from prints that should have been identical.

<p align="center"><img src="../photos/process/IMG_8087.jpg" alt="A test joint between two short pieces" width="360"></p>

The approach that worked was to stop changing both sides at once. The female socket, once it printed well, was frozen. The male side (the tongue) was tested on its own against the female side (the socket), with four coupons (small test pieces) at 0.20, 0.15, 0.10 and 0.05 mm clearance per side, each marked with one to four dots so they could be told apart off the bed.

| The four coupons | Testing one in a printed socket |
|---|---|
| ![Four coupons marked with one to four dots](../photos/process/IMG_8089.jpg) | ![A coupon being slid into the socket of a printed piece](../photos/process/IMG_8090.jpg) |

Then two full-height tongues with the real top cap checked the fit over the whole 55 mm:

<p align="center"><img src="../photos/process/IMG_8099.jpg" alt="Two full-height test tongues" width="360"></p>

The final model (v25, June 24) uses 0.15 mm per side. Coupon files: [`stl/test-coupons/`](../stl/test-coupons/). Generators: [`tools/`](../tools/).

The same round of prints showed that every flat base joint still trapped support material, so v25 also turned all of them into 45° wedges:

![The base joint in four versions: none, a flat shelf, then a 45-degree wedge](img/renders/base-joint-progression.png)
*Two pieces pulled apart at the base. The Python version had no overlap at the base; v4 and v24 had a flat shelf that needed support under it; v25 has a 45° wedge that prints on its own.*

![The final model's six pieces, pulled apart](img/renders/2026-06-24_v25-six-pieces.png)

> **Lesson:** the printer's precision, and its repeatability from one print to the next, is a design input. A fit that works on one print may not on the next, even at identical settings. Test on cheap coupons, change one side of a joint at a time, and plan for some hand fitting.

## Printing the pieces (late June)

I think all six pieces were printed from the final model, v25. They were printed in iSANMATE PLA+ Rainbow, a colour-change filament (1.75 mm); the gradients on the box come from the filament, not from the design. I used the printer's fine setting, 0.12 mm layers, so the rim chamfer would come out more accurately. I think I used the default wall thickness, 2 layers, and 15% infill (maybe 3 and 20%; I don't remember). From memory, each piece took about 6–8 hours, depending on its size.

The printer is made for kids getting into 3D printing, and the prints weren't perfectly precise or repeatable: the fit varied between prints at the same settings (above), and some surfaces came out rough.

<p align="center"><img src="../photos/process/IMG_8117.jpg" alt="Rough patches left by printing on an inside wall, next to a joint socket" width="360"></p>

Still, with a little Dremel work and glue, it made a box we use regularly and that holds up. We like how it looks, and visitors sometimes ask where we got it.

## Finishing: Dremel and glue (late June)

With all six pieces printed, they still didn't sit flush. High spots on the mating faces bumped into each other and kept the pieces from seating. A Dremel took those down.

Even seated, the friction fit wasn't enough for a box that gets picked up and moved. Plastic glue on the joints made it one rigid unit that doesn't wobble at rest.

![Two trial pieces side by side](../photos/process/IMG_8103.jpg)

![The assembled box, empty](../photos/finished-empty.jpg)

## Living with it (July onward)

**A knife that didn't fit.** Our usual brand fits well within the 196 mm interior. But one particularly long knife from another brand touched both ends. The sizing came from our own measurements plus published sizes, and the outlier wasn't covered.

<p align="center"><img src="../photos/knife-too-long.jpg" alt="A longer knife touching both ends of a compartment" width="360"></p>

**Columns didn't work in practice.** The box was designed for three columns per compartment, each a stack of cutlery lying face up: knives in the narrowest compartment, forks in the middle, spoons in the widest. The stacks were unstable even with the box standing still, and they fell over as soon as it was moved. I could only keep knives stacked using new ones, placed with great care; otherwise they kept falling. I did count 48 knives in the columns, but filling them was a pain.

I had checked on every newly printed part that three pieces fit side by side, but I never tried stacking them until the whole box was built. As soon as I had the two knife pieces, I could have tried the stacks I was planning for and seen quickly that they didn't work. Maybe that would have sent me back to the design: for example, printing dividers between the columns. But then I might never have found the packing that holds far more. It's hard to say.

**Packing it like the packaging.** The packaging gave me the idea: it lays the pieces on edge, nested tightly together, and that turned out to be very space-efficient. Once I saw how much more fit that way, I stopped aiming for the same amount of each type and split the space by how much we use each:

- **Forks**, which we use most, went into the widest compartment, on edge in two rows.
- **Spoons**, which we use least, went into the narrowest, also on edge in two rows. They're still easy to grab there.
- **Knives** went into the middle, loosely packed: roughly parallel, but not in neat stacks. They were hard to stand on edge by hand. But a knife is just a long shaft without the big head of a fork or a spoon, so they don't tangle and are still easy to pick up, and a lot of them fit. In the narrowest compartment, though, getting a hand in to grab a knife was awkward.

| As designed: three face-up columns (the knife stacks kept falling, so only one layer is shown) | Now: on edge, split by use |
|---|---|
| ![The box as designed: knives in the narrowest compartment, forks in the middle and spoons in the widest, in face-up stacks](../photos/designed-layout.jpg) | ![The box with forks and spoons on edge in two rows and knives loosely packed](../photos/final-layout.jpg) |

| | Columns (as designed) | On edge, split by use | Change |
|---|---|---|---|
| Spoons | 36 (widest) | 48 (narrowest) | +33% |
| Forks | 36 (middle) | 56 (widest) | +56% |
| Knives | 48 (narrowest) | 80 (middle) | +67% |
| **Total** | **120** | **184** | **+53%** |

Each type also changed compartment, so the per-type change mixes the new packing with the new compartment size. The total is the fairer comparison.

The new layout has trade-offs. Three neat columns look nicer, so it's function over looks. It may also be less hygienic. To pack in less height, the two rows face opposite ways: the spoons, for example, lie with their heads down in one row and up in the other. So fingers reaching for the top row can touch the heads in the bottom row. We don't mind much, since most of the people who use it are family.

This split suits how we use it; other layouts are worth trying. Knives could also go in the narrowest compartment and spoons in the middle, where far more spoons would fit. I didn't, because reaching into the narrowest compartment for knives lying almost flat was awkward. And whichever type you use most, forks or knives, can have the widest compartment.

**A second one.** My brother had been looking for the same thing, so I printed one for him too.

**No lid, so far.** The rim has everything a clear 2 mm lid needs, but the food-safe sheets I found were expensive or not good enough, and we haven't missed a lid. If you know a good source, please [open an issue](../README.md#feedback).

## What I learned

- **The screen lies in specific ways.** Hollow corners, ghost faces and visible seams all looked fine on screen. A short slice of a piece is the cheapest test there is.
- **Printer variance is part of the design.** Clearances that worked on one print failed on the next. Coupons narrow the range; a Dremel and glue close the gap.
- **Change one variable at a time.** Freezing the socket and testing only the male side is what finally made progress on the joint.
- **Measure the full range, not one sample.** One long knife from another brand was enough to miss.
- **Use reveals what planning can't, so test the use early.** The layout that works (on edge, like the packaging), the capacity, and which compartment should hold which type only became clear once the box was on the counter.
- **Plain Claude got a working design,** with a lot of human rendering, printing and judging in the loop. It couldn't run OpenSCAD or touch the prints: I rendered, printed and photographed, and it worked from my screenshots and its own diagrams.

## Next version

- **Try text-to-CAD and other CAD tools for language models,** and compare against this plain-chat baseline: how many rounds, how many test prints, and how good the result is.
- **Design for packing on edge from the start:** size the compartments for nested cutlery and for how often each type is used, and check how easy each is to grab.
- **Measure several brands,** including the longest knife likely to end up in the box.
- **Design the joints for glue,** or for a looser fit that tolerates print-to-print variation, rather than relying on a precise friction fit.
- **A lid:** find an affordable food-safe sheet, or design a printable one.

---

Raw notes, all 25 model versions and every design screenshot are in [`../archive/`](../archive/).
