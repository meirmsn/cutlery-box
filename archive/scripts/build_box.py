#!/usr/bin/env python3
"""
Parametric graduated 3-chamber disposable-cutlery box  (Option 3)
for a 120 x 120 x 120 mm printer.

DESIGN
------
One connected box, three OPEN graduated chambers — knife, fork, spoon —
separated by SHARED single dividers (maximum interior space). Each chamber is a
single open bay (cutlery settles into ~3 columns on its own; no sub-dividers).

Tiled into bed-sized pieces:
    * 3 chambers across the width  (knife / fork / spoon)
    * 2 halves along the length    (A = near, B = far)   => 6 body pieces.

ALL JOINTS ARE FLUSH, HIDDEN, VERTICAL SLIDING DOVETAILS embedded inside the
walls — nothing protrudes from an exterior face and nothing sits in a bay:

  * A/B halves join across the mid seam via dovetails embedded in the four
    thick LENGTHWISE walls (the two outer walls + the two shared dividers).
  * Chamber-to-chamber joins happen the SAME way, but across the chamber
    boundary, with the dovetail embedded inside the thick END walls.

Both kinds of wall are thickened to HOST_T so the dovetail fits entirely within
the wall. Assemble by lowering pieces straight down.

Geometry = axis-aligned boxes + trapezoidal vertical prisms; overlapping closed
solids are unioned by the slicer (no CSG). Output: binary STL. Std-lib only.
"""
import struct, math, os

# ============================================================ parameters (mm)
BASE      = 3.0      # floor thickness
COMP_H    = 55.0     # interior height (cutlery stack depth)
HALF_LEN  = 104.0    # printed length of each half (<120 incl. dovetail)
HOST_T    = 6.0      # thickness of every dovetail-hosting wall (outer + divider + end)
END_WALL  = HOST_T   # end walls are hosts too, so equally thick
BODY_H    = BASE + COMP_H                       # 58.0

# Each chamber is an open bay of width = N_COL * col, sized so 3 real columns
# fit with a little play.  Column = measured cutlery width + play.
#   knife 19 + 4,  fork 29 + 4,  spoon 34 + 3 (spoon trimmed to keep piece <119)
N_COL     = 3
CHAMBERS = [
    {"name": "knife", "col": 23.0},   # bay 69 mm  (3 x 19 mm knives + ~12 play)
    {"name": "fork",  "col": 33.0},   # bay 99 mm  (3 x 29 mm forks  + ~12 play)
    {"name": "spoon", "col": 37.0},   # bay 111 mm (3 x 34 mm spoons + ~9 play)
]

# ----- dovetail profile (shared by both joint directions) ------------------
DT_DEPTH  = 5.0      # protrusion past the seam
DT_NECK   = 1.2      # half-width at the seam face (narrow)
DT_FLARE  = 2.1      # half-width at the tip (wide -> locks)
DT_CLR    = 0.4      # clearance on the female socket

# ----- comfort chamfer on the top rim (the edges you handle) ---------------
CHAMFER   = 1.0      # 45-deg comfort break on the top wall edges
JOINT_CHAMF = 0.5    # smaller break on the small dovetail tops at the rim

# ----- male dovetail "hat" (knife A/B joints only) -------------------------
# The "hat" is achieved by letting the wall's comfort chamfer FLOW CONTINUOUSLY
# over the top of the male A/B key (instead of leaving the key flat-topped).
# Visually the wall's chamfered top extends out across the dovetail, so the rim
# reads as one continuous edge that runs onto the key. The female (knife B) is
# left exactly as a normal chamfered wall — its rim chamfer is untouched — and
# the male key still slides straight down into the unchanged female socket.

# ============================================================ mesh helpers
def signed_area(poly):
    s = 0.0
    for i in range(len(poly)):
        x0, y0 = poly[i]; x1, y1 = poly[(i + 1) % len(poly)]
        s += x0 * y1 - x1 * y0
    return 0.5 * s

def ccw(poly):
    return poly if signed_area(poly) > 0 else poly[::-1]

