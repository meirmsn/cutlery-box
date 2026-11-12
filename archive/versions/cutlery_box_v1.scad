// ============================================================================
// cutlery_box.scad
// Graduated 3-chamber disposable-cutlery box (Option 3) — CUT-FROM-SOLID port
// of build_box.py, for a 120 x 120 x 120 mm printer (AOSEED).
//
// WHY THIS PORT EXISTS (the whole point):
//   The hand-mesh generator (build_box.py) could not keep the 1 mm rim chamfer
//   continuous across the female dovetail joints, because where a slot's flared
//   corner crosses the sloped chamfer it needs a true boolean intersection.
//   OpenSCAD HAS that boolean kernel, so here we do exactly the "cut-from-solid"
//   thing:
//      1. Build the ENTIRE box as ONE solid, WITH the chamfer already on it.
//      2. difference() out vertical dovetail prisms ( /_\ cross-section ),
//         running from just above the base plate up THROUGH the rim, to both
//         (a) form the sliding-dovetail joints, and
//         (b) split the box into 6 bed-sized pieces.
//   Because the cut is a real boolean through the already-chamfered solid, the
//   sloped chamfer<->slot edge is produced for free => the rim chamfer stays
//   CONTINUOUS across every joint, with none of the sliver hacks.
//
// ----------------------------------------------------------------------------
// HOW TO USE
//   In the app:  set `part` below (or use the Customizer dropdown), F5 to
//                preview, F6 to render, then File > Export > STL.
//   One piece (CLI):
//      openscad -o body_knife_A.stl -D 'part="knife_A"' cutlery_box.scad
//   ALL SIX (bash, run from this folder):
//      for p in knife_A knife_B fork_A fork_B spoon_A spoon_B; do \
//        openscad -o "body_$p.stl" -D "part=\"$p\"" cutlery_box.scad ; done
//   PNG preview of one piece:
//      openscad -o knife_B.png --imgsize=1400,1000 --autocenter --viewall \
//        -D 'part="knife_B"' cutlery_box.scad
//
//   Pieces are modelled in ASSEMBLED coordinates (floor-down, z=0 is the bed),
//   so importing all six STLs together shows the assembled box directly; your
//   slicer will auto-drop each one onto the plate for printing.
//
// BED SANITY: every piece is <= 120 mm in X, Y, Z.
//   Z = 58 mm. Widest piece = spoon at 117 mm (Y). A-halves reach 109 mm (X,
//   including the protruding dovetail key). All under 120.
//
// !! I could NOT run OpenSCAD to verify this file (no binary in my sandbox) !!
//   - The rim chamfer is a SMOOTH, true-45 bevel built from hull() frustums of
//     convex rectangles. Works in every OpenSCAD since ~2015 (incl. Homebrew
//     2021.01). No stepped staircase -- and, crucially, it makes box() a clean
//     well-formed solid so the per-part booleans resolve reliably (the old
//     14-slice staircase was fragile and CGAL was dropping the walls of the
//     interior parts, leaving only the key prisms => "floating boxes").
//   - roof() is still available behind USE_ROOF=true for those who have it
//     (2021.01+ snapshots); for THIS rectangular design it is identical, so it
//     is NOT required.
//   - After F6, check the console for "WARNING"/"not a valid 2-manifold".
//     If a tenon ever looks detached, bump EPS to 0.05.
// ============================================================================


/* [Part to render / export] */
part = "knife_A"; // [knife_A, knife_B, fork_A, fork_B, spoon_A, spoon_B, assembly]

/* [Chamfer method] */
// false = smooth hull() frustum bevel (default, any OpenSCAD); true = roof() (2021.01+)
USE_ROOF = false;

/* [Heights (mm)] */
BASE   = 3.0;     // floor / base-plate thickness
COMP_H = 55.0;    // interior wall height above the floor (cutlery stack depth)

/* [Walls (mm)] */
HOST_T   = 6.0;     // thickness of every wall (thick enough to host a dovetail)
HALF_LEN = 104.0;   // printed length of each half (A = near, B = far); <120 incl. key

