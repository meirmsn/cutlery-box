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
// TRIAL-PRINT FIX (Option A) set the FEMALE socket to neck 1.5 / flare 2.0 half
//   (= DT_NECK+DT_CLR / DT_FLARE+DT_CLR), giving ear = HOST_T/2 - flare 2.0 = 1.0 mm.
//   That female side printed great and is now FINAL.
// KEY #2 (full-height slide test, 2026-06): the male was too loose at 0.3 mm/side
//   (popped when pulled horizontally). We tighten the per-side slide clearance
//   0.3 -> 0.15 by GROWING the male tail to neck 1.35 / flare 1.85 half. The SOCKET is
//   UNCHANGED (1.35+0.15 = 1.5, 1.85+0.15 = 2.0), so the already-printed female side is
//   not affected. ear = 3 - (1.85+0.15) = 1.0 mm and undercut hook (DT_FLARE-DT_NECK)
//   = 0.5 mm are both UNCHANGED; only the slide clearance tightens.
DT_DEPTH = 5.0;   // tail protrusion past the seam (male key depth)
DT_NECK  = 1.35;  // male half-width at the seam face (narrow)  [key#2: was 1.2]
DT_FLARE = 1.85;  // male half-width at the tip (wide -> locks) [key#2: was 1.7]
DT_CLR   = 0.15;  // FLANK/seam slide clearance added for the female socket [key#2: was 0.3]
DT_DEPTH_RELIEF = 0.3; // extra depth on the socket BACK only, so the tail tip never bottoms out
// ---- FUTURE TRIAL — Option B (thicker ears still: 1.2 mm) -------------------------
// If Option A's ears still feel thin, try Option B. It buys another 0.2 mm of ear by
// also narrowing the MALE neck (so the male gets a little weaker — that's the trade):
//     DT_NECK  = 1.0;   // was 1.2  (male neck 2.4 -> 2.0 mm full width)
//     DT_FLARE = 1.5;   // was 2.1
//     DT_CLR   = 0.3;   // same as Option A
//   -> ear = 3 - (1.5 + 0.3) = 1.2 mm ; undercut hook = 1.5 - 1.0 = 0.5 mm (same as A).
// Only switch ONE option in at a time; re-test the knife pair before committing all six.
// ----------------------------------------------------------------------------------

/* [Hidden-dovetail top cap / "hat" (mm)] */
// The dovetail otherwise shows its trapezoid outline on the TOP edge of the wall.
// To hide it, the MALE piece extends the wall's full-width top (chamfer included)
// across the key footprint -> a flush, continuous top. The FEMALE piece gets a
// matching top RECESS (cap footprint + CAP_CLR) so the cap drops straight in.
// Result: the top reads as one surface with a single straight seam line at the cap
// tip; the dovetail joinery lives entirely below the cap.
//
// SELF-SUPPORTING UNDERSIDE: the cap reaches the FULL wall width at the chamfer base
// (so the top edge reads as the wall extended, with NO recessed sliver on the outer
// face), and its underside is ONE planar ramp from the chamfer's OUTER CORNER
// (half-width HOST_T/2 at z = BODY_H-CHAMFER) down to the dovetail-neck half-width
// (CAP_FOOT) at CAP_SLANT_DEG from horizontal. No little horizontal step. The ramp
// reaching full width exactly at the chamfer base means "ramp top" == "chamfer base"
// (CAP_H is DERIVED). The FEMALE recess is the same ramp + CAP_CLR play.
// TRADEOFF: because the cap runs all the way to the outer corner, the female wall
// tapers to ~0 at z = BODY_H-CHAMFER -> a thin feather edge at the joint (gradual at
// CAP_SLANT_DEG, hidden inside the joint when assembled). Accepted per design intent.
CAP_SLANT_DEG = 50;     // cap underside ramp angle from horizontal (50 = self-supporting, long flare)
CAP_FOOT = 1.2;         // cap-underside half-width [PINNED to the pre-key#2 neck so the
                        // FINAL female cap-recess (CAP_FOOT+CAP_CLR) is unchanged; the
                        // 0.15 mm tongue-vs-cap-foot step is buried inside the joint]
CAP_CLR = 0.3;          // slide clearance so the male cap seats into the female top recess

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

/* [Lid — box features that receive a flat ORDERED clear sheet] */
// The lid itself is NOT printed: it's a flat ~2 mm PETG/Tritan sheet, bullnose-polished
// edges (r=LID_EDGE_R), ordered to size. We only model the box features that receive it.
LID_T            = 2.0;   // ordered sheet thickness
LID_EDGE_R       = 1.0;   // ordered sheet bullnose edge radius (for the sheet order spec)
LID_PLAY         = 0.4;   // total vertical play in the hinge groove (sheet + this)
LID_RECESS       = 2.0;   // lid TOP sits this far BELOW the rim, so the journal pocket is fully
                          // capped (rim caps the bullnose -> retains the lid when raised; tilt-in)