def inset_convex(poly, c):
    """Inset a convex polygon inward by c (offset every edge, re-intersect)."""
    p = ccw([tuple(v) for v in poly]); n = len(p); offs = []
    for i in range(n):
        x0, y0 = p[i]; x1, y1 = p[(i+1) % n]
        dx, dy = x1-x0, y1-y0; L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy/L, dx/L                      # inward normal (CCW)
        offs.append((x0+nx*c, y0+ny*c, dx, dy))
    out = []
    for i in range(n):
        ax, ay, adx, ady = offs[(i-1) % n]
        bx, by, bdx, bdy = offs[i]
        den = adx*bdy - ady*bdx
        if abs(den) < 1e-9:
            out.append((bx, by))
        else:
            t = ((bx-ax)*bdy - (by-ay)*bdx) / den
            out.append((ax+adx*t, ay+ady*t))
    return out

def merge_collinear(poly):
    """Drop vertices that lie on a straight line between their neighbours."""
    n = len(poly); out = []
    for i in range(n):
        a, b, c = poly[(i-1) % n], poly[i], poly[(i+1) % n]
        cr = (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])
        if abs(cr) > 1e-7:
            out.append(b)
    return out

def rect_union_outline(rects):
    """CCW outline polygon of a union of axis-aligned rectangles
       (rects = (x0,x1,y0,y1)), assuming a simple connected region."""
    def covered(cx, cy):
        return any(x0 < cx < x1 and y0 < cy < y1 for (x0,x1,y0,y1) in rects)
    xs = sorted(set([r[0] for r in rects] + [r[1] for r in rects]))
    ys = sorted(set([r[2] for r in rects] + [r[3] for r in rects]))
    from collections import defaultdict
    cnt = defaultdict(int)
    for i in range(len(xs)-1):
        for j in range(len(ys)-1):
            cx = (xs[i]+xs[i+1])/2.0; cy = (ys[j]+ys[j+1])/2.0
            if not covered(cx, cy): continue
            x0, x1, y0, y1 = xs[i], xs[i+1], ys[j], ys[j+1]
            for a, b in (((x0,y0),(x1,y0)), ((x1,y0),(x1,y1)),
                         ((x1,y1),(x0,y1)), ((x0,y1),(x0,y0))):
                cnt[(a, b)] += 1
    nxt = {a: b for (a, b) in cnt if cnt.get((b, a), 0) == 0}
    if not nxt: return []
    start = next(iter(nxt)); poly = [start]; cur = nxt[start]
    guard = 0
    while cur != start and cur in nxt and guard < 100000:
        poly.append(cur); cur = nxt[cur]; guard += 1
    return ccw(merge_collinear(poly))

def ear_clip(poly):
    """Triangulate a simple CCW polygon by ear clipping -> list of (i,j,k)."""
    p = ccw([tuple(v) for v in poly]); idx = list(range(len(p))); tris = []
    def cross(a, b, c): return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])
    def in_tri(q, a, b, c):
        d1 = cross(q,a,b); d2 = cross(q,b,c); d3 = cross(q,c,a)
        return not (((d1<0) or (d2<0) or (d3<0)) and ((d1>0) or (d2>0) or (d3>0)))
    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1; m = len(idx); cut = False
        for ii in range(m):
            i0, i1, i2 = idx[(ii-1) % m], idx[ii], idx[(ii+1) % m]
            a, b, c = p[i0], p[i1], p[i2]
            if cross(a, b, c) <= 1e-9: continue          # reflex/degenerate
            if any(jj not in (i0,i1,i2) and in_tri(p[jj], a, b, c) for jj in idx):
                continue
            tris.append((i0, i1, i2)); idx.pop(ii); cut = True; break
        if not cut: break
    if len(idx) == 3: tris.append((idx[0], idx[1], idx[2]))
    return p, tris

def tri_normal(a, b, c):
    ux, uy, uz = b[0]-a[0], b[1]-a[1], b[2]-a[2]
    vx, vy, vz = c[0]-a[0], c[1]-a[1], c[2]-a[2]
    nx, ny, nz = uy*vz-uz*vy, uz*vx-ux*vz, ux*vy-uy*vx
    L = math.sqrt(nx*nx+ny*ny+nz*nz) or 1.0
    return (nx/L, ny/L, nz/L)