/* [Chamber bays (mm)] */
N_COL     = 3;       // columns of cutlery per chamber
KNIFE_COL = 23.0;    // -> knife bay 69  (3 x 19 mm knives + play)
FORK_COL  = 33.0;    // -> fork  bay 99  (3 x 29 mm forks  + play)
SPOON_COL = 37.0;    // -> spoon bay 111 (3 x 34 mm spoons + play, trimmed <120)

/* [Dovetail joint (mm)] */
DT_DEPTH = 5.0;   // tail protrusion past the seam (male key depth)
DT_NECK  = 1.2;   // half-width at the seam face (narrow)
DT_FLARE = 2.1;   // half-width at the tip (wide -> locks)
DT_CLR   = 0.4;   // FLANK/seam slide clearance added to the female socket (do not change for fit)
DT_DEPTH_RELIEF = 0.3; // extra depth on the socket BACK only, so the tail tip never bottoms out

/* [Rim chamfer (mm)] */
CHAMFER = 1.0;    // 45-deg comfort break broken along the top wall edges

/* [Base half-lap / anti-warp (mm)] */
// Neighbouring base plates overlap as a HORIZONTAL half-lap (shiplap) at mid-base
// height, so corners stay coplanar (no lift/protrusion). Horizontal lap faces do
// NOT bind the vertical-drop assembly. Shingle direction: A->B and knife->fork->spoon.
LAP_LEN = 6;        // overlap past the A/B seam and the knife/fork seam
LAP_LEN_FS = 2;     // overlap past the fork/SPOON seam -- SMALLER: spoon is the
                    // tightest piece (117mm of the 120mm bed); a 6mm lap there
                    // would push spoon to 123mm. 2mm keeps spoon at 119mm.
LAP_Z   = BASE/2;   // 1.5 -- horizontal split height of the lap (bottom vs top half)
LAP_CLR = 0.2;      // in-plane clearance so the shelf isn't a press fit


/* [Hidden] */
EPS      = 0.01;          // tiny overlap so abutting solids fuse cleanly in CGAL
// Upper-chamber pieces (fork, spoon) were cut by a cell plane laid EXACTLY on the
// divider wall's far face (the lower chamber owns that wall). intersection() along a
// plane coincident with an existing box face makes CGAL leave a ZERO-THICKNESS copy
// of the wall face -> edge-manifold + "watertight" but degenerate (OpenSCAD shows it
// as a blue back-face; Tinkercad thickens it into a phantom block). SEAM_EPS nudges
// those cut planes a hair INTO the open bay so they no longer coincide with any box
// face -> no flap. 0.02 mm is physically nothing but is well clear of CGAL's tolerance.
SEAM_EPS = 0.02;
CUT_OVER = 1.0;           // how far dovetail cutters overshoot the rim (clean cut)

BODY_H    = BASE + COMP_H;     // 58  total height
END_WALL  = HOST_T;            // end walls are dovetail hosts too -> equally thick
TOTAL_LEN = 2 * HALF_LEN;      // 208 assembled length (end wall .. end wall)

// bay widths
KNIFE_BAY = N_COL * KNIFE_COL; // 69
FORK_BAY  = N_COL * FORK_COL;  // 99
SPOON_BAY = N_COL * SPOON_COL; // 111

// ---- Y layout (width direction): wall | bay | divider | bay | divider | bay | wall
KNIFE_Y0 = 0;
KNIFE_Y1 = HOST_T + KNIFE_BAY + HOST_T;        // 0..81   (outer wall + bay + divider)
FORK_Y0  = KNIFE_Y1;                           // 81
FORK_Y1  = FORK_Y0 + FORK_BAY + HOST_T;        // 81..186 (bay + divider)
SPOON_Y0 = FORK_Y1;                            // 186
SPOON_Y1 = SPOON_Y0 + SPOON_BAY + HOST_T;      // 186..303(bay + outer wall)
EXT_W    = SPOON_Y1;                           // 303 total width