HINGE_AT_MINUS_X = true;  // hinge on the -x (303mm) end wall; clip on +x. (flip = mirror; default delivered)
// perimeter support ledge (lid underside rests on it at z = BODY_H-LID_T)
LEDGE_W          = 2.0;   // ledge inward protrusion (its underside ramps back at 45 deg -> self-supporting)
GROOVE_END_INSET = 0.0;   // groove reaches the corners but RUNS OUT smoothly there (no end-face / no
                          // exposed bore); GROOVE_TAPER sets the run-out length
GROOVE_TAPER     = 4.0;   // y-length over which the eased mouth tapers out at each groove end
// hinge journal (cut into the inner face of the hinge end wall, CONTINUOUS along the long edge)
GROOVE_DEPTH     = 3.0;   // 2mm lead-in slot + 1mm pocket radius -> journal sits 2mm back from the
                          // face so its cap clears the swing relief and RETAINS the lid
GROOVE_POCKET_R  = 1.0;   // journal half-cylinder radius (the bullnose sheet edge rolls in it)
// clip latch — TWO light DETENT clips on the clip end wall, flanking a central finger notch.
// "Light detent" = small overhang so the rigid sheet pops past it by hand (not a firm lock).
CLIP_W           = 8.0;   // width of EACH of the two clips
CLIP_LIP         = 0.3;   // retaining overhang (light detent; 0.3 soft .. 0.6 firm-but-stiff)
CLIP_RAMP_H      = 1.6;   // cam-ramp height (press-to-close lead-in)
// finger notch — a through-cut in the clip wall (visible from outside), centered between the
// two clips, so a fingertip can reach the lid edge and lift it (popping both clips at once).
NOTCH_W          = 20.0;  // finger-notch width
NOTCH_DEPTH      = 6.0;   // how far down from the rim to the deepest point (past the lid edge)
NOTCH_ARCH       = 4.0;   // bottom is an ELLIPTICAL arch this tall; the rest is vertical sides
                          // (NOTCH_ARCH < NOTCH_W/2 -> a gentle arch, not a deep half-circle)


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

// hidden-cap ramp geometry (derived).
//   CAP_HW    = cap MAX half-width = HOST_T/2 (the full wall edge) at the chamfer base.
//   CAP_RISE  = vertical height of the self-supporting CAP_SLANT_DEG underside ramp.
//   CAP_ZRAMP = where the cap reaches full width = the chamfer base (BODY_H-CHAMFER), so
//               the ramp runs straight to the chamfer OUTER CORNER (no horizontal step).
//   CAP_ZBOT  = cap bottom = ramp start; CAP_H derived from it (for reference/report).
//   CAP_ZRAMP_R = recess ramp top, shifted down by CAP_CLR so the recess ramp stays
//               parallel to the cap ramp with uniform play.
CAP_HW      = HOST_T/2;   // cap reaches the FULL wall edge at the chamfer base
CAP_RISE    = (CAP_HW - CAP_FOOT) * tan(CAP_SLANT_DEG);
CAP_ZRAMP   = BODY_H - CHAMFER;               // full width exactly at the chamfer base / outer corner
CAP_ZBOT    = CAP_ZRAMP - CAP_RISE;
CAP_H       = BODY_H - CAP_ZBOT;              // derived; reported
CAP_ZRAMP_R = CAP_ZRAMP;   // recess ramp ALSO tops at the chamfer corner (mirror the cap) -> no vertical lip
// sanity checks
assert(CAP_ZBOT > BASE + 1,
       "cap zone dips too low -- raise CAP_SLANT_DEG");
assert(CAP_HW >= DT_FLARE,
       "cap too narrow to cover the dovetail tail");

// NOTE: lid-derived constants are defined BELOW the Y-layout block, because some of
// them (INTERIOR_Y0/Y1, CLIP_CY) depend on OUTER_L / OUTER_R / EXT_W. See "lid derived".

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

// ---- lid derived ---- (placed AFTER OUTER_L/OUTER_R/EXT_W so nothing is forward-referenced)
LID_TOP_Z   = BODY_H - LID_RECESS;        // 56  lid TOP (recessed); rim z=58 rises LID_RECESS above it
LID_Z_UNDER = LID_TOP_Z - LID_T;          // 54  lid underside / ledge top / lowered-divider top
POCKET_CZ   = LID_TOP_Z - LID_T/2;        // 55  journal centre (lid mid) -> pocket top = LID_TOP_Z = capped
// hinge end-wall inner face x + inward direction; clip end-wall inner face x + inward dir
HINGE_INX   = HINGE_AT_MINUS_X ? END_WALL : TOTAL_LEN - END_WALL;       // 6  (default)
HINGE_IN    = HINGE_AT_MINUS_X ? 1 : -1;  // interior direction from the hinge wall (+x default)
CLIP_INX    = HINGE_AT_MINUS_X ? TOTAL_LEN - END_WALL : END_WALL;       // 202 (default)
CLIP_IN     = HINGE_AT_MINUS_X ? -1 : 1;  // interior direction from the clip wall (-x default)
POCKET_CX   = HINGE_INX - HINGE_IN*(GROOVE_DEPTH - GROOVE_POCKET_R);    // 5  pocket centre x (INTO the wall)
INTERIOR_Y0 = OUTER_L[1];                 // 6   inner face of the -y short wall
INTERIOR_Y1 = OUTER_R[0];                 // 297 inner face of the +y short wall
CLIP_CY     = EXT_W/2;                     // 151.5 clip/scallop centre (in the fork chamber)
assert(POCKET_CZ - GROOVE_POCKET_R > BASE + 1,
       "journal dips too low -- reduce LID_RECESS or LID_T");