class Mesh:
    def __init__(self): self.tris = []
    def add_tri(self, a, b, c): self.tris.append((a, b, c))

    def prism(self, poly2d, z0, z1):
        poly = ccw([tuple(p) for p in poly2d]); n = len(poly)
        bot = [(x, y, z0) for (x, y) in poly]
        top = [(x, y, z1) for (x, y) in poly]
        for i in range(1, n-1): self.add_tri(top[0], top[i], top[i+1])
        for i in range(1, n-1): self.add_tri(bot[0], bot[i+1], bot[i])
        for i in range(n):
            j = (i+1) % n
            self.add_tri(bot[i], bot[j], top[j]); self.add_tri(bot[i], top[j], top[i])

    def box(self, x0, x1, y0, y1, z0, z1):
        if x1 <= x0 or y1 <= y0 or z1 <= z0: return
        self.prism([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], z0, z1)

    def _emit_oriented(self, tris):
        """Append triangles to the soup, flipping each so its normal points away
           from the solid's centroid (correct outward normals for a convex part)."""
        pts = [v for t in tris for v in t]
        if not pts: return
        k = len(pts)
        cx = sum(p[0] for p in pts)/k; cy = sum(p[1] for p in pts)/k; cz = sum(p[2] for p in pts)/k
        for a, b, c in tris:
            nx, ny, nz = tri_normal(a, b, c)
            mx = (a[0]+b[0]+c[0])/3.0 - cx
            my = (a[1]+b[1]+c[1])/3.0 - cy
            mz = (a[2]+b[2]+c[2])/3.0 - cz
            if nx*mx + ny*my + nz*mz < 0:
                self.tris.append((a, c, b))
            else:
                self.tris.append((a, b, c))

    def extrude(self, poly2d, lo, hi, axis):
        """Extrude a 2D polygon along `axis` from lo to hi (outward normals).
           axis 'z': poly is (x,y); 'x': poly is (y,z); 'y': poly is (x,z)."""
        def to3d(p, t):
            a, b = p
            if axis == 'z': return (a, b, t)
            if axis == 'x': return (t, a, b)
            return (a, t, b)
        poly = [tuple(p) for p in poly2d]; n = len(poly)
        bot = [to3d(p, lo) for p in poly]; top = [to3d(p, hi) for p in poly]
        tris = []
        for i in range(1, n-1):
            tris.append((top[0], top[i], top[i+1]))
            tris.append((bot[0], bot[i+1], bot[i]))
        for i in range(n):
            j = (i+1) % n
            tris.append((bot[i], bot[j], top[j])); tris.append((bot[i], top[j], top[i]))
        self._emit_oriented(tris)

    def prism_chamf_top(self, poly2d, z0, z1, c):
        """Vertical prism with a 45-deg chamfer broken all around its top edge.
           Shrinks the bevel for thin features; gives up only if it can't fit."""
        poly = ccw([tuple(p) for p in poly2d])
        a0 = signed_area(poly)
        cc = None
        for trial in (c, c*0.6, c*0.35):
            ins = inset_convex(poly, trial)
            if signed_area(ins) > 0.18 * a0:
                cc = trial; break
        n = len(poly); tris = []
        if cc is None:                              # too thin: plain prism
            bot = [(x, y, z0) for (x, y) in poly]; top = [(x, y, z1) for (x, y) in poly]
            for i in range(1, n-1):
                tris.append((top[0], top[i], top[i+1])); tris.append((bot[0], bot[i+1], bot[i]))
            for i in range(n):
                j = (i+1) % n
                tris.append((bot[i], bot[j], top[j])); tris.append((bot[i], top[j], top[i]))
            self._emit_oriented(tris); return
        bz = z1 - cc
        bot = [(x, y, z0) for (x, y) in poly]
        mid = [(x, y, bz) for (x, y) in poly]
        topi = [(x, y, z1) for (x, y) in ins]
        for i in range(1, n-1):                     # bottom face
            tris.append((bot[0], bot[i+1], bot[i]))
        for i in range(n):                          # straight sides
            j = (i+1) % n
            tris.append((bot[i], bot[j], mid[j])); tris.append((bot[i], mid[j], mid[i]))
        for i in range(n):                          # bevel skirt
            j = (i+1) % n
            tris.append((mid[i], mid[j], topi[j])); tris.append((mid[i], topi[j], topi[i]))
        for i in range(1, n-1):                     # top face
            tris.append((topi[0], topi[i], topi[i+1]))
        self._emit_oriented(tris)

    def prism_partial_chamf(self, poly2d, z0, z1, c, axis_idx, face):
        """Convex prism whose top edges are chamfered ONLY where an edge lies on
           the line {coord[axis_idx] == face} (the wall-face side). Other edges
           rise straight to z1. Used so a dovetail socket inherits the wall's
           face chamfer and stays flat across the cut."""
        poly = ccw([tuple(p) for p in poly2d]); n = len(poly); offs = []
        for i in range(n):
            x0, y0 = poly[i]; x1, y1 = poly[(i+1) % n]
            dx, dy = x1-x0, y1-y0; Ln = math.hypot(dx, dy) or 1.0
            nx, ny = -dy/Ln, dx/Ln
            mid = ((x0+x1)/2.0, (y0+y1)/2.0)
            ci = c if abs(mid[axis_idx] - face) < 0.05 else 0.0
            offs.append((x0+nx*ci, y0+ny*ci, dx, dy))
        ins = []
        for i in range(n):
            ax, ay, adx, ady = offs[(i-1) % n]; bx, by, bdx, bdy = offs[i]
            den = adx*bdy - ady*bdx
            if abs(den) < 1e-9: ins.append((bx, by))
            else:
                t = ((bx-ax)*bdy - (by-ay)*bdx) / den
                ins.append((ax+adx*t, ay+ady*t))
        zm = z1 - c
        bot = [(x, y, z0) for (x, y) in poly]
        mid_ = [(x, y, zm) for (x, y) in poly]
        topi = [(x, y, z1) for (x, y) in ins]
        tris = []
        for i in range(1, n-1): tris.append((bot[0], bot[i+1], bot[i]))
        for i in range(n):
            j = (i+1) % n
            tris.append((bot[i], bot[j], mid_[j])); tris.append((bot[i], mid_[j], mid_[i]))
        for i in range(n):
            j = (i+1) % n
            tris.append((mid_[i], mid_[j], topi[j])); tris.append((mid_[i], topi[j], topi[i]))
        for i in range(1, n-1): tris.append((topi[0], topi[i], topi[i+1]))
        self._emit_oriented(tris)

    def write_stl(self, path):
        with open(path, "wb") as f:
            f.write(b"\0" * 80); f.write(struct.pack("<I", len(self.tris)))
            for a, b, c in self.tris:
                f.write(struct.pack("<3f", *tri_normal(a, b, c)))
                for v in (a, b, c): f.write(struct.pack("<3f", *v))
                f.write(struct.pack("<H", 0))

    def bounds(self):
        xs = [v[0] for t in self.tris for v in t]
        ys = [v[1] for t in self.tris for v in t]
        zs = [v[2] for t in self.tris for v in t]
        return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))

