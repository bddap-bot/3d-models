"""Procedural single-piece plumeria relief. Coordinates and STL units: millimeters.
Run with Python 3 + numpy, scipy, trimesh, manifold3d. No reference-image texture.
Every sculpted patch extends to the same flat back, making a support-free height solid.
"""
import os,sys,math,json
sys.path.insert(0,'/tmp/modeldeps')
import numpy as np,trimesh
from scipy.spatial.transform import Rotation
OUT=os.path.dirname(os.path.abspath(__file__))

def solid(fn,nu=110,nv=60):
 vs=[]
 for layer in [1,0]:
  for i in range(nu+1):
   for j in range(nv+1):
    x,y,z=fn(i/nu,2*j/nv-1);vs.append([x,y,z if layer else 0])
 n=(nu+1)*(nv+1);fs=[]
 for i in range(nu):
  for j in range(nv):
   a=i*(nv+1)+j;b=a+nv+1
   fs.extend([[a,b,b+1],[a,b+1,a+1],[a+n,b+1+n,b+n],[a+n,a+1+n,b+1+n]])
 boundary=list(range(nv+1))+[i*(nv+1)+nv for i in range(1,nu+1)]+[nu*(nv+1)+j for j in range(nv-1,-1,-1)]+[i*(nv+1) for i in range(nu-1,0,-1)]
 for a,b in zip(boundary,boundary[1:]+boundary[:1]):fs.extend([[a,b+n,b],[a,a+n,b+n]])
 m=trimesh.Trimesh(vertices=vs,faces=fs,process=True);m.fix_normals();return m
parts=[];labels=[]
leaf_specs=[('01_crown',(7,7),(18,78),16,-8),('02_upper_left',(-5,7),(-54,51),18,5),('03_right',(10,0),(82,18),19,-8),('04_lower_right',(9,-10),(68,-52),17,-8),('05_lower',(-3,-9),(-29,-80),17,-6),('06_lower_left',(-10,-5),(-81,-36),18,-8)]
for name,start,end,w,curve in leaf_specs:
 st=np.array(start);en=np.array(end);d=en-st;L=np.linalg.norm(d);n=np.array([-d[1],d[0]])/L
 def fn(u,v):
  sw=math.sin(math.pi*u);width=.85+w*sw**.80
  p=st+d*u+n*(curve*sw+width*v)
  # gently domed leaf, raised flowing midrib and swept, vein pairs
  z=2.0+3.25*sw**.65*(1-v*v)+.4*sw
  mid=.85*math.exp(-(v*width/.60)**2)*sw**.4
  branch=0
  for t in [.18,.28,.38,.48,.58,.68,.78,.87]:
   dist=(u-t-.13*abs(v))*L
   branch=max(branch,.48*math.exp(-(dist/.55)**2)*(1-abs(v))**.35)
  return p[0],p[1],z+mid+branch
 m=solid(fn,150,76);parts.append(m);labels.append('Leaf_'+name)
# Flower centers, radial lengths, phase, elevation. Back flower emerges above rear leaves.
flowers=[('Back',(6,17),25.3,14,7.0),('Left',(-19,-13),25.5,42,8.1),('Front',(10,-18),28.5,5,10.6)]
for k,(name,center,r,phase,base) in enumerate(flowers):
 for p in range(5):
  angle=math.radians(72*p+phase);c=math.cos(angle);s=math.sin(angle)
  rr=r*(1+.022*math.sin(p*3+k));ww=rr*.465
  def fn(u,v):
   sw=math.sin(math.pi*u);width=.85+ww*sw**.60*(.80+.20*u)
   x=1.1+rr*u;y=rr*.245*u**1.3+width*v
   # Raised rolled rim on one side, broad cupped basin, and petal sweep.
   z=base+5.0*u**1.45+2.75*v*v*sw**.65+2.0*v*sw**.70*u+.32*math.sin(math.pi*u)*math.cos(v*2)
   return center[0]+c*x-s*y,center[1]+s*x+c*y,z
  m=solid(fn,95,60);parts.append(m);labels.append('Flower_'+name+'_Petal_'+str(p+1))
 # Shallow funnel center, fully filled underside. Connect roots without a bead.
 nseg=96;rad=4.65
 vs=[[center[0],center[1],base-.65],[center[0],center[1],0]]
 for z in [base+.4,0]:
  for j in range(nseg):a=2*math.pi*j/nseg;vs.append([center[0]+rad*math.cos(a),center[1]+rad*math.sin(a),z])
 fs=[]
 for j in range(nseg):
  a=2+j;b=2+(j+1)%nseg;aa=a+nseg;bb=b+nseg
  fs.extend([[0,a,b],[1,bb,aa],[a,aa,bb],[a,bb,b]])
 m=trimesh.Trimesh(vertices=vs,faces=fs);m.fix_normals();parts.append(m);labels.append('Flower_'+name+'_Throat')
# Use exact solid union. The hidden source meshes remain individually editable.
if __name__=='__main__':
 os.makedirs(OUT+'/source_parts',exist_ok=True)
 for name,m in zip(labels,parts):m.export(OUT+'/source_parts/'+name+'.stl')
 print('Union',len(parts),'sculpted solids',flush=True)
 mesh=trimesh.boolean.union(parts,engine='manifold');mesh.merge_vertices();mesh.remove_unreferenced_vertices();mesh.fix_normals()
 scale=165/max(mesh.extents[:2]);mesh.apply_scale(scale)
 xy=(mesh.bounds[0,:2]+mesh.bounds[1,:2])/2;mesh.apply_translation([-xy[0],-xy[1],0])
 mesh.export(OUT+'/Plumeria_Single_Piece_165mm.stl')
 json.dump({'scale':scale,'xy_center':xy.tolist(),'flowers':flowers,'source_parts':labels},open(OUT+'/model_parameters.json','w'),indent=2)
 val={'dimensions_mm':mesh.extents.tolist(),'bounds_mm':mesh.bounds.tolist(),'watertight':bool(mesh.is_watertight),'winding_consistent':bool(mesh.is_winding_consistent),'connected_components':len(mesh.split()),'positive_volume_mm3':float(mesh.volume),'faces':len(mesh.faces),'bed_fit_180mm':bool(max(mesh.extents)<180),'construction':'Union of flat-bottom sculpted height solids. Every XY column in each source is filled down to Z=0. No floating bodies or bottom-facing overhangs outside the flat bed surface.'}
 json.dump(val,open(OUT+'/validation.json','w'),indent=2);print(json.dumps(val,indent=2),flush=True)
