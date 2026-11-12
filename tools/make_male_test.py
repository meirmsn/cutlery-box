#!/usr/bin/env python3
"""
KEY #2 full-height MALE tongue test -- males only, slide into the EXISTING
printed box socket (female side is final, not reprinted).

Two tongues, both full slide height (BODY_H - BASE = 55 mm), both with the real
angled "hat" cap on top so the full fit (flanks + cap seating) is exercised:

  1 pip : key #2 as-is        (per-side clr 0.15, tongue depth 5.0 mm)
  2 pip : key #2 + 1 mm reach (tongue tip extended STRAIGHT to 6.0 mm in the
          dovetail body only; cap zone kept at 5.0 mm so the hat still seats)

Key #2 = per-side clearance 0.15 against the production socket (neck half 1.5,
flare half 2.0). Male = socket - 0.15 per side -> neck 1.35 / flare 1.85 half
(full width 2.70 / 3.70). The straight +1 mm extension keeps the flare width,
so it fits the same socket; it adds reach + a little flank friction, not a
wider undercut.
"""
import struct, math, sys

# ---- locked model geometry (cutlery_box.scad), z shifted so coupon z=0 == BASE
BASE, BODY_H, CHAMFER = 3.0, 58.0, 1.0
H = BODY_H - BASE                      # 55.0

NECK_F, FLARE_F = 1.5, 2.0             # production socket half-widths
DEPTH   = 5.0
CLR     = 0.15                         # key #2
NECK    = NECK_F - CLR                 # 1.35
FLARE   = FLARE_F - CLR                # 1.85

CAP_HW, CAP_FOOT, CAP_SLANT, CAP_CLR = 3.0, 1.2, 50.0, 0.3
CAP_RISE  = (CAP_HW - CAP_FOOT) * math.tan(math.radians(CAP_SLANT))
CAP_ZRAMP = (BODY_H - CHAMFER) - BASE  # 54.0
CAP_ZBOT  = CAP_ZRAMP - CAP_RISE       # ~51.855

WM, WY = 10.0, 8.0                     # host grip depth / half width
PIP_H  = 1.5
EXTRA  = 1.0                           # +1 mm reach for variant B

tris = []
def add(a,b,c): tris.append((a,b,c))