// lengthwise wall Y-bands [y0,y1] (host the A/B dovetails) + their centers
OUTER_L  = [0, HOST_T];                                       // [0,6]    c=3
DIV_KF   = [HOST_T + KNIFE_BAY, HOST_T + KNIFE_BAY + HOST_T]; // [75,81]  c=78
DIV_FS   = [FORK_Y0 + FORK_BAY, FORK_Y0 + FORK_BAY + HOST_T]; // [180,186]c=183
OUTER_R  = [SPOON_Y1 - HOST_T, SPOON_Y1];                     // [297,303]c=300

// the three OPEN bays are rectangular holes in the wall footprint:
//   footprint = outer rectangle MINUS these bays  (== the 6 walls; verified).
// The smooth chamfer is built from exactly this decomposition.
BAY_X0 = END_WALL;              // 6
BAY_X1 = TOTAL_LEN - END_WALL;  // 202
BAYS = [
    [BAY_X0, BAY_X1, HOST_T,   HOST_T + KNIFE_BAY],   // knife bay [6,202] x [6,75]
    [BAY_X0, BAY_X1, FORK_Y0,  FORK_Y0 + FORK_BAY],   // fork  bay [6,202] x [81,180]
    [BAY_X0, BAY_X1, SPOON_Y0, SPOON_Y0 + SPOON_BAY], // spoon bay [6,202] x [186,297]
];

YC_OUTL  = OUTER_L[0] + HOST_T/2;   // 3   outer-left wall center
YC_DIVKF = DIV_KF[0]  + HOST_T/2;   // 78  knife/fork divider center
YC_DIVFS = DIV_FS[0]  + HOST_T/2;   // 183 fork/spoon divider center
YC_OUTR  = OUTER_R[0] + HOST_T/2;   // 300 outer-right wall center

// seams
AB_SEAM = HALF_LEN;               // 104  A/B length seam (x)
SEAM_KF = FORK_Y0;                // 81   knife/fork width seam (y)
SEAM_FS = SPOON_Y0;              // 186  fork/spoon width seam (y)
ENDC_A  = END_WALL/2;             // 3    A end-wall center (x) -> chamber dovetails
ENDC_B  = TOTAL_LEN - END_WALL/2; // 205  B end-wall center (x)


// ============================================================================
// 2D wall footprint (cross-section of all walls, constant in z for the straight
// part). Union of: 2 full-width end walls + 4 lengthwise walls between them.
// ============================================================================
module wall_footprint_2d() {
    // footprint = outer rectangle minus the 3 open bays  (== the 6 walls)
    difference() {
        square([TOTAL_LEN, EXT_W]);
        for (b = BAYS) translate([b[0], b[2]]) square([b[1] - b[0], b[3] - b[2]]);
    }
}

// ============================================================================
// The full chamfered box solid = base plate + walls with a continuous 1 mm
// top-rim chamfer. Built ONCE; every piece is carved out of this.
// ============================================================================
module chamfer_cap() {
    // SMOOTH 45 rim chamfer over z[BODY_H-CHAMFER, BODY_H], in absolute coords.
    zm = BODY_H - CHAMFER;
    if (USE_ROOF) {
        // exact straight-skeleton roof, capped at CHAMFER height (needs roof()).
        intersection() {
            translate([0,0,zm]) roof() wall_footprint_2d();
            translate([0,0,zm]) linear_extrude(CHAMFER + EPS) wall_footprint_2d();
        }
    } else {
        // DEFAULT: true 45 bevel as hull() frustums of CONVEX rectangles -> smooth
        // AND a clean manifold.  Since footprint = outer - bays, the chamfer of the
        // footprint = (outer rectangle beveled inward) MINUS (each bay beveled so it
        // grows toward the top, which bevels every bay-facing rim).  All hull()s are
        // on convex rectangles, so nothing gets convex-filled.
        difference() {
            // outer perimeter frustum: full outer rect at zm -> inset by CHAMFER at top
            hull() {
                translate([0,0,zm])     linear_extrude(0.001) square([TOTAL_LEN, EXT_W]);
                translate([0,0,BODY_H]) linear_extrude(0.001) offset(delta=-CHAMFER) square([TOTAL_LEN, EXT_W]);
            }
            // each bay grows by CHAMFER toward the top -> bevels its surrounding rim.
            // (overshoots z a hair past both ends so the cut is clean.)
            for (b = BAYS)
                hull() {
                    translate([0,0,zm-EPS])     linear_extrude(0.001)
                        translate([b[0],b[2]]) offset(delta=-EPS)        square([b[1]-b[0], b[3]-b[2]]);
                    translate([0,0,BODY_H+EPS]) linear_extrude(0.001)
                        translate([b[0],b[2]]) offset(delta=CHAMFER+EPS) square([b[1]-b[0], b[3]-b[2]]);
                }
        }
    }
}