assert(POCKET_CZ + GROOVE_POCKET_R <= LID_TOP_Z + EPS,
       "journal not capped -- lower the lid (raise LID_RECESS) or shrink GROOVE_POCKET_R");
// NOTE: with LID_RECESS the lid underside (and lowered dividers) sit BELOW CAP_ZBOT. That is
// intended: the inner dividers are cut flat below the cap zone (their hidden caps are removed,
// but the lid covers them); the perimeter/end-wall caps are untouched (full-height walls).

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

// ===== hidden-dovetail top cap ("hat"), SELF-SUPPORTING underside ===============
// MALE cap: a FULL-wall-width hat whose underside is ONE planar ramp from the chamfer's
// OUTER CORNER (half-width CAP_HW = HOST_T/2 at CAP_ZRAMP = BODY_H-CHAMFER) down to the
// dovetail-neck half-width (CAP_FOOT) at CAP_SLANT_DEG from horizontal -> the self-
// supporting shoulder, running straight to the corner (no horizontal step). Built as
// hull(narrow bottom slab buried in the tail neck, full-width top slab through the rim);
// box() trims it to the wall and adds the continuous rim chamfer for free, so the outer
// top edge reads as the wall extended (no recessed sliver). The protruding NOSE is left
// SQUARE (vertical) -- hidden in the female socket when assembled.
// TRADEOFF: the female wall tapers to ~0 at z=BODY_H-CHAMFER (a thin feather edge at the
// joint, gradual at CAP_SLANT_DEG) -- accepted per design intent.
module ab_cap(yc) {   // A/B seam, grows +X past the seam (length direction)
    hull() {
        translate([AB_SEAM - EPS, yc - CAP_FOOT, CAP_ZBOT])
            cube([DT_DEPTH + EPS, 2*CAP_FOOT, EPS]);
        translate([AB_SEAM - EPS, yc - CAP_HW,   CAP_ZRAMP])
            cube([DT_DEPTH + EPS, 2*CAP_HW, (BODY_H + CUT_OVER) - CAP_ZRAMP]);
    }
}
module ch_cap(seam_y, xc) {   // chamber seam, grows +Y past the seam (in the end wall)
    hull() {
        translate([xc - CAP_FOOT, seam_y - EPS, CAP_ZBOT])
            cube([2*CAP_FOOT, DT_DEPTH + EPS, EPS]);
        translate([xc - CAP_HW,   seam_y - EPS, CAP_ZRAMP])
            cube([2*CAP_HW, DT_DEPTH + EPS, (BODY_H + CUT_OVER) - CAP_ZRAMP]);
    }
}
// FEMALE recess: the SAME ramp grown by CAP_CLR (flanks, tip, floor, and ramp shifted down
// by CAP_CLR so it stays parallel) -> the cap seats with uniform slide clearance. It opens
// to the wall edge (and a hair past, into air) so the cap's full-width corner drops in;
// this is what leaves the thin female feather at the top (accepted). Open upward + toward seam.
module ab_cap_neg(yc) {
    hull() {
        translate([AB_SEAM - EPS, yc - (CAP_FOOT + CAP_CLR), CAP_ZBOT - CAP_CLR])
            cube([DT_DEPTH + CAP_CLR + EPS, 2*(CAP_FOOT + CAP_CLR), EPS]);
        translate([AB_SEAM - EPS, yc - (CAP_HW + EPS), CAP_ZRAMP_R])
            cube([DT_DEPTH + CAP_CLR + EPS, 2*(CAP_HW + EPS), (BODY_H + CUT_OVER + 1) - CAP_ZRAMP_R]);
    }
}
module ch_cap_neg(seam_y, xc) {
    hull() {
        translate([xc - (CAP_FOOT + CAP_CLR), seam_y - EPS, CAP_ZBOT - CAP_CLR])
            cube([2*(CAP_FOOT + CAP_CLR), DT_DEPTH + CAP_CLR + EPS, EPS]);
        translate([xc - (CAP_HW + EPS), seam_y - EPS, CAP_ZRAMP_R])
            cube([2*(CAP_HW + EPS), DT_DEPTH + CAP_CLR + EPS, (BODY_H + CUT_OVER + 1) - CAP_ZRAMP_R]);
    }
}
// LOWERED-DIVIDER hat: same 50-deg self-supporting cap as ab_cap, but reaching FULL width at the
// LOWERED divider top (LID_Z_UNDER) instead of the rim -- because the inner dividers are lowered
// for the lid, which strips their normal cap. It extends above the top and is trimmed flush to
// LID_Z_UNDER by divider_lower(), so the divider top reads as one surface (dovetail hidden below).
DCAP_ZRAMP = LID_Z_UNDER;            // full width at the lowered divider top (54)
DCAP_ZBOT  = DCAP_ZRAMP - CAP_RISE;  // ramp start (neck), 50 deg below
module div_cap(yc) {        // male hat on the lowered divider (A/B seam)
    hull() {
        translate([AB_SEAM - EPS, yc - CAP_FOOT, DCAP_ZBOT])
            cube([DT_DEPTH + EPS, 2*CAP_FOOT, EPS]);
        translate([AB_SEAM - EPS, yc - CAP_HW,   DCAP_ZRAMP])
            cube([DT_DEPTH + EPS, 2*CAP_HW, (BODY_H + CUT_OVER) - DCAP_ZRAMP]);
    }
}
module div_cap_neg(yc) {    // female recess to receive div_cap (with CAP_CLR slide play)
    hull() {
        translate([AB_SEAM - EPS, yc - (CAP_FOOT + CAP_CLR), DCAP_ZBOT - CAP_CLR])
            cube([DT_DEPTH + CAP_CLR + EPS, 2*(CAP_FOOT + CAP_CLR), EPS]);
        translate([AB_SEAM - EPS, yc - (CAP_HW + EPS), DCAP_ZRAMP])
            cube([DT_DEPTH + CAP_CLR + EPS, 2*(CAP_HW + EPS), (BODY_H + CUT_OVER + 1) - DCAP_ZRAMP]);
    }
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

// ----- 45-deg RAMPED chamber lap (TRIAL-PRINT FIX, fork/spoon seam only) --------
// The flat half-lap above leaves the receiver's lip floating over a 1.5 mm blind
// pocket -> support packs in and won't clean out (seen on fork_B). Replace it at
// the fork/spoon seam with a 45-deg ramped lap (Option 1): the upper chamber
// (spoon) owns a SOLID WEDGE that is full LAP_Z at the seam and tapers to 0 a
// distance LAP_Z into the lower chamber (run == rise == LAP_Z -> true 45 deg).
// The lower chamber (fork) gets the complementary ramped pocket: solid floor runs
// into its bay, and the lap underside is a 45-deg ramp down to the bed -> no flat
// roof -> prints with NO support. Built via linear_extrude (always manifold; no
// polyhedron winding to get wrong). rotate([90,0,90]) maps the local (y,z) profile
// onto the world Y-Z plane and extrudes the prism along +X.
//   spoon-owned wedge:  fs_wedge(seam_y, x0, x1)   (replaces lap_shelf_Y at SEAM_FS)
//   fork-side pocket:    fs_pocket(seam_y, x0, x1)  (replaces lap_neg_Y  at SEAM_FS)
module fs_wedge(seam_y, x0, x1) {                  // solid wedge, sits flat on the bed
    translate([x0, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(x1 - x0)
                polygon([[seam_y - LAP_Z,     0],          // bay-side tip (on bed)
                         [seam_y + 2*SEAM_EPS, 0],          // seam-side foot (+overlap into spoon body -> fuses)
                         [seam_y + 2*SEAM_EPS, LAP_Z]]);    // seam-side top
}
module fs_pocket(seam_y, x0, x1) {                 // fork negative = wedge profile grown by LAP_CLR
    // offset(delta) grows every edge outward by LAP_CLR -> a UNIFORM ~0.2 mm gap on
    // the slanted mating face (a non-uniform inset would pinch to a near-press fit at
    // the seam). Costs ~0.2 mm of lip thickness near the seam (1.5 -> ~1.3 mm) -- fine,
    // the divider wall sits right on top of it. Sharp (mitred) offset: delta, no r.
    translate([x0 - EPS, 0, 0])
        rotate([90, 0, 90])
            linear_extrude((x1 - x0) + 2*EPS)
                offset(delta = LAP_CLR)
                    polygon([[seam_y - LAP_Z, 0],
                             [seam_y,         0],
                             [seam_y,         LAP_Z]]);
}

// ----- 45-deg RAMPED A/B lap (TRIAL-PRINT FIX, A/B mid-seam) --------------------
// Same idea as fs_wedge/fs_pocket but the lap runs perpendicular to X (the A/B
// seam) instead of Y. The B half owns a SOLID WEDGE full at the seam, tapering to
// 0 a distance LAP_Z into the A side (-X); the A half gets the ramped pocket. The
// profile lives in the X-Z plane; the prism runs along Y over [y0,y1].
// rotate([-90,0,0]) maps local (x,y,z) -> (x,z,-y), so a local polygon authored in
// (x, -z) extruded along local Z becomes a Y-prism with the correct X-Z profile.
// NOTE: the A/B lap is engaged by the straight-DOWN drop of the whole B row onto
// the A row; flat faces never bind, two 45-deg faces can cam, so the LAP_CLR gap is
// load-bearing here -> assembly-test this one before committing all six.
//   B-owned wedge:  ab_wedge(AB_SEAM, y0, y1)   (replaces lap_shelf_X)
//   A-side pocket:   ab_pocket(AB_SEAM, y0, y1)  (replaces lap_neg_X)
module ab_wedge(seam_x, y0, y1) {                  // solid wedge, sits flat on the bed
    translate([0, y0, 0])
        rotate([-90, 0, 0])
            linear_extrude(y1 - y0)
                polygon([[seam_x - LAP_Z,       0],          // A-side tip (on bed)
                         [seam_x + 2*SEAM_EPS,  0],          // seam-side foot (+overlap into B body -> fuses)
                         [seam_x + 2*SEAM_EPS, -LAP_Z]]);    // seam-side top (-z in local -> +z world)
}
module ab_pocket(seam_x, y0, y1) {                 // A negative = wedge grown by LAP_CLR
    translate([0, y0 - EPS, 0])
        rotate([-90, 0, 0])
            linear_extrude((y1 - y0) + 2*EPS)
                offset(delta = LAP_CLR)
                    polygon([[seam_x - LAP_Z,  0],
                             [seam_x,          0],
                             [seam_x,         -LAP_Z]]);
}

// ===== corner crossing key (TRIAL-PRINT FIX) ==================================
// At each A/B-seam x divider crossing the half-lap left a thin 1.5 mm dangling tab
// (the chamber shelf) with a floating lip above it. Instead we make a SOLID
// FULL-HEIGHT base corner on the DIVIDER-OWNING piece (so it sits right under that
// piece's own divider wall -> well anchored, no dangle, squared off), and CLIP the
// neighbour chamber shelf back by LAP_CLR so nothing collides. Added as a final
// union() AFTER the per-part cuts so the lap negatives don't eat it.
//   knife/fork divider -> boss on knife_A ; clip fork_A's SEAM_KF chamber shelf.
//   fork/spoon divider -> boss on fork_A  ; clip spoon_A's SEAM_FS chamber shelf.
// The boss spans x[seam-lap_x, seam] (the A side only) and the dangling y-strip; it
// overshoots z by EPS to fuse into the divider wall. B pieces are x>=seam -> untouched.
module corner_key(seam_x, lap_x, y0, y1) {
    translate([seam_x - lap_x, y0, 0]) cube([lap_x, y1 - y0, BASE + EPS]);
}
CORNER_CLIP = LAP_LEN + LAP_CLR;   // how far to pull a chamber shelf back from the A/B seam

// ============================================================================
// LID FEATURES (receive a flat ORDERED clear sheet; the sheet is not printed).
// All features live at the TOP (z >= ~52), ABOVE the dovetail engagement, the half-lap
// (z<1.5) and most of the hat, so the vertical-drop assembly and joints are untouched.
// EPS overlaps throughout; no coincident coplanar faces with the existing walls.
// Default orientation: HINGE on the -x end wall (A pieces), CLIP on the +x end wall
// (B pieces), clip+scallop centred on the fork (middle) chamber.
// ============================================================================

// --- perimeter support ledge: 45-deg self-supporting brackets; rest face at LID_Z_UNDER.
//     Runs along the CLIP end wall + the two short outer walls. (Hinge wall uses the groove.)
//     Built as hull(thin top edge, wall column) -> a triangular bracket whose underside is
//     a 45-deg ramp (prints floor-down with no support). ADDED to each piece (clipped by cell).
//     Each run is INSET by LEDGE_W from the perpendicular walls so the three brackets never
//     overlap at a corner and the wall's normal chamfer wraps every corner uninterrupted.
module lid_ledge() {
    cy0 = INTERIOR_Y0 + LEDGE_W;  cy1 = INTERIOR_Y1 - LEDGE_W;  cyl = cy1 - cy0;   // clip-run y span (inset)
    sx0 = END_WALL    + LEDGE_W;  sxl = (TOTAL_LEN - 2*END_WALL) - 2*LEDGE_W;       // short-run x span (inset)
    // clip end wall (x = CLIP_INX), bracket protrudes toward interior (CLIP_IN)
    hull() {
        translate([CLIP_INX + CLIP_IN*LEDGE_W, cy0, LID_Z_UNDER - EPS]) cube([EPS, cyl, EPS]);
        translate([CLIP_INX - EPS,             cy0, LID_Z_UNDER - LEDGE_W]) cube([2*EPS, cyl, LEDGE_W]);
    }
    // OUTER_L short wall (y = INTERIOR_Y0), bracket protrudes +y
    hull() {
        translate([sx0, INTERIOR_Y0 + LEDGE_W, LID_Z_UNDER - EPS]) cube([sxl, EPS, EPS]);
        translate([sx0, INTERIOR_Y0 - EPS,     LID_Z_UNDER - LEDGE_W]) cube([sxl, 2*EPS, LEDGE_W]);
    }
    // OUTER_R short wall (y = INTERIOR_Y1), bracket protrudes -y
    hull() {
        translate([sx0, INTERIOR_Y1 - LEDGE_W, LID_Z_UNDER - EPS]) cube([sxl, EPS, EPS]);
        translate([sx0, INTERIOR_Y1 - EPS,     LID_Z_UNDER - LEDGE_W]) cube([sxl, 2*EPS, LEDGE_W]);
    }
}

// --- hinge groove: ONE 2D cross-section (journal bore + lead-in slot + 45-deg swing ramp),
//     CAPPED at the recessed lid top (LID_TOP_Z), swept along the wall. At BOTH ends the whole
//     profile RUNS OUT smoothly -- it tapers to the inner-top rim corner (HINGE_INX, BODY_H) --
//     so there is NO end-face and NO exposed bore at the corners; the groove just fades into the
//     wall. The rim caps the bullnose (retains the lid, tilt-in); the 45-deg ramp is self-
//     supporting and gives the swing clearance; the cap stays full over the bullnose => retains.
module groove_profile() {                            // 2D cross-section in (x, z)
    union() {
        translate([POCKET_CX, POCKET_CZ]) circle(r = GROOVE_POCKET_R, $fn = 28);              // journal bore
        translate([POCKET_CX, LID_Z_UNDER]) square([HINGE_INX - POCKET_CX + EPS, LID_T]);     // lead-in slot
        polygon([[POCKET_CX, LID_TOP_Z], [HINGE_INX + EPS, LID_TOP_Z], [HINGE_INX + EPS, BODY_H - CHAMFER]]); // swing relief (below the rim chamfer)
        polygon([[HINGE_INX, BODY_H - CHAMFER], [HINGE_INX + EPS, BODY_H + EPS], [HINGE_INX - CHAMFER, BODY_H + EPS]]); // rim chamfer cut, CONTINUOUS through the divider junctions (no bulge)
    }
}
module groove_extrude(y0, y1) {                      // sweep the profile along the wall, y0..y1
    translate([0, y0, 0]) rotate([90,0,0]) translate([0,0,-(y1 - y0)]) linear_extrude(y1 - y0) groove_profile();
}
module hinge_groove() {
    // journal runs STRAIGHT to the end of the wall at each side; the perpendicular short wall
    // caps the bore there (no run-out). The EPS overlap tucks the bore end into the short wall.
    groove_extrude(INTERIOR_Y0 - EPS, INTERIOR_Y1 + EPS);
}

// --- lower the inner chamber dividers to the lid underside (mid-support, no sag).
//     Removes the divider top over the full length; outer walls keep full height.
module divider_lower() {
    // x-span is the CHAMBER BAY only [BAY_X0, BAY_X1] (+EPS overlap into the end walls so the
    // cut is manifold). The end/outer walls keep their full BODY_H tops; only the two INNER
    // dividers (DIV_KF, DIV_FS) are lowered.
    translate([BAY_X0 - EPS, DIV_KF[0], LID_Z_UNDER]) cube([BAY_X1 - BAY_X0 + 2*EPS, HOST_T, BODY_H - LID_Z_UNDER + CUT_OVER]);
    translate([BAY_X0 - EPS, DIV_FS[0], LID_Z_UNDER]) cube([BAY_X1 - BAY_X0 + 2*EPS, HOST_T, BODY_H - LID_Z_UNDER + CUT_OVER]);
}

// --- retaining clips (ADDED): TWO light detent lips on the clip end wall, flanking the finger
//     notch. Each lip overhangs the RECESSED lid top (LID_TOP_Z) by CLIP_LIP and gives a soft
//     hold; a lead-in ramp above it cams the lid under on close. Anchored into the wall. Light
//     enough that lifting the lid edge (through the notch) flexes the sheet past both at once.
CLIP_OFF = NOTCH_W/2 + CLIP_W/2;     // clip centre offset from CLIP_CY (clips sit just outside the notch)
module one_clip(yc) {
    translate([0, yc - CLIP_W/2, 0]) rotate([90,0,0]) translate([0,0,-CLIP_W]) linear_extrude(CLIP_W)
        polygon([[CLIP_INX - CLIP_IN*HOST_T/2, LID_TOP_Z - 0.8],         // anchor low, into the wall (fuse)
                 [CLIP_INX + CLIP_IN*CLIP_LIP, LID_TOP_Z],               // lip tip: overhang over the lid top
                 [CLIP_INX + CLIP_IN*CLIP_LIP, LID_TOP_Z + 0.4],         // lip front
                 [CLIP_INX - CLIP_IN*HOST_T/2, LID_TOP_Z + CLIP_RAMP_H]]);// lead-in ramp up into the wall
}
module lid_clip() {
    one_clip(CLIP_CY - CLIP_OFF);
    one_clip(CLIP_CY + CLIP_OFF);
}

// --- finger notch (CUT): a through-cut in the clip end wall, centred between the two clips.
//     Vertical sides + an ELLIPTICAL arched bottom (a rounded scoop, not a sharp box). Goes
//     THROUGH the wall so it reads as a visible scoop from the outside and a fingertip can
//     reach the lid edge to lift it. Deepest point is NOTCH_DEPTH below the rim.
module lid_finger_notch() {
    arch_cz = BODY_H - NOTCH_DEPTH + NOTCH_ARCH;          // z where the vertical sides meet the arc
    // vertical-sided upper part, open to the rim
    translate([CLIP_INX - EPS, CLIP_CY - NOTCH_W/2, arch_cz - EPS])
        cube([END_WALL + 2*EPS, NOTCH_W, (BODY_H + EPS) - (arch_cz - EPS)]);
    // elliptical arched bottom (y-semi = NOTCH_W/2, z-semi = NOTCH_ARCH), through the wall
    translate([CLIP_INX - EPS, CLIP_CY, arch_cz])
        scale([1, 1, NOTCH_ARCH/(NOTCH_W/2)])
        rotate([0, 90, 0])
        cylinder(h = END_WALL + 2*EPS, r = NOTCH_W/2, $fn = 48);
    // ALSO remove the support ledge across the notch span, so a fingertip can reach under the
    // lid edge here (the ledge/rail stays everywhere else to keep pinching the lid with the clips)
    lx0 = min(CLIP_INX, CLIP_INX + CLIP_IN*LEDGE_W) - EPS;
    lx1 = max(CLIP_INX, CLIP_INX + CLIP_IN*LEDGE_W) + EPS;
    translate([lx0, CLIP_CY - NOTCH_W/2, LID_Z_UNDER - LEDGE_W - EPS])
        cube([lx1 - lx0, NOTCH_W, LEDGE_W + 2*EPS]);
}

// --- restore the inner-top rim chamfer where the LOWERED dividers meet the +x (clip) end wall.
//     The box chamfer is interrupted at those junctions (the divider fills the inner side before
//     it is lowered), leaving a full-height bulge once lowered. The -x/hinge side is already
//     handled by the continuous journal chamfer; this does the same at the +x end.
module div_chamfer_fix() {
    cz = BODY_H - CHAMFER;            // 57, chamfer base
    xf = TOTAL_LEN - END_WALL;        // 202, +x clip-wall inner face
    for (yb = [DIV_KF, DIV_FS])
        translate([0, yb[0] - EPS, 0]) rotate([90,0,0]) translate([0,0,-((yb[1]-yb[0])+2*EPS)]) linear_extrude((yb[1]-yb[0])+2*EPS)
            polygon([[xf, cz], [xf - EPS, BODY_H + EPS], [xf + CHAMFER, BODY_H + EPS]]);  // bevel toward the wall (x>202)
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
  union() {                                               // + corner key (added after the cuts)
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(-1, AB_SEAM, KNIFE_Y0 - 1, KNIFE_Y1);
                    ab_key(YC_OUTL); ab_key(YC_DIVKF); ch_key(SEAM_KF, ENDC_A);
                    ab_cap(YC_OUTL); div_cap(YC_DIVKF); ch_cap(SEAM_KF, ENDC_A);  // hide tops (divider uses LOWERED hat)
                }
            }
            intersection() { lid_ledge(); cell(-1, AB_SEAM, KNIFE_Y0 - 1, KNIFE_Y1); }  // lid support ledge
        }
        ab_pocket(AB_SEAM, KNIFE_Y0, KNIFE_Y1);   // receive knife_B's A/B wedge (ramped lap)
        fs_pocket(SEAM_KF, 0, AB_SEAM);           // receive fork_A's 45-deg wedge (ramped lap)
        hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();   // lid cuts (groove hits A pieces; divider/scallop where present)
    }
    corner_key(AB_SEAM, LAP_LEN, SEAM_KF - LAP_LEN, SEAM_KF);  // solid full-height corner under the knife/fork divider
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
                    ch_cap(SEAM_KF, ENDC_B);                // hide top (male, chamber)
                }
            }
            ab_wedge(AB_SEAM, KNIFE_Y0, KNIFE_Y1 - LAP_LEN);  // A/B wedge -> knife_A (CLIPPED at y=81 crossing)
            intersection() { lid_ledge(); cell(AB_SEAM, TOTAL_LEN + 1, KNIFE_Y0 - 1, KNIFE_Y1); }  // lid support ledge
        }
        ab_socket(YC_OUTL); ab_socket(YC_DIVKF);
        ab_cap_neg(YC_OUTL); div_cap_neg(YC_DIVKF);      // top recesses to receive knife_A's caps (divider = LOWERED hat)
        fs_pocket(SEAM_KF, AB_SEAM, TOTAL_LEN);         // receive fork_B's 45-deg wedge (ramped lap)
        hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();   // lid cuts
    }
}

