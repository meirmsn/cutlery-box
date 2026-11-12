# Archive

Raw working material from the design process, kept so nothing is lost. None of it is needed to print or change the box; for that, see the [README](../README.md). The notes were written during the work and haven't been edited since, so some refer to old file paths (`openscad/…`) and some describe intermediate states that were later changed.

| Folder | What's in it |
|---|---|
| [`versions/`](versions/) | Every saved OpenSCAD version, `cutlery_box_v1.scad` to `v25` (the first, Python-generated model is `scripts/build_box.py`). v4 (body only, no lid features), v24 and v25 include their exported STL sets. v25 is identical to [`../scad/cutlery_box.scad`](../scad/cutlery_box.scad). |
| [`notes/`](notes/) | `CONSTRUCTION_STORY.md` (the running design log), `TRIAL_PRINT_FIX_PLAN.md` (diagnosis of the trial prints), `v24_stable_NOTES.md`, `dremel-guide.md` (finishing reference), and `WORKING_README.md` (the project README as it stood during the work). |
| [`scripts/`](scripts/) | `build_box.py`, the original Python mesh generator that the OpenSCAD model replaced, plus two one-off render and check scripts. |
| [`diagrams/`](diagrams/) | Renders and cross-sections made while designing. `OLD/` holds the ones from the Python-generator era. |
| [`screenshots/`](screenshots/) | Annotated screenshots and trial-print photos used as feedback during the design, named by date and time (US Pacific). |

The dated summary is in [`../docs/BUILD_LOG.md`](../docs/BUILD_LOG.md).
