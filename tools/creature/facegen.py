# facegen.py: the features on his sculpted face (mesh 6671078520), placed on its front surface.
# Prints a Luau table for Rig.build: { name, kind, x, y, z, nx, ny, nz, roll, sx, sy, sz, col, mat }
import json, math
S="/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad"
g=json.load(open(f"{S}/facegrid.json")); zb=g["zb"]; x0=g["x0"]; y0=g["y0"]; D=g["d"]
SX,SY,SZ=0.74,1.12,1.15
def z(x,y):
    fi=(x-x0)/D; fj=(y-y0)/D; i=int(fi); j=int(fj); a=fi-i; b=fj-j
    vals=[]
    for (jj,ii,w) in ((j,i,(1-a)*(1-b)),(j,i+1,a*(1-b)),(j+1,i,(1-a)*b),(j+1,i+1,a*b)):
        v=zb[jj][ii]
        if v is None: return None
        vals.append(v*w)
    return sum(vals)
out=[]
def put(name, kind, x, y, sx, sy, sz, col, mat, roll=0.0, lift=0.0):
    zz=z(x,y); h=0.012
    fx=(z(x+h,y)-z(x-h,y))/(2*h)*SZ/SX; fy=(z(x,y+h)-z(x,y-h))/(2*h)*SZ/SY
    n=(fx,fy,-1.0); l=math.sqrt(sum(c*c for c in n)); n=tuple(c/l for c in n)
    px,py,pz=x*SX,y*SY,zz*SZ
    px+=n[0]*lift; py+=n[1]*lift; pz+=n[2]*lift
    out.append((name,kind,px,py,pz,n[0],n[1],n[2],roll,sx,sy,sz,col,mat))
def line(name, pts, w, col, mat="SmoothPlastic", lift=0.006):
    # a thin strip along the surface through native points pts
    for a,b in zip(pts,pts[1:]):
        mx,my=(a[0]+b[0])/2,(a[1]+b[1])/2
        dx,dy=(b[0]-a[0])*SX,(b[1]-a[1])*SY
        za,zbb=z(*a)*SZ,z(*b)*SZ
        L=math.sqrt(dx*dx+dy*dy+(zbb-za)**2)
        roll=math.atan2(dx,dy)  # (0 = straight down/up the face)
        put(name,"block",mx,my,w,L+0.004,0.012,col,mat,roll=-roll,lift=lift)
# the eyes: hollowed out, flat black, the left squeezed half shut, the right wide and drooping
for side,(cx,cy,w,hh,tilt) in ((-1,(-0.225,0.152,0.17,0.075,0.12)),(1,(0.228,0.142,0.18,0.135,-0.18))):
    put("EyeRim","ball",cx,cy-0.008,w*SX+0.07,hh*SY+0.07,0.03,"DIRT","SmoothPlastic",roll=tilt,lift=0.002)
    put("EyeHole","ball",cx,cy,w*SX,hh*SY,0.03,"HOLE","Neon",roll=tilt,lift=0.006)
    put("Glint","ball",cx+0.012*side,cy-0.004,0.016,0.016,0.012,"GLINT","Neon",lift=0.014)
    # dried streaks from the bottom of each eye, thick under it and thinning out down the cheek
    base=cy-hh*0.5
    L=0.36 if side>0 else 0.26
    line("Streak",[(cx-0.01*side,base),(cx-0.015*side,base-L*0.4),(cx-0.02*side,base-L*0.75),(cx-0.022*side,base-L)],0.016,"STREAK")
    line("Streak",[(cx+0.035*side,base+0.005),(cx+0.04*side,base-L*0.3),(cx+0.042*side,base-L*0.5)],0.011,"STREAK")
# the mouth: a slit wider than the lips, parted, the corners dragged up into the cheeks (the right further)
MY=-0.252
put("Maw","ball",0.0,MY,0.30,0.05,0.03,"HOLE","Neon",roll=-0.04,lift=0.008)
for side in (-1,1):
    cx=0.17*side; cy=MY+0.025+(0.012 if side>0 else 0)
    put("Mouth","ball",cx,cy,0.07,0.018,0.03,"HOLE","Neon",roll=side*-0.55,lift=0.008)
for i in range(-6,7):
    x=i*0.024
    if i in (-3,2,5): continue
    hh=0.016+((i*7)%4)*0.004
    put("Tooth","block",x,MY+0.02-hh/2/SY*0.5,0.014,hh,0.012,"TOOTH","SmoothPlastic",roll=((i*3)%5-2)*0.05,lift=0.013)
for i in range(-5,6):
    x=i*0.026
    if i in (1,-2): continue
    hh=0.014+((i*5)%3)*0.004
    put("LowerTooth","block",x,MY-0.02,0.014,hh,0.012,"TOOTH","SmoothPlastic",lift=0.013)
# cracks: from the brow down through the left eye to the jaw, its branches, the chin, the right temple
for pts in ([(-0.06,0.44),(-0.12,0.34),(-0.17,0.24),(-0.2,0.2)],[(-0.24,0.1),(-0.27,0.0),(-0.26,-0.1),(-0.3,-0.2)],
            [(-0.12,0.34),(-0.22,0.38),(-0.3,0.36)],[(0.06,-0.4),(0.12,-0.46)],[(0.32,0.36),(0.36,0.28),(0.39,0.2)]):
    line("Crack",pts,0.011,"CRACK")
print("return {")
for o in out:
    print("\t{ %r, %r, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %r, %r }," % o)
print("}")
