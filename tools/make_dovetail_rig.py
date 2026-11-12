#!/usr/bin/env python3
# Dovetail male-fit test rig. 4 separate male coupons at different per-side
# clearances vs the LOCKED female socket cavity (neck 3.0mm, flare 4.0mm full).
# male half-width = female_cavity_half - clearance. Print floor-down (tongues
# vertical, like the real parts). Slide each tongue into the printed fork socket.
import struct, math

DT_DEPTH = 5.0            # tongue depth (matches model)
H        = 20.0           # coupon height (NOT full height)
NECK_F   = 1.5           # female cavity half-width at neck (DT_NECK+DT_CLR)
FLARE_F  = 2.0           # female cavity half-width at flare (DT_FLARE+DT_CLR)

# (label pips, per-side clearance)
COUPONS = [(1, 0.20), (2, 0.15), (3, 0.10), (4, 0.05)]

tris = []  # each: (v0,v1,v2)
def quad(a,b,c,d): tris.extend([(a,b,c),(a,c,d)])
def box(x0,x1,y0,y1,z0,z1):
    p=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
       (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    quad(p[0],p[3],p[2],p[1])      # bottom
    quad(p[4],p[5],p[6],p[7])      # top
    quad(p[0],p[1],p[5],p[4])      # -y
    quad(p[1],p[2],p[6],p[5])      # +x
    quad(p[2],p[3],p[7],p[6])      # +y
    quad(p[3],p[0],p[4],p[7])      # -x
def trap(x0, yc, hn, hf, z0, z1):
    # trapezoid: neck (2*hn) at x0, flare (2*hf) at x0+DT_DEPTH
    a=(x0,           yc-hn); b=(x0+DT_DEPTH, yc-hf)
    c=(x0+DT_DEPTH,  yc+hf); d=(x0,          yc+hn)
    B=[(a[0],a[1],z0),(b[0],b[1],z0),(c[0],c[1],z0),(d[0],d[1],z0)]
    T=[(a[0],a[1],z1),(b[0],b[1],z1),(c[0],c[1],z1),(d[0],d[1],z1)]
    quad(B[0],B[3],B[2],B[1]); quad(T[0],T[1],T[2],T[3])
    for i in range(4):
        j=(i+1)%4; quad(B[i],B[j],T[j],T[i])

for k,(pips,c) in enumerate(COUPONS):
    X0 = k*26.0
    yc = 0.0
    hn = NECK_F - c
    hf = FLARE_F - c
    box(X0-11, X0+1.0, yc-7, yc+7, 0, H)   # handle/grip
    trap(X0, yc, hn, hf, 0, H)             # male tongue (overlaps handle by 1mm)
    for n in range(pips):                  # identifier pips on handle top
        px = X0-9 + n*2.6
        box(px, px+1.6, yc-0.8, yc+0.8, H, H+2.0)

# write binary STL
def norm(t):
    (ax,ay,az),(bx,by,bz),(cx,cy,cz)=t
    ux,uy,uz=bx-ax,by-ay,bz-az; vx,vy,vz=cx-ax,cy-ay,cz-az
    nx,ny,nz=uy*vz-uz*vy, uz*vx-ux*vz, ux*vy-uy*vx
    l=math.sqrt(nx*nx+ny*ny+nz*nz) or 1.0
    return (nx/l,ny/l,nz/l)
with open("dovetail_fit_test_rig.stl","wb") as f:
    f.write(b'\0'*80); f.write(struct.pack('<I', len(tris)))
    for t in tris:
        n=norm(t); f.write(struct.pack('<3f', *n))
        for v in t: f.write(struct.pack('<3f', *v))
        f.write(struct.pack('<H', 0))
print("coupons (pips : per-side clr : male neck/flare full-width mm):")
for pips,c in COUPONS:
    print(f"  {pips} pip(s) : {c:.2f} mm : {2*(NECK_F-c):.2f} / {2*(FLARE_F-c):.2f}")
print(f"triangles: {len(tris)}  ->  dovetail_fit_test_rig.stl")