def interval_complement(lo, hi, holes):
    out, cur = [], lo
    for a, b in sorted(holes):
        if a > cur: out.append((cur, a))
        cur = max(cur, b)
    if cur < hi: out.append((cur, hi))
    return out

def chamf_wall(m, x0, x1, y0, y1, c=CHAMFER, z0=BASE, z1=BODY_H):
    """A wall box with a 45-deg chamfer broken along its top rim, on the two
       long faces (the faces you'd run a finger along). Auto-detects the run
       direction; the floor-side and ends stay square."""
    lx, ly = x1 - x0, y1 - y0
    cc = min(c, 0.49 * min(lx, ly))
    if lx >= ly:                                   # runs along X -> taper in Y
        poly = [(y0, z0), (y1, z0), (y1, z1-cc), (y1-cc, z1), (y0+cc, z1), (y0, z1-cc)]
        m.extrude(poly, x0, x1, 'x')
    else:                                          # runs along Y -> taper in X
        poly = [(x0, z0), (x1, z0), (x1, z1-cc), (x1-cc, z1), (x0+cc, z1), (x0, z1-cc)]
        m.extrude(poly, y0, y1, 'y')

def outline_walls(m, poly2d, z0, z1, c, square_lines=(), square_pred=None):
    """Extrude a wall OUTLINE polygon with a 45-deg chamfer broken continuously
       around its top rim (inner + outer), mitred at every corner. Edges on a
       `square_lines` entry ((axis,value)) — or for which `square_pred(p0,p1)` is
       True — rise straight (no chamfer), so dovetail keys stay flat-topped and
       slots stay vertical. Where a straight rim edge changes from chamfered to
       square (e.g. entering a slot's wall sliver) the two segments are collinear
       and their inset lines are parallel; that transition is closed with an
       explicit vertical STEP so the top face stays watertight."""
    poly, _ = ear_clip(poly2d)        # CCW-normalised vertices
    n = len(poly); zm = z1 - c
    edir = []; enrm = []; cof = []
    for i in range(n):
        a = poly[i]; b = poly[(i+1) % n]
        dx, dy = b[0]-a[0], b[1]-a[1]; Ln = math.hypot(dx, dy) or 1.0
        edir.append((dx/Ln, dy/Ln)); enrm.append((-dy/Ln, dx/Ln))
        keep_sq = any((ax == 0 and abs(a[0]-v) < 0.05 and abs(b[0]-v) < 0.05) or
                      (ax == 1 and abs(a[1]-v) < 0.05 and abs(b[1]-v) < 0.05)
                      for (ax, v) in square_lines)
        if not keep_sq and square_pred is not None:
            keep_sq = square_pred(a, b)
        cof.append(0.0 if keep_sq else c)
    def opt(i, vtx):                  # offset point of edge i evaluated at polygon vertex vtx
        return (poly[vtx][0] + enrm[i][0]*cof[i], poly[vtx][1] + enrm[i][1]*cof[i])
    def isect(i, j):                  # intersect the two offset lines (edge i then edge j)
        ax, ay = opt(i, i); adx, ady = edir[i]
        bx, by = opt(j, j); bdx, bdy = edir[j]
        den = adx*bdy - ady*bdx
        if abs(den) < 1e-9: return None
        t = ((bx-ax)*bdy - (by-ay)*bdx) / den
        return (ax+adx*t, ay+ady*t)
    sIns = [None]*n; eIns = [None]*n  # inset endpoints of each edge (start at vtx i, end at vtx i+1)
    top = []; steps = []
    for v in range(n):
        ep = (v-1) % n; ec = v
        P = isect(ep, ec)
        if P is not None:
            eIns[ep] = P; sIns[ec] = P; top.append(P)
        else:                         # parallel inset lines at this vertex
            a = opt(ep, v); b = opt(ec, v)
            if math.hypot(a[0]-b[0], a[1]-b[1]) < 1e-6:   # coincident -> single point
                eIns[ep] = a; sIns[ec] = a; top.append(a)
            else:                                          # genuine step (chamfer<->square)
                eIns[ep] = a; sIns[ec] = b; top.append(a); top.append(b)
                steps.append((v, a, b))
    ptop, top_tris = ear_clip(top)
    _, base_tris = ear_clip(poly)
    for (i, j, k) in base_tris:        # bottom face (-Z)
        m.add_tri((poly[i][0], poly[i][1], z0), (poly[k][0], poly[k][1], z0), (poly[j][0], poly[j][1], z0))
    for i in range(n):                 # straight sides z0..zm
        j = (i+1) % n
        b0 = (poly[i][0], poly[i][1], z0); b1 = (poly[j][0], poly[j][1], z0)
        mm0 = (poly[i][0], poly[i][1], zm); mm1 = (poly[j][0], poly[j][1], zm)
        m.add_tri(b0, b1, mm1); m.add_tri(b0, mm1, mm0)
    for i in range(n):                 # bevel skirt zm..z1 (per edge, to its own inset endpoints)
        j = (i+1) % n
        mm0 = (poly[i][0], poly[i][1], zm); mm1 = (poly[j][0], poly[j][1], zm)
        t0 = (sIns[i][0], sIns[i][1], z1); t1 = (eIns[i][0], eIns[i][1], z1)
        m.add_tri(mm0, mm1, t1); m.add_tri(mm0, t1, t0)
    for (v, a, b) in steps:            # vertical step face closing chamfer<->square transitions
        vp = (poly[v][0], poly[v][1], zm)
        m.add_tri(vp, (a[0], a[1], z1), (b[0], b[1], z1))
    for (i, j, k) in top_tris:         # top face (+Z)
        m.add_tri((ptop[i][0], ptop[i][1], z1), (ptop[j][0], ptop[j][1], z1), (ptop[k][0], ptop[k][1], z1))