module fork_A() {
  union() {                                               // + corner key (added after the cuts)
    difference() {
        union() {
            intersection() {
                box();
                union() {
                    cell(-1, AB_SEAM, FORK_Y0 + SEAM_EPS, FORK_Y1);  // -Y cut nudged off the divider face
                    ab_key(YC_DIVFS); ch_key(SEAM_FS, ENDC_A);
                    div_cap(YC_DIVFS); ch_cap(SEAM_FS, ENDC_A);       // hide tops (divider uses LOWERED hat)
                }
            }
            fs_wedge(SEAM_KF, 0, AB_SEAM - CORNER_CLIP);  // 45-deg wedge -> knife_A, CLIPPED (knife_A owns the crossing as a solid corner)
            intersection() { lid_ledge(); cell(-1, AB_SEAM, FORK_Y0 + SEAM_EPS, FORK_Y1); }  // lid support ledge (none in fork-A)
        }
        ab_pocket(AB_SEAM, FORK_Y0, FORK_Y1);           // receive fork_B's A/B wedge (ramped lap)
        ch_socket(SEAM_KF, ENDC_A);
        ch_cap_neg(SEAM_KF, ENDC_A);                    // top recess to receive knife_A's chamber cap (female)
        fs_pocket(SEAM_FS, 0, AB_SEAM);                 // receive spoon_A's 45-deg wedge (ramped lap)
        hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();   // lid cuts (groove = fork-A hinge segment; divider = DIV_FS)
    }
    corner_key(AB_SEAM, LAP_LEN, SEAM_FS - LAP_LEN_FS, SEAM_FS);  // solid full-height corner under the fork/spoon divider
  }
}

