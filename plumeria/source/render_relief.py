import bpy,math,os,json
from mathutils import Vector
OUT=os.path.dirname(os.path.abspath(__file__))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.unit_settings.system='METRIC';s.unit_settings.scale_length=.001;s.unit_settings.length_unit='MILLIMETERS'
def mat(name,col,rough=.58):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=rough;return m
clay=mat('Warm ivory clay - unpainted geometry',(.69,.64,.55));floor=mat('Warm dark studio',(.07,.082,.088))
bpy.ops.wm.stl_import(filepath=OUT+'/Plumeria_Single_Piece_165mm.stl');obj=bpy.context.object;obj.name='PRINT - One connected relief - 165 mm - flat back Z0';obj.data.materials.append(clay)
dec=obj.modifiers.new('Preserve form - printable mesh optimization','DECIMATE');dec.ratio=.34;bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=dec.name)
bpy.ops.wm.stl_export(filepath=OUT+'/Plumeria_Single_Piece_165mm.stl',export_selected_objects=True)
for p in obj.data.polygons:p.use_smooth=True
obj['print_orientation']='Flat back on build plate, Z=0. All detail faces up.';obj['units']='mm';obj['single_piece']=True
# Non-rendering editable construction pieces retained and named.
c=bpy.data.collections.new('SOURCE - Editable petals and veined leaves - hidden');s.collection.children.link(c);params=json.load(open(OUT+'/model_parameters.json'))
for name in params['source_parts']:
 bpy.ops.wm.stl_import(filepath=OUT+'/source_parts/'+name+'.stl');o=bpy.context.object;o.name=name;o.scale=(params['scale'],)*3;o.location=(-params['xy_center'][0],-params['xy_center'][1],0)
 for cc in list(o.users_collection):cc.objects.unlink(o)
 c.objects.link(o)
c.hide_render=True;c.hide_viewport=True
bpy.ops.mesh.primitive_plane_add(size=2000,location=(0,0,-.15));ground=bpy.context.object;ground.name='STUDIO - not printable';ground.data.materials.append(floor)
def track(o,p=(0,0,0)):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-98,320));cam=bpy.context.object;track(cam,(0,0,3));cam.data.type='ORTHO';cam.data.ortho_scale=192;s.camera=cam
for loc,power,size in [((-100,70,200),1050000,160),((100,-50,170),480000,180),((0,180,90),320000,110)]:
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.data.energy=power;o.data.shape='DISK';o.data.size=size;track(o)
s.render.engine='CYCLES';s.cycles.samples=64;s.cycles.use_denoising=False;s.world.color=(.18,.18,.18);s.render.resolution_x=1300;s.render.resolution_y=1400;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX';s.render.image_settings.file_format='PNG'
s.render.filepath=OUT+'/01_Clay_Geometry_Preview.png';bpy.ops.wm.save_as_mainfile(filepath=OUT+'/Plumeria_Single_Piece_Editable.blend',compress=True);bpy.ops.render.render(write_still=True)
# Direct top view of exactly the same final printable mesh.
cam.location=(0,0,320);track(cam,(0,0,0));cam.data.ortho_scale=185;s.render.filepath=OUT+'/02_Top_Geometry_View.png';bpy.ops.render.render(write_still=True)
# Low side view exposes integrated flat back and supported mass.
cam.location=(155,-220,115);track(cam,(0,0,7));cam.data.ortho_scale=187;s.render.resolution_x=1500;s.render.resolution_y=750;s.render.filepath=OUT+'/03_Flat_Back_Print_Orientation.png';bpy.ops.render.render(write_still=True)
# Clay scene is the editable file default.
cam.location=(0,-98,320);track(cam,(0,0,3));cam.data.ortho_scale=192;s.render.resolution_x=1300;s.render.resolution_y=1400
bpy.context.view_layer.objects.active=obj;bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=OUT+'/Plumeria_Single_Piece_Editable.blend',compress=True)
