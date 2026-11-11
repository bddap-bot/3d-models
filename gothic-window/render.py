import sys
from pathlib import Path

import bpy
from mathutils import Vector

stl_dir, out_dir = Path(sys.argv[-2]), Path(sys.argv[-1])

PAINTS = [
    (0.80, 0.03, 0.05),
    (0.03, 0.12, 0.75),
    (0.02, 0.45, 0.12),
    (1.00, 0.55, 0.03),
    (0.38, 0.05, 0.60),
    (0.00, 0.50, 0.58),
    (0.95, 0.25, 0.45),
    (1.00, 0.85, 0.25),
]
GAP = 10
MARGIN = 18
PAINT_BAND = 9
GLOW = (3.0, 1.1, 75)


def material(name, kind, colour):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    shader = nodes.new(kind)
    shader.inputs[0].default_value = (*colour, 1)
    if kind == "ShaderNodeEmission":
        centre, edge, reach = GLOW
        distance = nodes.new("ShaderNodeVectorMath")
        distance.operation = "LENGTH"
        falloff = nodes.new("ShaderNodeMapRange")
        falloff.interpolation_type = "SMOOTHSTEP"
        for socket, value in (("From Min", 0), ("From Max", reach), ("To Min", centre), ("To Max", edge)):
            falloff.inputs[socket].default_value = value
        links.new(nodes.new("ShaderNodeTexCoord").outputs["Object"], distance.inputs[0])
        links.new(distance.outputs["Value"], falloff.inputs["Value"])
        links.new(falloff.outputs["Result"], shader.inputs["Strength"])
    if kind == "ShaderNodeBsdfPrincipled":
        shader.inputs["Roughness"].default_value = 0.4
    if kind == "ShaderNodeBsdfTranslucent":
        back = nodes.new("ShaderNodeBsdfDiffuse")
        back.inputs["Color"].default_value = (*colour, 1)
        mix = nodes.new("ShaderNodeMixShader")
        mix.inputs["Fac"].default_value = 0.45
        links.new(shader.outputs[0], mix.inputs[1])
        links.new(back.outputs[0], mix.inputs[2])
        shader = mix
    links.new(shader.outputs[0], nodes.new("ShaderNodeOutputMaterial").inputs["Surface"])
    return mat


def load(part, mat, offset):
    bpy.ops.wm.stl_import(filepath=str(stl_dir / f"{part}.stl"))
    obj = bpy.context.selected_objects[0]
    obj.location = offset
    obj.data.materials.append(mat)
    return obj


def islands(part, offset):
    bpy.ops.wm.stl_import(filepath=str(stl_dir / f"{part}.stl"))
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    pieces = sorted(bpy.context.selected_objects, key=lambda o: (round(o.location.y / PAINT_BAND), o.location.x))
    for piece in pieces:
        piece.location += offset
    return pieces


def facing(direction):
    return Vector(direction).to_track_quat("-Z", "Y").to_euler()


def sun(direction, strength):
    light = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    bpy.context.scene.collection.objects.link(light)
    light.data.energy = strength
    light.data.angle = 0.2
    light.rotation_euler = facing(direction)


def render(name, stem, leaded, painted=False, backlit=True):
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x = 2000
    for stamp in ("date", "time", "render_time", "frame", "camera", "scene", "filename", "hostname", "memory"):
        setattr(scene.render, f"use_stamp_{stamp}", False)
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0, 0, 0, 1) if backlit else (0.2, 0.21, 0.22, 1)

    pane = material("pane", "ShaderNodeBsdfTranslucent", (0.92, 0.92, 0.88))
    frame = material("frame", "ShaderNodeBsdfPrincipled", (0.012, 0.012, 0.014))
    glow = material("glow", "ShaderNodeEmission", (1.0, 0.93, 0.82))
    paints = [material(f"paint{i}", "ShaderNodeBsdfTransparent", c) for i, c in enumerate(PAINTS)]
    lo = hi = step = None
    for block, with_leading in enumerate(reversed(leaded) if backlit else leaded):
        at = block * step if block else Vector()
        sheet = load(f"{stem}-pane", pane, at)
        if not block:
            corners = [Vector(c) for c in sheet.bound_box]
            lo = Vector((min(c.x for c in corners), min(c.y for c in corners)))
            hi = Vector((max(c.x for c in corners), max(c.y for c in corners)))
            step = Vector((0, hi.y - lo.y + GAP, 0)) if backlit else Vector((hi.x - lo.x + GAP, 0, 0))
        load(f"{stem}-rim", frame, at)
        load(f"{stem}-tracery", frame, at)
        if backlit:
            for lamp in islands(f"{stem}-pane", at - Vector((0, 0, 0.7))):
                lamp.data.materials.append(glow)
        if with_leading:
            load(f"{stem}-leading", frame, at)
        if with_leading and painted:
            for i, cell in enumerate(islands(f"{stem}-cells", at + Vector((0, 0, 0.02)))):
                cell.data.materials.append(paints[i * 3 % len(PAINTS)])

    span = Vector((hi.x - lo.x, hi.y - lo.y, 0)) + (len(leaded) - 1) * step
    centre = Vector((lo.x + span.x / 2, lo.y + span.y / 2, 0))
    bpy.ops.mesh.primitive_plane_add(size=6000, location=centre - Vector((0, 0, 1.2 if backlit else 0)))
    bpy.context.object.data.materials.append(material("ground", "ShaderNodeBsdfDiffuse", (0.16, 0.14, 0.12) if backlit else (0.23, 0.15, 0.09)))
    camera = bpy.data.objects.new("camera", bpy.data.cameras.new("camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.clip_end = 10000
    if backlit:
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = span.x + 2 * MARGIN
        camera.location = centre + Vector((0, 0, 1000))
        scene.render.resolution_y = round(scene.render.resolution_x * (span.y + 2 * MARGIN) / (span.x + 2 * MARGIN))
        sun((0.25, -0.2, -1), 1.0)
    else:
        camera.data.lens = 45
        camera.location = centre + Vector((-45, -285, 215))
        camera.rotation_euler = facing(centre - Vector((0, 12, 0)) - camera.location)
        scene.render.resolution_y = 900
        sun((0.62, 0.45, -0.5), 5.5)
    scene.render.filepath = str(out_dir / f"{name}.png")
    bpy.ops.render.render(write_still=True)


render("backlit", "row", [False, True])
render("painted", "row", [True], painted=True)
render("frontlit", "pair", [False, True], backlit=False)