module fork_B() {
    union() {
        difference() {
            union() {
                intersection() {
                    box();
                    union() {
                        cell(AB_SEAM, TOTAL_LEN + 1, FORK_Y0 + SEAM_EPS, FORK_Y1);  // -Y cut nudged off the divider face
                        ch_key(SEAM_FS, ENDC_B);
                        ch_cap(SEAM_FS, ENDC_B);                // hide top (male, chamber)
                    }
                }
                ab_wedge(AB_SEAM, FORK_Y0, FORK_Y1 - LAP_LEN_FS); // A/B wedge -> fork_A (CLIPPED at y=186 crossing)
                fs_wedge(SEAM_KF, AB_SEAM, TOTAL_LEN);   // 45-deg wedge -> knife_B (ramped lap)
                intersection() { lid_ledge(); cell(AB_SEAM, TOTAL_LEN + 1, FORK_Y0 + SEAM_EPS, FORK_Y1); }  // lid ledge (clip-end run)
            }
            ab_socket(YC_DIVFS);
            div_cap_neg(YC_DIVFS);                           // top recess to receive fork_A's A/B cap (divider = LOWERED hat)
            ch_socket(SEAM_KF, ENDC_B);
            ch_cap_neg(SEAM_KF, ENDC_B);                    // top recess to receive knife_B's chamber cap (female)
            fs_pocket(SEAM_FS, AB_SEAM, TOTAL_LEN);     // receive spoon_B's 45-deg wedge (ramped lap)
            hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();     // lid cuts (scallop lands here)
        }
        intersection() { lid_clip(); cell(AB_SEAM, TOTAL_LEN + 1, FORK_Y0 + SEAM_EPS, FORK_Y1); }  // retaining clip, added AFTER the scallop cut
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
                    ab_cap(YC_OUTR);                        // hide top (male)
                }
            }
            fs_wedge(SEAM_FS, 0, AB_SEAM - CORNER_CLIP);  // 45-deg wedge -> fork_A, CLIPPED (fork_A owns the crossing as a solid corner)
            intersection() { lid_ledge(); cell(-1, AB_SEAM, SPOON_Y0 + SEAM_EPS, SPOON_Y1 + 1); }  // lid support ledge (OUTER_R run)
        }
        ab_pocket(AB_SEAM, SPOON_Y0, SPOON_Y1);         // receive spoon_B's A/B wedge (ramped lap)
        ch_socket(SEAM_FS, ENDC_A);
        ch_cap_neg(SEAM_FS, ENDC_A);                    // top recess to receive fork_A's chamber cap (female)
        hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();   // lid cuts (groove = spoon-A hinge segment)
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
            ab_wedge(AB_SEAM, SPOON_Y0, SPOON_Y1);      // A/B wedge -> spoon_A (ramped lap)
            fs_wedge(SEAM_FS, AB_SEAM, TOTAL_LEN);        // 45-deg wedge -> fork_B (ramped lap)
            intersection() { lid_ledge(); cell(AB_SEAM, TOTAL_LEN + 1, SPOON_Y0 + SEAM_EPS, SPOON_Y1 + 1); }  // lid ledge (OUTER_R + clip-end runs)
        }
        ab_socket(YC_OUTR);
        ab_cap_neg(YC_OUTR);                            // top recess to receive spoon_A's A/B cap (female)
        ch_socket(SEAM_FS, ENDC_B);
        ch_cap_neg(SEAM_FS, ENDC_B);                    // top recess to receive fork_B's chamber cap (female)
        hinge_groove(); divider_lower(); lid_finger_notch(); div_chamfer_fix();   // lid cuts
    }
}

// TRUE assembled view: the six real, separable pieces in their assembled positions
// (slower to render — many booleans — but this is what actually shows the seams, the
// lowered dividers, the hinge journal, the clip, the scallop, and all the joints).
// For a fast no-cuts preview of just the outer shell, temporarily use box(); instead.
module assembly() {
    knife_A(); knife_B(); fork_A(); fork_B(); spoon_A(); spoon_B();
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