def floor_with_notches(m, x0, x1, y0, y1, notches):
    """Floor over [x0,x1]x[y0,y1], minus rectangular notches (where incoming
       male tabs land). Notches are (nx0,nx1,ny0,ny1)."""
    xs = sorted(set([x0, x1] + [v for n in notches for v in (n[0], n[1])]))
    xs = [x for x in xs if x0 - 1e-9 <= x <= x1 + 1e-9]
    for i in range(len(xs) - 1):
        sx0, sx1 = xs[i], xs[i+1]
        if sx1 - sx0 < 1e-6: continue
        holes = [(ny0, ny1) for (nx0, nx1, ny0, ny1) in notches
                 if nx0 <= sx0 + 1e-9 and nx1 >= sx1 - 1e-9]
        for (a, b) in interval_complement(y0, y1, holes):
            m.box(sx0, sx1, a, b, 0, BASE)

# ============================================================ Y-axis layout
def build_layout():
    y = 0.0; layout = []
    for ci, ch in enumerate(CHAMBERS):
        left_is_outer  = (ci == 0)
        right_is_outer = (ci == len(CHAMBERS) - 1)
        piece_y0 = y
        hosts = []
        if left_is_outer:
            hosts.append(y + HOST_T/2.0); y += HOST_T          # outer-left wall
        bay_w = N_COL * ch["col"]
        cav = (y, y + bay_w); y += bay_w
        right_wall = (y, y + HOST_T)
        hosts.append(y + HOST_T/2.0); y += HOST_T              # divider / outer-right
        piece_y1 = y
        layout.append({
            "name": ch["name"], "ci": ci,
            "left_is_outer": left_is_outer, "right_is_outer": right_is_outer,
            "y0": piece_y0, "y1": piece_y1,
            "cav": cav, "right_wall": right_wall, "hosts": hosts,
        })
    return layout, y

