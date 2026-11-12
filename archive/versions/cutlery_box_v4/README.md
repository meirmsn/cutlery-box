# cutlery_box v4 — print-ready, NO LID

The body-only release (six pieces, no lid features). `cutlery_box_PRINT_READY_no_lid.scad`
is a byte-identical copy of `cutlery_box_v4.scad`.

Export the STLs (run from the project root):

```bash
for p in knife_A knife_B fork_A fork_B spoon_A spoon_B; do openscad -o "previous-versions/cutlery_box_v4/body_$p.stl" -D "part=\"$p\"" previous-versions/cutlery_box_v4/cutlery_box_v4.scad; done
```
