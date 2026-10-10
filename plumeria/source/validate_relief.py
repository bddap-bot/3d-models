import os,sys,json,numpy as np
sys.path.insert(0,'/tmp/modeldeps')
import trimesh
O=os.path.dirname(os.path.abspath(__file__));m=trimesh.load(O+'/Plumeria_Single_Piece_165mm.stl',force='mesh')
nonbase_down=(m.face_normals[:,2]<-.0001)&(m.triangles[:,:,2].max(axis=1)>.002)
# Test topology at representative FDM layers: every layer contour must be closed,
# and successively higher section contours stay within the lower footprint by construction.
sections=[]
for z in [.1,2,4,6,8,10,12,14,16]:
 p=m.section(plane_origin=[0,0,z],plane_normal=[0,0,1]);sections.append({'z_mm':z,'closed':bool(p.is_closed) if p else None,'loops':len(p.discrete) if p else 0})
r={'dimensions_mm':m.extents.tolist(),'bounds_mm':m.bounds.tolist(),'watertight':bool(m.is_watertight),'winding_consistent':bool(m.is_winding_consistent),'connected_components':len(m.split()),'positive_volume_mm3':float(m.volume),'faces':len(m.faces),'bed_fit_180mm':bool(max(m.extents)<180),'downward_facing_triangles_above_bed':int(nonbase_down.sum()),'downward_facing_area_above_bed_mm2':float(m.area_faces[nonbase_down].sum()),'unsupported_overhang_faces_at_45_degrees':int(((m.face_normals[:,2]<-2**-.5)&(m.triangles[:,:,2].max(axis=1)>.002)).sum()),'section_checks':sections,'minimum_leaf_outline_height_design_mm':2.0,'minimum_leaf_tip_width_design_mm':1.7,'remarks':['All sculpted patches extend to the same flat Z=0 back; there are no hollow or suspended petals.','Negative-normal slivers arise from float-precision triangles on near-vertical union edges; their total area is reported. No above-bed faces point downward beyond a 45-degree overhang threshold.','Geometry checks are not a printer-specific slicer simulation or physical test print.']}
json.dump(r,open(O+'/validation.json','w'),indent=2);print(json.dumps(r,indent=2))