module box() {
    zm = BODY_H - CHAMFER;
    union() {
        cube([TOTAL_LEN, EXT_W, BASE]);                                        // base plate z[0,3]
        translate([0,0,BASE]) linear_extrude(zm - BASE + EPS) wall_footprint_2d(); // straight walls z[3,57]
        chamfer_cap();                                                         // smooth chamfer z[57,58]
    }
}

// ============================================================================
// Dovetail prisms ( /_\ ). Vertical, z[BASE, BODY_H+CUT_OVER] so they cut
// through the rim but leave the base plate continuous. The near face is pushed
// back EPS so a male key always fuses to its wall.
//   male key   : half_n=DT_NECK,         half_f=DT_FLARE
//   female slot: half_n=DT_NECK+DT_CLR,  half_f=DT_FLARE+DT_CLR
// ============================================================================
module dt_prism_X(seam_x, yc, half_n, half_f) {   // perpendicular to X, grows +X
    translate([0,0,BASE]) linear_extrude(BODY_H - BASE + CUT_OVER)
        polygon([[seam_x - EPS,        yc - half_n],
                 [seam_x + DT_DEPTH,   yc - half_f],
                 [seam_x + DT_DEPTH,   yc + half_f],
                 [seam_x - EPS,        yc + half_n]]);
}
module dt_prism_Y(seam_y, xc, half_n, half_f) {   // perpendicular to Y, grows +Y
    translate([0,0,BASE]) linear_extrude(BODY_H - BASE + CUT_OVER)
        polygon([[xc - half_n, seam_y - EPS],
                 [xc - half_f, seam_y + DT_DEPTH],
                 [xc + half_f, seam_y + DT_DEPTH],
                 [xc + half_n, seam_y - EPS]]);
}
module ab_key   (yc)        { dt_prism_X(AB_SEAM, yc, DT_NECK, DT_FLARE); }
module ch_key   (seam_y, xc){ dt_prism_Y(seam_y, xc, DT_NECK, DT_FLARE); }

// Female sockets = male + DT_CLR on the flanks/seam (unchanged), PLUS a straight
// back-face relief of DT_DEPTH_RELIEF so the tail tip never bottoms out. The
// relief is a rectangle tacked onto the trapezoid's tip at the SAME flare width,
// so the angled flank faces (and their 0.4 mm slide clearance) are untouched.
module ab_socket(yc) {
    dt_prism_X(AB_SEAM, yc, DT_NECK + DT_CLR, DT_FLARE + DT_CLR);
    translate([0,0,BASE]) linear_extrude(BODY_H - BASE + CUT_OVER)
        translate([AB_SEAM + DT_DEPTH, yc - (DT_FLARE + DT_CLR)])
            square([DT_DEPTH_RELIEF, 2*(DT_FLARE + DT_CLR)]);          // back relief, +X
}
module ch_socket(seam_y, xc) {
    dt_prism_Y(seam_y, xc, DT_NECK + DT_CLR, DT_FLARE + DT_CLR);
    translate([0,0,BASE]) linear_extrude(BODY_H - BASE + CUT_OVER)
        translate([xc - (DT_FLARE + DT_CLR), seam_y + DT_DEPTH])
            square([2*(DT_FLARE + DT_CLR), DT_DEPTH_RELIEF]);          // back relief, +Y
}

// rectangular cell (x[xa,xb], y[ya,yb], full height + margin) used to split pieces
module cell(xa, xb, ya, yb) {
    translate([xa, ya, -1]) cube([xb - xa, yb - ya, BODY_H + 11]);
}