LAYOUT, EXT_W = build_layout()

# ============================================================ dovetail features
# Dovetails are SPLICED into the single wall outline (not added as separate
# overlapping/abutting solids). That way the keys and slots are part of the same
# manifold as the wall, so a CAD viewer shows them as solid, connected wall —
# no detached-looking tabs and no z-fighting twist at the seams.
def dovetail_path(seam, center, axis, neck, flare, depth, clr=0.0):
    """Vertices of a dovetail feature on the seam line {coord[axis]==seam},
       centred at `center`, running +depth off the seam. Male: clr=0 (a key that
       protrudes past the seam). Female: clr=DT_CLR (a slot cut into the wall,
       opening widened for fit). Narrow at the seam (neck), wide at depth (flare)
       — the locking undercut. Returned lowest-transverse-first."""
    n, f = neck + clr, flare + clr
    s2 = seam + depth
    if axis == 0:                       # seam x=const, transverse y
        return [(seam, center - n), (s2, center - f),
                (s2, center + f), (seam, center + n)]
    return [(center - n, seam), (center - f, s2),     # seam y=const, transverse x
            (center + f, s2), (center + n, seam)]

def splice_feature(poly, seam, center, axis, half_open, path):
    """Replace the slice of the outline edge lying on {coord[axis]==seam} that
       brackets [center-half_open, center+half_open] with `path`, keeping the
       outline one clean loop. `path` is inserted in the edge's travel order."""
    tr = 1 - axis; n = len(poly); out = []; done = False
    for i in range(n):
        p = poly[i]; q = poly[(i + 1) % n]; out.append(p)
        if (not done and abs(p[axis]-seam) < 1e-6 and abs(q[axis]-seam) < 1e-6
                and min(p[tr], q[tr]) - 1e-6 <= center - half_open
                and center + half_open <= max(p[tr], q[tr]) + 1e-6):
            out.extend(path if q[tr] > p[tr] else path[::-1]); done = True
    return out, done

def insert_cut(poly, axis, cval):
    """Split every edge that strictly crosses the line {coord[axis]==cval},
       inserting the crossing point. Lets a long rim edge be split so its
       near-slot STRIP can be marked square (no chamfer) on its own."""
    out = []; n = len(poly)
    for i in range(n):
        p = poly[i]; q = poly[(i + 1) % n]; out.append(p)
        d = q[axis] - p[axis]
        if abs(d) > 1e-9:
            t = (cval - p[axis]) / d
            if 1e-6 < t < 1 - 1e-6:
                out.append((p[0] + t*(q[0]-p[0]), p[1] + t*(q[1]-p[1])))
    return out