def add_box(x0,x1,y0,y1,z0,z1):
    p=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
       (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    def q(a,b,c,d): add(p[a],p[b],p[c]); add(p[a],p[c],p[d])
    q(0,3,2,1); q(4,5,6,7); q(0,1,5,4); q(1,2,6,5); q(2,3,7,6); q(3,0,4,7)

def signed_area(poly):
    return 0.5*sum(poly[i][0]*poly[(i+1)%len(poly)][1]-poly[(i+1)%len(poly)][0]*poly[i][1]
                   for i in range(len(poly)))

def ear_clip(poly):
    n=len(poly); idx=list(range(n))
    if signed_area(poly)<0: idx.reverse()
    cr=lambda o,a,b:(a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    def inside(p,a,b,c):
        d1,d2,d3=cr(a,b,p),cr(b,c,p),cr(c,a,p)
        return not(((d1<0)or(d2<0)or(d3<0)) and ((d1>0)or(d2>0)or(d3>0)))
    out=[]; g=0
    while len(idx)>2 and g<10000:
        g+=1; ear=False; m=len(idx)
        for k in range(m):
            i0,i1,i2=idx[(k-1)%m],idx[k],idx[(k+1)%m]
            a,b,c=poly[i0],poly[i1],poly[i2]
            if cr(a,b,c)<=0: continue
            if all(j in (i0,i1,i2) or not inside(poly[j],a,b,c) for j in idx):
                out.append((i0,i1,i2)); idx.pop(k); ear=True; break
        if not ear: break
    return out

def _area(a,b,c):
    ux,uy,uz=b[0]-a[0],b[1]-a[1],b[2]-a[2]; vx,vy,vz=c[0]-a[0],c[1]-a[1],c[2]-a[2]
    cx,cy,cz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
    return (cx*cx+cy*cy+cz*cz)**0.5

def add_safe(a,b,c):
    if _area(a,b,c) > 1e-9: add(a,b,c)

def extrude_levels(levels, ox=0.0, oy=0.0):
    """levels = [(z, poly), ...]; poly = ordered CCW verts (same count each)."""
    N=len(levels[0][1])
    for s in range(len(levels)-1):
        z0,lo=levels[s]; z1,hi=levels[s+1]
        for i in range(N):
            j=(i+1)%N
            b0=(lo[i][0]+ox,lo[i][1]+oy,z0); b1=(lo[j][0]+ox,lo[j][1]+oy,z0)
            t1=(hi[j][0]+ox,hi[j][1]+oy,z1); t0=(hi[i][0]+ox,hi[i][1]+oy,z1)
            add_safe(b0,b1,t1); add_safe(b0,t1,t0)
    bot=levels[0][1]; zb=levels[0][0]
    for (i0,i1,i2) in ear_clip(bot):
        add((bot[i0][0]+ox,bot[i0][1]+oy,zb),(bot[i2][0]+ox,bot[i2][1]+oy,zb),
            (bot[i1][0]+ox,bot[i1][1]+oy,zb))
    top=levels[-1][1]; zt=levels[-1][0]
    for (i0,i1,i2) in ear_clip(top):
        add((top[i0][0]+ox,top[i0][1]+oy,zt),(top[i1][0]+ox,top[i1][1]+oy,zt),
            (top[i2][0]+ox,top[i2][1]+oy,zt))

def extrude(prof, zs, ox=0.0, oy=0.0):
    extrude_levels([(z,prof(z)) for z in zs], ox, oy)

def lerp(a,b,t): return a+(b-a)*t

def trap(d):
    return [(0,-NECK),(d,-FLARE),(d,FLARE),(0,NECK)]

def build_male(ox, oy, extra, pips):
    # host grip
    add_box(ox-WM, ox, oy-WY, oy+WY, 0, H)
    # dovetail tongue: continuous taper to flare at the TIP.
    #   below the cap -> tip reaches DEPTH+extra (full flare only at full depth)
    #   cap zone      -> tip kept at DEPTH so the hat seats in the existing recess
    d_lo = DEPTH + extra
    extrude_levels([(0, trap(d_lo)), (CAP_ZBOT, trap(d_lo)),
                    (CAP_ZBOT, trap(DEPTH)), (H, trap(DEPTH))], ox, oy)
    # angled hat cap (depth kept at DEPTH so it seats in the existing recess)
    def cap(z):
        yh = CAP_HW if z>=CAP_ZRAMP else lerp(CAP_FOOT,CAP_HW,(z-CAP_ZBOT)/(CAP_ZRAMP-CAP_ZBOT))
        return [(0,-yh),(DEPTH,-yh),(DEPTH,yh),(0,yh)]
    extrude(cap, [CAP_ZBOT,CAP_ZRAMP,H], ox, oy)
    # id pips on host top
    for n in range(pips):
        px=ox-WM+1.2+n*2.2
        add_box(px,px+1.2,oy-0.7,oy+0.7,H,H+PIP_H)

build_male(0.0,  0.0, 0.0,   1)   # key #2 as-is
build_male(30.0, 0.0, EXTRA, 2)   # key #2 + 1 mm reach

# shift into positive space (min corner -> origin)
mnx=min(v[0] for t in tris for v in t); mny=min(v[1] for t in tris for v in t)
mnz=min(v[2] for t in tris for v in t)
tris=[tuple((v[0]-mnx,v[1]-mny,v[2]-mnz) for v in t) for t in tris]

def norm(t):
    (ax,ay,az),(bx,by,bz),(cx,cy,cz)=t
    ux,uy,uz=bx-ax,by-ay,bz-az; vx,vy,vz=cx-ax,cy-ay,cz-az
    nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
    l=math.sqrt(nx*nx+ny*ny+nz*nz) or 1.0
    return (nx/l,ny/l,nz/l)

out=sys.argv[1] if len(sys.argv)>1 else "dovetail_male_test.stl"
with open(out,"wb") as f:
    f.write(b'\0'*80); f.write(struct.pack('<I',len(tris)))
    for t in tris:
        n=norm(t); f.write(struct.pack('<3f',*n))
        for v in t: f.write(struct.pack('<3f',*v))
        f.write(struct.pack('<H',0))
print(f"key#2 clr={CLR}  male neck/flare full = {2*NECK:.2f}/{2*FLARE:.2f}  depth={DEPTH}")
print(f"variant B = continuous dovetail taper, tip at {DEPTH+EXTRA} mm "
      f"(full flare {2*FLARE:.2f} only at tip; cap zone kept at {DEPTH} mm)")
print(f"H={H}  CAP_ZBOT={CAP_ZBOT:.2f}  triangles={len(tris)}  -> {out}")
