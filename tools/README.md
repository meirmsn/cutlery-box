# Tools

The coupon generators are plain Python 3 with no dependencies; each writes a binary STL to the current directory, and the outputs are already in [`../stl/test-coupons/`](../stl/test-coupons/).

| Script | Output | What it's for |
|---|---|---|
| `make_dovetail_rig.py` | `dovetail_fit_test_rig.stl` | Four 20 mm male dovetail coupons at 0.20 / 0.15 / 0.10 / 0.05 mm clearance per side, marked with 1–4 dots. Slide each into a printed female socket and keep the tightest one that still slides by hand. |
| `make_male_test.py` | `dovetail_male_test.stl` | Two full-height (55 mm) male tongues with the real top cap, at 0.15 mm per side: one at the standard depth (1 dot) and one 1 mm deeper (2 dots). |
| `render_stl.py` | PNG | The flat-shaded renderer used for the images in `docs/img/renders/`. Needs numpy, matplotlib and Pillow; see the examples at the top of the file. |

The two coupon generators are sized against the final female socket in `scad/cutlery_box.scad` (half-widths 1.5 mm at the neck and 2.0 mm at the flare). If you change the dovetail parameters there, change them here too.

```bash
cd stl/test-coupons
python3 ../../tools/make_dovetail_rig.py
python3 ../../tools/make_male_test.py
```