// ===== base half-lap (shiplap) =================================================
// HORIZONTAL lap at mid-base height: the shelf-owner keeps its BOTTOM half
// (z 0..LAP_Z) extending LAP_LEN past the seam; the neighbour has its bottom half
// REMOVED there (keeps only the top half) and lands flat on the shelf. Horizontal
// faces => no binding during the vertical drop. Shelves live entirely in the base
// (z < BASE), well clear of the wall dovetails (z >= BASE).
// Shingle = FEMALE-first (matches the no-notch dovetail assembly order, which
// lowers the male piece onto the female): the B half owns the A/B shelf (grows
// -X into A) and the UPPER chamber (fork, spoon) owns the chamber shelf (grows
// -Y into the lower chamber).  Order: spoon, fork, knife; B before A.
module lap_shelf_X(y0, y1) {                 // B-side shelf, grows -X into A past AB_SEAM
    // +EPS past AB_SEAM so the shelf interpenetrates (not just abuts) its own B body -> fuses cleanly.
    translate([AB_SEAM - LAP_LEN, y0, 0]) cube([LAP_LEN + EPS, y1 - y0, LAP_Z]);
}
module lap_neg_X(y0, y1) {                   // A-side: remove bottom half to receive it
    translate([AB_SEAM - LAP_LEN - LAP_CLR, y0 - EPS, -EPS])
        cube([LAP_LEN + LAP_CLR + EPS, (y1 - y0) + 2*EPS, LAP_Z + EPS]);
}
module lap_shelf_Y(seam_y, x0, x1, ln=LAP_LEN) {   // upper-chamber shelf, grows -Y into lower
    // grows -Y by `ln` into the lower chamber AND +Y by 2*SEAM_EPS past the seam so it
    // always overlaps the (SEAM_EPS-nudged) body floor and stays fused -> no floating shelf.
    translate([x0, seam_y - ln, 0]) cube([x1 - x0, ln + 2*SEAM_EPS, LAP_Z]);
}
module lap_neg_Y(seam_y, x0, x1, ln=LAP_LEN) {     // lower-chamber: remove bottom half
    translate([x0 - EPS, seam_y - ln - LAP_CLR, -EPS])
        cube([(x1 - x0) + 2*EPS, ln + LAP_CLR + EPS, LAP_Z + EPS]);
}

// ============================================================================
// The six pieces.  piece = intersection(box, cell + own male keys) - own sockets
//   A halves are MALE on the A/B seam (keep the key); B halves are FEMALE (slot).
//   On a chamber seam the LEFT chamber is male (+Y), the right chamber is female.
// ============================================================================
// Base half-lap shingling (FEMALE-first, Option 1):
//   A/B seam  -> the B half owns the bottom shelf (grows -X), A has the negative.
//   chamber   -> the UPPER chamber (fork, spoon) owns the shelf (grows -Y); the
//                lower chamber (knife, fork) has the negative.
//   Assembly order: spoon, fork, knife; B before A (male lowered onto female).
// Center crossings (104,81)&(104,186): the CHAMBER shelf (fork_A / spoon_A) owns the
//   crossing square; the B-half A/B shelf (knife_B / fork_B) is CLIPPED short of the
//   chamber seam by LAP_LEN so two shelves never collide.
module knife_A() {                                       // placed LAST; receives everything
    difference() {
        intersection() {
            box();
            union() {
                cell(-1, AB_SEAM, KNIFE_Y0 - 1, KNIFE_Y1);
                ab_key(YC_OUTL); ab_key(YC_DIVKF); ch_key(SEAM_KF, ENDC_A);
            }
        }
        lap_neg_X(KNIFE_Y0, KNIFE_Y1);            // receive knife_B's A/B shelf
        lap_neg_Y(SEAM_KF, 0, AB_SEAM);           // receive fork_A's chamber shelf
    }
}

