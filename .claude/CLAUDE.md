# Cutlery Box: context for Claude sessions

This repo is the **single source of truth** for the project. It replaced a local project folder on the owner's computer, which is deprecated. Everything from that folder is here: the final model and STLs at the top level, everything else byte-identical under `archive/` (images re-saved only to strip metadata). The original design conversations with Claude (June 2026, claude.ai chats) are not exportable; their reasoning is captured in `archive/notes/CONSTRUCTION_STORY.md` and `archive/notes/TRIAL_PRINT_FIX_PLAN.md`.

Owner: Meir Messingher Lang (@meirmsn). Robot hands: @meirmsn-agent.

## What this is

A three-compartment box for disposable knives, forks and spoons. It was designed in OpenSCAD with plain Claude in chat (no text-to-CAD tools) in June 2026, printed in six pieces on the owner's son's AOSEED printer (120 mm cube build area), finished with a Dremel and plastic glue, and in daily use since July 2026. The public docs are `README.md` (one screen) and `docs/BUILD_LOG.md` (the full story).

## Layout

| Path | What |
|---|---|
| `scad/cutlery_box.scad` | Final model, v25. Byte-identical to `archive/versions/cutlery_box_v25/`. `part` selects knife_A/B, fork_A/B, spoon_A/B or assembly. |
| `stl/` | The six exported pieces (the owner's own F6 exports of v25), plus `test-coupons/`. |
| `tools/` | Coupon generators, `render_stl.py` (grey z-buffer renderer, no OpenSCAD needed), `render_versions.sh` (OpenSCAD renders of all versions). |
| `photos/` | Finished-box photos; `process/` holds test-print photos taken on 2026-08-31 of leftover prints. Resized to 1600 px, all metadata (including GPS) stripped. |
| `docs/img/` | Images used by the docs; `renders/` was made with `tools/render_stl.py`. `social-preview.png` (1280×640) is for GitHub settings. |
| `archive/` | Every version v1–v25, notes, the original Python generator, design diagrams and feedback screenshots. See `archive/README.md`. |

## Working rules (from the owner)

- **Packaging only:** no changes to the model or product behaviour unless he asks.
- **README structure is fixed:** title; status line (`Shipped · in daily use · last touched YYYY-MM`); one sentence; short paragraph; photo; Approach; What it does (3–6 visitor outcomes, no jargon); How it works (3–6 bullets, including tried-and-dropped); Build log (dated bullets plus a preview linking to `docs/BUILD_LOG.md`); Known limitations (visitor-facing only); Run it; Feedback ("Suggestions and critiques welcome — open an issue or a discussion."); License (CC BY 4.0). It mirrors his other repos, e.g. github.com/meirmsn/song-bass-explainer.
- **Build log style:** plain, learning-oriented, in order (motivation and plan, then doing, iteration, done, insights, next version).
- **Never estimate a number.** Ask him. Use his phrasing, lightly polished, when he provides text.
- **Review before every PR:** an adversarial pass that cuts anything a skeptic would call fluff, wrong or self-flattering. Best done by a separate agent that checks claims against `archive/notes/`, the scad parameters and the photos.
- **Process:** keep each change on one PR branch. End each round with one short list of things only he can do, and no TODOs buried in the docs.
- **Commits:** author `meirmsn-agent <340873665+meirmsn-agent@users.noreply.github.com>`, with the trailer `Co-authored-by: Meir Messingher Lang <meirmsn@users.noreply.github.com>`.
- **Images:** strip all metadata before committing. The owner's phone photos carry GPS.
- **Renders:** neutral grey (`#c9ccd1` on white), as the model looked while designing. Colour appears only in photos. The piece colours were never a design decision, and the prints use gradient filament.
- **Dates:** design dates come from file timestamps in US Pacific time. The notes in `archive/notes/` are dated in UTC, so some read a day later.

## Facts from the owner that are not in the archive notes

- **Why:** disposable cutlery comes in cardboard boxes that fall apart or plastic ones that crack into sharp pieces, and none can be washed. Organizers for real cutlery hold too few pieces and don't lock. His taped DIY dividers were flimsy and unhygienic. He never had time to design it in CAD; with Claude it was fast and fun. His brother had been looking for one too, so he printed a second.
- **Sizing:** measured cutlery plus published sizes. A particularly long knife from another brand doesn't fit (it touches both ends); their usual brand fits.
- **In use:** three columns per compartment wobbled when the box was moved. Nesting the cutlery flat in stacks, like the packaging, raised capacity (not yet counted) and stability. Spoons (least used) moved to the narrowest compartment, forks to the middle, knives to the widest. He's considering forks (most used) in the widest, depending on how easy each type is to grab.
- **Lid:** never made. Food-safe sheets he found were too expensive or not good enough, and he hasn't needed one. He wants suggestions: affordable, food-safe, good surface finish, about 196.5 × 290 × 2 mm, rounded edges. The hinge was designed as a half-round channel plus an angled opening, so the lid can swing up and also lift out (for serving).
- **Finishing:** a Dremel removed high spots that kept pieces from seating; plastic glue makes the box rigid and stops it wobbling at rest.
- **Next version:** try text-to-CAD tools and compare against this plain-Claude baseline (he didn't know they existed in June 2026).

## Open items

Things only the owner can provide:
- **Capacity:** count, nested stacks vs. the three-column layout, then add the figure to the README and build log ("held more (I haven't counted how much yet)").
- **Lid-version renders (v5–v23):** run `bash tools/render_versions.sh` on a machine with OpenSCAD and choose renders for the lid section of the build log.
- **Brother's box:** a photo, if he gets one.
- **Optional:** a Printables or MakerWorld listing to link from the README.
- **Never answered:** layer height, nozzle, filament material and brand, print time and filament used; the exact AOSEED model; which full-height test tongue won (1 dot = standard, 2 dots = 1 mm deeper); whether the box in use is exactly v25. Leave these out of the docs unless he answers.
- **Caption to confirm:** `photos/process/IMG_8117.jpg` is captioned as showing Dremel marks.

Repo admin:
- **Release `v1.0`:** attach the six STLs, `cutlery-box-stl-v1.0.zip` (`stl/*.stl` plus `stl/test-coupons/*.stl`) and `cutlery-box-photos-v1.0.zip` (`photos/**/*.jpg`).
- **GitHub settings:** set the description and topics (openscad, 3d-printing, 3d-printable, dovetail, kitchen, organizer, claude). The owner uploads the social preview and flips the repo public.

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