# ============================================================ rim-chamfer predicate
def make_is_square(square_mid, seam_lines, fz):
    """Build the rim-edge predicate used by outline_walls: an edge stays SQUARE
       (no comfort chamfer) if it is a dovetail edge, lies on a seam/mating face,
       or sits inside a female sliver zone."""
    def is_square(p, q):
        mid = ((p[0]+q[0])/2.0, (p[1]+q[1])/2.0)
        if (round(mid[0], 2), round(mid[1], 2)) in square_mid:
            return True
        for ax, val in seam_lines:
            if abs(p[ax]-val) < 0.05 and abs(q[ax]-val) < 0.05:
                return True
        for ax, lo, hi in fz:
            if lo - 0.01 <= mid[ax] <= hi + 0.01:
                return True
        return False
    return is_square

# ============================================================ build one body piece
def build_body(ci, half, hat_ab=False):
    """One printable piece: a solid floor plate plus a continuous wall outline
       with every dovetail spliced straight into it — males as protruding keys,
       females as vertical trapezoidal slots cut to plate level. The rim chamfer
       is broken continuously around the top; seam faces and all dovetail edges
       stay square.

       When hat_ab is set (knife A/B), the male A/B key is NOT marked square, so the
       comfort chamfer flows continuously over the top of the key — the wall's
       chamfered top reads as if it extends out across the dovetail (the "hat").
       The female (knife B) is unchanged: its socket and full rim chamfer are
       identical to a standard wall, and the male key still slides straight down
       into it (the chamfer only removes material from the key's very top)."""
    L = LAYOUT[ci]; m = Mesh()
    y0, y1 = L["y0"], L["y1"]; hosts = L["hosts"]
    left_conn  = not L["left_is_outer"]          # hosts a chamber FEMALE on its left
    right_conn = not L["right_is_outer"]         # hosts a chamber MALE on its right
    y_male = L["right_wall"][1]                   # chamber male protrudes +Y from here
    rw0, rw1 = L["right_wall"]
    ex0, ex1 = (0.0, END_WALL) if half == "A" else (HALF_LEN - END_WALL, HALF_LEN)
    exc = (ex0 + ex1) / 2.0
    ab_seam = HALF_LEN if half == "A" else 0.0    # A/B mating face

    # NOTE: an earlier "hat" attempt let the rim chamfer run over the male A/B key
    # (chamfer_male_ab). That broke the outer-wall chamfer miter — the key sits on
    # the SQUARE mating seam and the chamfer engine cannot miter cleanly around a
    # protruding key on a square edge. Reverted: the male key is flat-topped/square
    # like every other piece, so the outer wall keeps a clean continuous chamfer.
    chamfer_male_ab = False

    # ---- solid floor plate ----
    m.box(0.0, HALF_LEN, y0, y1, 0.0, BASE)

    # ---- wall rectangles, full extent to the seams, unioned to one outline ----
    wlo, whi = (END_WALL, HALF_LEN) if half == "A" else (0.0, HALF_LEN - END_WALL)
    rects = [(ex0, ex1, y0, y1)]                  # end wall
    if L["left_is_outer"]:
        rects.append((wlo, whi, y0, y0 + HOST_T)) # outer-left lengthwise wall
    rects.append((wlo, whi, rw0, rw1))            # divider / outer-right wall
    poly = rect_union_outline(rects)

    # ---- splice every dovetail into that one outline ----
    square_mid = set()                            # midpoints of dovetail edges kept square
    def mark(path):
        for k in range(len(path) - 1):
            square_mid.add((round((path[k][0]+path[k+1][0])/2.0, 2),
                            round((path[k][1]+path[k+1][1])/2.0, 2)))

    for yc in hosts:                              # A/B joint in each lengthwise wall
        clr = 0.0 if half == "A" else DT_CLR
        path = dovetail_path(ab_seam, yc, 0, DT_NECK, DT_FLARE, DT_DEPTH, clr)
        poly, ok = splice_feature(poly, ab_seam, yc, 0, DT_NECK + clr, path)
        assert ok, f"A/B splice failed: {L['name']}_{half} y={yc}"
        if not chamfer_male_ab:                   # hat = leave the male key un-squared
            mark(path)
    if right_conn:                               # chamber male, +Y across boundary
        path = dovetail_path(y_male, exc, 1, DT_NECK, DT_FLARE, DT_DEPTH, 0.0)
        poly, ok = splice_feature(poly, y_male, exc, 1, DT_NECK, path)
        assert ok, f"chamber male splice failed: {L['name']}_{half}"
        mark(path)
    if left_conn:                                # chamber female sunk in end wall
        path = dovetail_path(y0, exc, 1, DT_NECK, DT_FLARE, DT_DEPTH, DT_CLR)
        poly, ok = splice_feature(poly, y0, exc, 1, DT_NECK + DT_CLR, path)
        assert ok, f"chamber female splice failed: {L['name']}_{half}"
        mark(path)

    # ---- square the rim ONLY in the thin sliver a FEMALE slot leaves ----
    zdep = DT_DEPTH + 1.0
    fz = []                                       # female sliver zones (axis, lo, hi)
    if half == "B":                               # A/B females on the lengthwise walls
        fz.append((0, 0.0, zdep)); poly = insert_cut(poly, 0, zdep)
    if left_conn:                                 # chamber female in the end wall
        fz.append((1, y0, y0 + zdep)); poly = insert_cut(poly, 1, y0 + zdep)

    # ---- extrude: full rim chamfer except seam faces, female dovetails, slivers --
    seam_lines = [(0, ab_seam)]
    if right_conn: seam_lines.append((1, y_male))
    if left_conn:  seam_lines.append((1, y0))
    outline_walls(m, poly, BASE, BODY_H, CHAMFER, seam_lines,
                  make_is_square(square_mid, seam_lines, fz))
    return m