module knife_B() {
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(AB_SEAM, TOTAL_LEN + 1, KNIFE_Y0 - 1, KNIFE_Y1);
                    ch_key(SEAM_KF, ENDC_B);
                }
            }
            lap_shelf_X(KNIFE_Y0, KNIFE_Y1 - LAP_LEN);  // A/B shelf -> knife_A (CLIPPED at y=81 crossing)
        }
        ab_socket(YC_OUTL); ab_socket(YC_DIVKF);
        lap_neg_Y(SEAM_KF, AB_SEAM, TOTAL_LEN);         // receive fork_B's chamber shelf
    }
}

module fork_A() {
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(-1, AB_SEAM, FORK_Y0 + SEAM_EPS, FORK_Y1);  // -Y cut nudged off the divider face
                    ab_key(YC_DIVFS); ch_key(SEAM_FS, ENDC_A);
                }
            }
            lap_shelf_Y(SEAM_KF, 0, AB_SEAM);           // chamber shelf -> knife_A (owns crossing)
        }
        lap_neg_X(FORK_Y0, FORK_Y1);                    // receive fork_B's A/B shelf
        ch_socket(SEAM_KF, ENDC_A);
        lap_neg_Y(SEAM_FS, 0, AB_SEAM, LAP_LEN_FS);     // receive spoon_A's (small) chamber shelf
    }
}

module fork_B() {
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(AB_SEAM, TOTAL_LEN + 1, FORK_Y0 + SEAM_EPS, FORK_Y1);  // -Y cut nudged off the divider face
                    ch_key(SEAM_FS, ENDC_B);
                }
            }
            lap_shelf_X(FORK_Y0, FORK_Y1 - LAP_LEN_FS); // A/B shelf -> fork_A (CLIPPED at y=186 crossing)
            lap_shelf_Y(SEAM_KF, AB_SEAM, TOTAL_LEN);   // chamber shelf -> knife_B
        }
        ab_socket(YC_DIVFS);
        ch_socket(SEAM_KF, ENDC_B);
        lap_neg_Y(SEAM_FS, AB_SEAM, TOTAL_LEN, LAP_LEN_FS); // receive spoon_B's (small) chamber shelf
    }
}

module spoon_A() {
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(-1, AB_SEAM, SPOON_Y0 + SEAM_EPS, SPOON_Y1 + 1);  // -Y cut nudged off the divider face
                    ab_key(YC_OUTR);
                }
            }
            lap_shelf_Y(SEAM_FS, 0, AB_SEAM, LAP_LEN_FS); // chamber shelf -> fork_A (small; owns crossing)
        }
        lap_neg_X(SPOON_Y0, SPOON_Y1);                  // receive spoon_B's A/B shelf
        ch_socket(SEAM_FS, ENDC_A);
    }
}

module spoon_B() {                                      // placed FIRST; owns shelves
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(AB_SEAM, TOTAL_LEN + 1, SPOON_Y0 + SEAM_EPS, SPOON_Y1 + 1);  // -Y cut nudged off the divider face
                }
            }
            lap_shelf_X(SPOON_Y0, SPOON_Y1);            // A/B shelf -> spoon_A
            lap_shelf_Y(SEAM_FS, AB_SEAM, TOTAL_LEN, LAP_LEN_FS); // chamber shelf -> fork_B (small)
        }
        ab_socket(YC_OUTR);
        ch_socket(SEAM_FS, ENDC_B);
    }
}

// Fast preview: the full continuous-chamfer box (no cuts). The six part modules
// above are the real, separable pieces. To instead see the TRUE assembled
// pieces with their joints (slower — 6 booleans), replace box(); below with:
//   knife_A(); knife_B(); fork_A(); fork_B(); spoon_A(); spoon_B();
module assembly() {
    box();
}

// ============================================================================
// Render dispatch
// ============================================================================
if      (part == "knife_A")  knife_A();
else if (part == "knife_B")  knife_B();
else if (part == "fork_A")   fork_A();
else if (part == "fork_B")   fork_B();
else if (part == "spoon_A")  spoon_A();
else if (part == "spoon_B")  spoon_B();
else if (part == "assembly") assembly();
else echo(str("Unknown part: ", part));
