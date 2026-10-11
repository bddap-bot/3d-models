"""Split the printable relief into a leaves body and a flowers body for a two-colour print.
The flowers body is every column of the printable mesh inside the flowers' footprint, so a
flower's whole visible top, including where it covers a leaf, takes the flower colour.
"""
import os,json
import numpy as np,trimesh,shapely
from trimesh.path.polygons import projected
from build_relief import parts,labels
OUT=os.path.dirname(os.path.abspath(__file__))
# Covers the decimated printable mesh's flower walls, which drift from the source surfaces.
MARGIN=.3
params=json.load(open(OUT+'/model_parameters.json'))
relief=trimesh.load(OUT+'/Plumeria_Single_Piece_165mm.stl',force='mesh')
shift=np.array([-params['xy_center'][0],-params['xy_center'][1],0])
outlines=[]
for name,m in zip(labels,parts):
 if name.startswith('Flower_'):
  m=m.copy();m.apply_scale(params['scale']);m.apply_translation(shift);outlines.append(projected(m,normal=[0,0,1]))
footprint=shapely.union_all(outlines).buffer(MARGIN)
prism=trimesh.creation.extrude_polygon(footprint,relief.bounds[1,2]+2);prism.apply_translation([0,0,-1])
for name,body in [('Flowers',relief.intersection(prism,engine='manifold')),('Leaves',relief.difference(prism,engine='manifold'))]:
 body.export(OUT+f'/Plumeria_{name}_165mm.stl')
 print(name,{'volume_mm3':round(body.volume,1),'watertight':body.is_watertight,'bodies':[round(b.volume,2) for b in body.split(only_watertight=False)]})