# ============================================================ assembled model
def assemble(parts):
    """ACCURATE assembled model: the six real part meshes dropped into their
    in-use positions — B halves shifted one half-length in +X, chambers already
    carrying their global Y. Every male tab sits inside its mating socket exactly
    as printed (with the real DT_CLR clearance), so the seams and joints can be
    inspected for fit. This is the true geometry, not an idealised solid."""
    asm = Mesh()
    for name, mesh in parts.items():
        dx = 0.0 if name.endswith("_A.stl") else HALF_LEN
        for (a, b, c) in mesh.tris:
            asm.tris.append(((a[0]+dx, a[1], a[2]),
                             (b[0]+dx, b[1], b[2]),
                             (c[0]+dx, c[1], c[2])))
    return asm

# ============================================================ run
if __name__ == "__main__":
    outdir = os.path.dirname(os.path.abspath(__file__))
    parts = {}
    for L in LAYOUT:
        for half in ("A", "B"):
            parts[f"body_{L['name']}_{half}.stl"] = build_body(
                L["ci"], half, hat_ab=(L["name"] == "knife"))

    print("BUILD VOLUME LIMIT: 120 x 120 x 120 mm\n")
    ok = True
    for name in sorted(parts):
        m = parts[name]; m.write_stl(os.path.join(outdir, name))
        x0,x1,y0,y1,z0,z1 = m.bounds(); dx,dy,dz = x1-x0, y1-y0, z1-z0
        fits = dx<=120 and dy<=120 and dz<=120; ok = ok and fits
        print(f"{name:20s} tris={len(m.tris):5d}  {dx:6.2f} x {dy:6.2f} x {dz:6.2f} mm  {'OK' if fits else 'TOO BIG'}")

    asm = assemble(parts); asm.write_stl(os.path.join(outdir, "assembly.stl"))
    ax = asm.bounds()
    print(f"\nassembly.stl         tris={len(asm.tris):5d}  "
          f"{ax[1]-ax[0]:6.2f} x {ax[3]-ax[2]:6.2f} x {ax[5]-ax[4]:6.2f} mm  "
          f"(accurate; B shifted +{HALF_LEN:.0f} mm X)")

    interior_len = 2*HALF_LEN - 2*END_WALL
    print(f"\nAssembled: interior length {interior_len:.0f} mm, total width {EXT_W:.1f} mm")
    for L in LAYOUT:
        bw = N_COL * CHAMBERS[L['ci']]['col']
        print(f"  {L['name']:5s} chamber: {bw:.0f} mm open bay (~3 columns)")
    print("ALL PARTS FIT" if ok else "!! SOME PART EXCEEDS BUILD VOLUME")
