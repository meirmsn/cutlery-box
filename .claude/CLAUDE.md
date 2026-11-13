# Cutlery Box: context for Claude sessions

This repo is the **single source of truth** for the project. It replaced a local project folder on the owner's computer, which he has deleted. Everything from that folder is here: the final model and STLs at the top level, everything else byte-identical under `archive/` (images re-saved only to strip metadata). The original design conversations with Claude (June 2026, claude.ai chats) are not exportable; their reasoning is captured in `archive/notes/CONSTRUCTION_STORY.md` and `archive/notes/TRIAL_PRINT_FIX_PLAN.md`.

Owner: Meir Messingher Lang (@meirmsn). Robot hands: @meirmsn-agent.

**At the start of every session, before anything else, give the owner a short summary of the [Open items](#open-items) below** (one line each), so pending work and unanswered questions surface even if he doesn't ask. When an item is done or answered, update this file in the same PR: remove the item, and move any new fact into the docs or the facts section below.

## What this is

A three-compartment box for disposable knives, forks and spoons. It was designed in OpenSCAD with plain Claude in chat (no text-to-CAD tools) in June 2026, printed in six pieces on the owner's son's AOSEED X-MAKER JOY AI+ (120 mm cube build area; `photos/printer.jpg`), finished with a Dremel and plastic glue, and in daily use since July 2026. The public docs are `README.md` (one screen) and `docs/BUILD_LOG.md` (the full story).

## Layout

| Path | What |
|---|---|
| `scad/cutlery_box.scad` | Final model, v25. Byte-identical to `archive/versions/cutlery_box_v25/`. `part` selects knife_A/B, fork_A/B, spoon_A/B or assembly. |
| `stl/` | The six exported pieces (the owner's own F6 exports of v25), plus `test-coupons/`. |
| `tools/` | Coupon generators, `render_stl.py` (grey z-buffer renderer, no OpenSCAD needed), `render_versions.sh` (OpenSCAD renders of all versions). |
| `photos/` | Finished-box photos; `process/` holds test-print photos taken on 2026-08-31 of leftover prints. Resized to 1600 px, all metadata (including GPS) stripped. |
| `docs/img/` | Images used by the docs; `renders/` was made with `tools/render_stl.py`. The social preview is `docs/social-preview.png` (1280×640, made with `tools/make_social_preview.py`). |
| `archive/` | Every version v1–v25, notes, the original Python generator, design diagrams and feedback screenshots. See `archive/README.md`. |

## Working rules (from the owner)

- **Packaging only:** no changes to the model or product behaviour unless he asks.
- **README structure is fixed:** title; status line (`Shipped · in daily use · last touched YYYY-MM`); one sentence; short paragraph; photo; Approach; What it does (3–6 visitor outcomes, no jargon); How it works (3–6 bullets, including tried-and-dropped); Build log (dated bullets plus a preview linking to `docs/BUILD_LOG.md`); Known limitations (visitor-facing only); Run it; Feedback ("Suggestions and critiques welcome — open an issue or a discussion."); License (CC BY 4.0). It mirrors his other repos, e.g. github.com/meirmsn/song-bass-explainer.
- **Build log style:** plain, learning-oriented, in order (motivation and plan, then doing, iteration, done, insights, next version).
- **Never estimate a number.** Ask him. Use his phrasing, lightly polished, when he provides text.
- **Review before every PR:** an adversarial pass that cuts anything a skeptic would call fluff, wrong or self-flattering. Best done by a separate agent that checks claims against `archive/notes/`, the scad parameters and the photos.
- **Process:** keep each change on one PR branch. End each round with one short list of things only he can do, and no TODOs buried in the docs.
- **Commits:** author `meirmsn-agent <340873665+meirmsn-agent@users.noreply.github.com>`, with the trailer `Co-authored-by: Meir Messingher Lang <meirmsn@users.noreply.github.com>`.
- **Images:** strip all metadata before committing (the owner's phone photos carry GPS), and crop out any fingertip shown sharply enough to copy a fingerprint from (blurred or side-on fingers are fine). IMG_8093–8096 (coupons held between sharp fingertips) were left out for that reason, and IMG_8079, 8082, 8083, 8090, 8091 and 8106 were cropped.
- **Renders:** neutral grey (`#c9ccd1` on white), as the model looked while designing. Colour appears only in photos. The piece colours were never a design decision, and the prints use gradient filament. The one exception, at his request: the social preview's render is in the print colours (`render_stl.py --colors`). The two OpenSCAD strips (`hinge-groove-progression.png`, `notch-progression.png`) are greyscale conversions of his renders, so they are darker than the `render_stl.py` ones.
- **Dates:** design dates come from file timestamps in US Pacific time. The notes in `archive/notes/` are dated in UTC, so some read a day later.

## Facts from the owner that are not in the archive notes

- **Why:** disposable cutlery comes in cardboard boxes that fall apart or plastic ones that crack into sharp pieces, and none can be washed. Organizers for real cutlery hold too few pieces and don't lock. His taped DIY dividers were flimsy and unhygienic. He never had time to design it in CAD; with Claude it was fast and fun. His brother had been looking for one too, so he printed a second.
- **Sizing:** measured cutlery plus published sizes. A particularly long knife from another brand doesn't fit (it touches both ends); their usual brand fits.
- **In use:** the designed layout, three face-up columns per compartment (knives narrowest, forks middle, spoons widest), held 36 spoons, 36 forks, 48 knives (120) and wobbled when the box was moved. An intermediate step swapped spoons and knives, still face up (`photos/finished-loaded.jpg`). The final layout (`photos/final-layout.jpg`), inspired by the packaging: forks (most used) on edge in two rows in the widest, 56; spoons (least used) on edge in two rows in the narrowest, 48; knives "loosely packed" in the middle, 80 (184 total, +53%). Knives are hard to stand on edge by hand but don't tangle and are easy to grab; reaching into the narrowest compartment for them was awkward.
- **Printing:** fine setting, 0.12 mm layers, for a more accurate chamfer. Filament: iSANMATE PLA+ Rainbow colour-change, 1.75 mm. About 6–8 h per piece, from memory. The printer is a kids' entry printer; describe its imprecision as observations, not as a fault, alongside the fact that the box came out reliable and good-looking (visitors ask where it's from).
- **Lid:** never made. Food-safe sheets he found were too expensive or not good enough, and he hasn't needed one. He wants suggestions: affordable, food-safe, good surface finish, about 196.5 × 290 × 2 mm, rounded edges. The hinge was designed as a half-round channel plus an angled opening, so the lid can swing up and also lift out (for serving).
- **Finishing:** a Dremel removed high spots that kept pieces from seating; plastic glue makes the box rigid and stops it wobbling at rest.
- **Next version:** try text-to-CAD tools and compare against this plain-Claude baseline (he didn't know they existed in June 2026).

## Repo setup (done 2026-11)

Public on GitHub with description and topics set. Release [`v1.0`](https://github.com/meirmsn/cutlery-box/releases/tag/v1.0) carries `cutlery-box-stl-v1.0.zip` (`stl/*.stl` plus `stl/test-coupons/*.stl`) and `cutlery-box-photos-v1.0.zip` (`photos/**/*.jpg`). The old local folder is deleted, so no "moved to" pointer is needed there or in claude.ai.

## Open items

Things only the owner can provide:
- **Designed-layout photo:** the owner is taking one (knives narrowest, forks middle, spoons widest, face up). It replaces `photos/finished-loaded.jpg` on the left of the capacity comparison in `docs/BUILD_LOG.md`; strip metadata, 1600 px.
- **Social-preview photo (optional):** the draft uses `photos/finished-empty.jpg`, already close to the render's angle. A new photo can replace it; rerun `tools/make_social_preview.py`.
- **Brother's box:** a photo, if he gets one.
- **Optional:** a Printables or MakerWorld listing to link from the README.
- **Never answered:** nozzle; wall count and infill (he thinks default 2 walls and 15%, maybe 3 and 20%); exact print times and filament used (he can look them up); which full-height test tongue won (1 dot = standard, 2 dots = 1 mm deeper); whether the box in use is exactly v25. Leave these out of the docs unless he answers.

Repo admin:
- **Social preview:** upload `docs/social-preview.png` in the GitHub settings (Settings → General → Social preview).

Settled; no action needed:
- Lid-version renders: the owner's OpenSCAD renders of v1–v25 showed only the plain shell for v1–v17 in the box, seam and notch views (`assembly()` rendered `box()` until v18), and the seam view was unreadable. Only the hinge view (v4–v10) and the notch view (v19–v22) were usable; they are `docs/img/renders/hinge-groove-progression.png` and `notch-progression.png`, converted to grey. The raw renders were not committed. v20 replaced an earlier single clip and finger scallop (present since v5); v23 changed no geometry.
- The "Option B" dovetail in `archive/notes/TRIAL_PRINT_FIX_PLAN.md` (thicker socket walls, thinner tongue) was never needed: v25 solved the fit by tightening the tongue to 0.15 mm per side.

Known minor mesh nits in `stl/`, left alone because the box printed fine:
- a few zero-area triangles
- one tiny open edge on `spoon_B` (the 0.01 mm sliver noted in `archive/notes/v24_stable_NOTES.md`)
- `knife_B` reports Euler characteristic 0

## Environment notes for cloud sessions

- OpenSCAD isn't installable in the cloud sandbox: apt and PyPI are blocked, and an unofficial WebAssembly build was refused as third-party code. Use `tools/render_stl.py` on the STLs, or have the owner run OpenSCAD locally.
- `git clone` of public GitHub repos works through the proxy; most other hosts don't.
- **render_stl.py camera presets** used for `docs/img/renders/`. Every command is `python3 -I tools/render_stl.py OUT.png FILES ARGS`; the A/B suffix pieces are body_*_A.stl and body_*_B.stl:

| View | Files | Args |
|---|---|---|
| Rim seam | fork A/B + spoon A/B | `--center 104 183 54 --width 44 --elev 40 --azim -55` |
| Base joint | knife A/B | `--offsetB 10 --center 109 30 2 --width 34 --elev 8 --azim -70` |
| Hinge wall | knife_A only | `--center 8 81 55 --width 24 --elev 15 --azim 70` |
| Notch and clips | assembled box | `--center 205 151.5 52 --width 50 --elev 30 --azim 200` |

  The Python-generator geometry comes from running `archive/scripts/build_box.py` in a scratch copy (it writes STLs next to itself) and passing `--offsetB 104`.
