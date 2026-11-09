# fine front-surface depth grid of the face mesh: facegrid.json {zb, x0, y0, d}
import json
S="/tmp/claude-0/-home-user-Horror/e0d7b3ed-0289-5d75-b841-90320013b441/scratchpad"
d=json.load(open(f"{S}/facemesh.json")); p=d["pos"]; idx=d["idx"]
V=[(p[i],p[i+1],p[i+2]) for i in range(0,len(p),3)]
D=0.01; x0,y0=-0.54,-0.56; W,H=109,113
zb=[[None]*W for _ in range(H)]
for t in range(0,len(idx),3):
    a,b,c=V[idx[t]],V[idx[t+1]],V[idx[t+2]]
    den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
    if abs(den)<1e-12: continue
    i0=max(0,int((min(a[0],b[0],c[0])-x0)/D)); i1=min(W-1,int((max(a[0],b[0],c[0])-x0)/D)+1)
    j0=max(0,int((min(a[1],b[1],c[1])-y0)/D)); j1=min(H-1,int((max(a[1],b[1],c[1])-y0)/D)+1)
    for j in range(j0,j1+1):
        py=y0+j*D
        for i in range(i0,i1+1):
            px=x0+i*D
            l1=((b[1]-c[1])*(px-c[0])+(c[0]-b[0])*(py-c[1]))/den
            l2=((c[1]-a[1])*(px-c[0])+(a[0]-c[0])*(py-c[1]))/den
            l3=1-l1-l2
            if min(l1,l2,l3)<-1e-6: continue
            z=l1*a[2]+l2*b[2]+l3*c[2]
            if zb[j][i] is None or z<zb[j][i]: zb[j][i]=z
json.dump({"zb":zb,"x0":x0,"y0":y0,"d":D},open(f"{S}/facegrid.json","w"))
# the eye sockets: in each upper quarter, the point furthest behind a straight line between its neighbours
def z(x,y):
    i=round((x-x0)/D); j=round((y-y0)/D); return zb[j][i]
best={}
for side in (-1,1):
    cand=[]
    for j in range(int((0.0-y0)/D),int((0.35-y0)/D)):
        for i in range(W):
            x=x0+i*D; y=y0+j*D
            if side*x<0.08 or side*x>0.42: continue
            zc=zb[j][i]
            if zc is None: continue
            nb=[zb[j][i-6] if i>=6 else None, zb[j][i+6] if i+6<W else None, zb[j-6][i], zb[j+6][i]]
            if None in nb: continue
            cand.append((zc-sum(nb)/4, x, y))
    cand.sort(reverse=True)
    print("eye", side, [(round(c[1],2),round(c[2],2),round(c[0],4)) for c in cand[:5]])
# the mouth: along x=0 from y -0.15 to -0.40, the dip
col=[(round(y0+j*D,2), zb[j][54]) for j in range(int((-0.42-y0)/D),int((-0.12-y0)/D))]
print("centre column", [(y, round(zz,3)) for y,zz in col if zz is not None])
