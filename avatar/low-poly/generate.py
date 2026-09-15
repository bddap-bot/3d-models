import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
PROOF = ROOT / "proof"
PROOF.mkdir(parents=True, exist_ok=True)


def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for datablock in list(datablocks):
            if datablock.users == 0:
                datablocks.remove(datablock)


def make_material(name, color, alpha, emission, rim, strength):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, alpha)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    emission_node = nodes.new("ShaderNodeEmission")
    emission_node.inputs["Color"].default_value = (*emission, 1.0)
    emission_node.inputs["Strength"].default_value = strength
    layer = nodes.new("ShaderNodeLayerWeight")
    layer.inputs["Blend"].default_value = 0.28
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.18
    ramp.color_ramp.elements[0].color = (*rim, 1.0)
    ramp.color_ramp.elements[1].position = 0.76
    ramp.color_ramp.elements[1].color = (*color, alpha)
    links.new(layer.outputs["Facing"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emission_node.inputs["Color"])
    mix = nodes.new("ShaderNodeMixShader")
    mix.inputs[0].default_value = alpha
    links.new(transparent.outputs[0], mix.inputs[1])
    links.new(emission_node.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], output.inputs[0])
    material.surface_render_method = "DITHERED"
    extension = material.vrm_addon_extension.mtoon1
    extension.enabled = True
    extension.pbr_metallic_roughness.base_color_factor = (*color, alpha)
    extension.alpha_mode = "BLEND"
    extension.double_sided = True
    extension.emissive_factor = emission
    extension.extensions.khr_materials_emissive_strength.emissive_strength = strength
    mtoon = extension.extensions.vrmc_materials_mtoon
    mtoon.shade_color_factor = tuple(c * 0.16 for c in color)
    mtoon.shading_toony_factor = 0.88
    mtoon.parametric_rim_color_factor = rim
    mtoon.rim_lighting_mix_factor = 0.9
    mtoon.parametric_rim_fresnel_power_factor = 4.5
    mtoon.parametric_rim_lift_factor = 0.08
    mtoon.outline_width_mode = "none"
    return material


def weight_object(obj, armature, bone_name):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    modifier = obj.modifiers.new("HumanoidRig", "ARMATURE")
    modifier.object = armature
    obj.parent = armature
    obj.select_set(False)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False


def prism(name, start, end, radius_a, radius_b, scale_xy, bone, material, armature, sides=6):
    start = Vector(start)
    end = Vector(end)
    direction = end - start
    bpy.ops.mesh.primitive_cone_add(
        vertices=sides,
        radius1=radius_a,
        radius2=radius_b,
        depth=direction.length,
        end_fill_type="NGON",
        location=(start + end) * 0.5,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())
    obj.scale.x = scale_xy[0]
    obj.scale.y = scale_xy[1]
    obj.data.materials.append(material)
    weight_object(obj, armature, bone)
    return obj


def ellipsoid(name, location, scale, bone, material, armature, subdivisions=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    weight_object(obj, armature, bone)
    return obj


def torus(name, location, major_radius, minor_radius, bone, material, armature):
    bpy.ops.mesh.primitive_torus_add(
        align="WORLD",
        major_segments=12,
        minor_segments=3,
        location=location,
        major_radius=major_radius,
        minor_radius=minor_radius,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    weight_object(obj, armature, bone)
    return obj


def make_face(armature, material):
    y = -0.148
    vertices = [
        (-0.096, y, 1.740), (-0.022, y - 0.004, 1.737), (-0.026, y, 1.710), (-0.090, y - 0.004, 1.712),
        (0.022, y - 0.004, 1.737), (0.096, y, 1.740), (0.090, y - 0.004, 1.712), (0.026, y, 1.710),
        (-0.098, y + 0.002, 1.775), (-0.022, y - 0.001, 1.783), (-0.024, y + 0.002, 1.774), (-0.096, y + 0.003, 1.767),
        (0.024, y + 0.002, 1.774), (0.022, y - 0.001, 1.783), (0.098, y + 0.002, 1.775), (0.096, y + 0.003, 1.767),
        (-0.060, y - 0.006, 1.635), (-0.030, y - 0.008, 1.650), (0.030, y - 0.008, 1.650), (0.060, y - 0.006, 1.635),
        (0.030, y - 0.008, 1.620), (-0.030, y - 0.008, 1.620),
    ]
    faces = [(0, 1, 2, 3), (4, 5, 6, 7), (16, 17, 18, 19, 20, 21)]
    mesh = bpy.data.meshes.new("FaceSignalsMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(material)
    face = bpy.data.objects.new("FaceSignals", mesh)
    bpy.context.collection.objects.link(face)
    weight_object(face, armature, "head")
    face.shape_key_add(name="Basis")

    def key(name, edits):
        block = face.shape_key_add(name=name, from_mix=False)
        for index, coordinate in edits.items():
            block.data[index].co = coordinate
        return block

    basis = [Vector(v) for v in vertices]
    key("aa", {
        16: (-0.034, y - 0.008, 1.649), 17: (-0.020, y - 0.010, 1.665), 18: (0.020, y - 0.010, 1.665),
        19: (0.034, y - 0.008, 1.649), 20: (0.020, y - 0.010, 1.600), 21: (-0.020, y - 0.010, 1.600),
    })
    key("ih", {
        16: (-0.090, y - 0.009, 1.636), 17: (-0.055, y - 0.010, 1.643), 18: (0.055, y - 0.010, 1.643),
        19: (0.090, y - 0.009, 1.636), 20: (0.055, y - 0.010, 1.629), 21: (-0.055, y - 0.010, 1.629),
    })
    key("ou", {
        16: (-0.027, y - 0.010, 1.638), 17: (-0.019, y - 0.011, 1.654), 18: (0.019, y - 0.011, 1.654),
        19: (0.027, y - 0.010, 1.638), 20: (0.019, y - 0.011, 1.614), 21: (-0.019, y - 0.011, 1.614),
    })
    key("ee", {
        16: (-0.080, y - 0.010, 1.637), 17: (-0.045, y - 0.011, 1.655), 18: (0.045, y - 0.011, 1.655),
        19: (0.080, y - 0.010, 1.637), 20: (0.045, y - 0.011, 1.613), 21: (-0.045, y - 0.011, 1.613),
    })
    key("oh", {
        16: (-0.038, y - 0.010, 1.640), 17: (-0.025, y - 0.011, 1.662), 18: (0.025, y - 0.011, 1.662),
        19: (0.038, y - 0.010, 1.640), 20: (0.025, y - 0.011, 1.607), 21: (-0.025, y - 0.011, 1.607),
    })
    blink_edits = {}
    for index in range(8):
        v = basis[index]
        blink_edits[index] = (v.x, v.y, 1.724)
    key("blink", blink_edits)
    key("neutral", {})
    key("amused", {
        0: (-0.096, y, 1.730), 1: (-0.022, y - 0.004, 1.727), 2: (-0.026, y, 1.717), 3: (-0.090, y - 0.004, 1.719),
        4: (0.022, y - 0.004, 1.727), 5: (0.096, y, 1.730), 6: (0.090, y - 0.004, 1.719), 7: (0.026, y, 1.717),
        16: (-0.064, y - 0.009, 1.642), 17: (-0.030, y - 0.010, 1.641), 18: (0.030, y - 0.010, 1.641),
        19: (0.064, y - 0.009, 1.642), 20: (0.030, y - 0.010, 1.622), 21: (-0.030, y - 0.010, 1.622),
    })
    key("puzzled", {
        0: (-0.096, y, 1.746), 1: (-0.022, y - 0.004, 1.736), 2: (-0.026, y, 1.711), 3: (-0.090, y - 0.004, 1.720),
        4: (0.022, y - 0.004, 1.733), 5: (0.096, y, 1.733), 6: (0.090, y - 0.004, 1.714), 7: (0.026, y, 1.714),
        16: (-0.058, y - 0.009, 1.630), 19: (0.066, y - 0.009, 1.642),
    })
    return face


def set_vrm(armature, face):
    extension = armature.data.vrm_addon_extension
    extension.spec_version = "1.0"
    meta = extension.vrm1.meta
    meta.vrm_name = "Lumen Relay"
    meta.version = "1.0.0"
    meta.authors.add().value = "bddap-bot"
    meta.copyright_information = "bddap-bot"
    meta.contact_information = "https://github.com/bddap-bot/3d-models"
    meta.references.add().value = "https://github.com/bddap-bot/3d-models/tree/main/avatar/low-poly"
    meta.third_party_licenses = "VRM Add-on for Blender is MIT OR GPL-3.0-or-later. Avatar artifacts are alternatively licensed under the repository MIT license linked by otherLicenseUrl."
    meta.avatar_permission = "everyone"
    meta.allow_excessively_violent_usage = True
    meta.allow_excessively_sexual_usage = True
    meta.allow_political_or_religious_usage = True
    meta.allow_antisocial_or_hate_usage = True
    meta.commercial_usage = "corporation"
    meta.credit_notation = "unnecessary"
    meta.allow_redistribution = True
    meta.modification = "allowModificationRedistribution"
    meta.other_license_url = "https://github.com/bddap-bot/3d-models/blob/main/LICENSE"
    expressions = extension.vrm1.expressions

    def bind(expression, shape):
        target = expression.morph_target_binds.add()
        target.node.mesh_object_name = face.name
        target.index = shape
        target.weight = 1.0

    for preset_name in ("aa", "ih", "ou", "ee", "oh", "blink", "neutral"):
        bind(getattr(expressions.preset, preset_name), preset_name)
    bind(expressions.preset.happy, "amused")
    bind(expressions.preset.surprised, "puzzled")
    for custom_name in ("amused", "puzzled"):
        custom = expressions.custom.add()
        custom.custom_name = custom_name
        bind(custom, custom_name)


def reset_pose(armature):
    for bone in armature.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0.0, 0.0, 0.0)
        bone.location = (0.0, 0.0, 0.0)
        bone.scale = (1.0, 1.0, 1.0)


def make_actions(armature):
    r = math.radians
    neutral = {
        "upper_arm.L": (r(-68), r(3), r(-5)), "upper_arm.R": (r(-68), r(-3), r(5)),
        "lower_arm.L": (r(-8), 0, 0), "lower_arm.R": (r(-8), 0, 0),
    }
    specs = {
        "sit": [(1, {**neutral}), (18, {**neutral, "upper_leg.L": (r(-88), 0, 0), "upper_leg.R": (r(-88), 0, 0), "lower_leg.L": (r(82), 0, 0), "lower_leg.R": (r(82), 0, 0), "hips": (r(5), 0, 0)}), (36, {**neutral, "upper_leg.L": (r(-88), 0, 0), "upper_leg.R": (r(-88), 0, 0), "lower_leg.L": (r(82), 0, 0), "lower_leg.R": (r(82), 0, 0), "hips": (r(5), 0, 0)})],
        "stand_up": [(1, {**neutral, "hips": (r(5), 0, 0), "upper_leg.L": (r(-88), 0, 0), "upper_leg.R": (r(-88), 0, 0), "lower_leg.L": (r(82), 0, 0), "lower_leg.R": (r(82), 0, 0)}), (18, {**neutral, "hips": (r(2.5), 0, 0), "upper_leg.L": (r(-40), 0, 0), "upper_leg.R": (r(-40), 0, 0), "lower_leg.L": (r(38), 0, 0), "lower_leg.R": (r(38), 0, 0), "chest": (r(-8), 0, 0)}), (36, neutral)],
        "idle_breathing": [(1, neutral), (18, {**neutral, "chest": (r(-2), 0, 0)}), (36, neutral)],
        "listen": [(1, neutral), (18, {**neutral, "head": (r(-4), r(10), r(4)), "chest": (0, r(4), 0)}), (36, neutral)],
        "talk_beats": [(1, neutral), (10, {**neutral, "upper_arm.L": (r(-38), r(-10), r(-8)), "lower_arm.L": (r(75), 0, 0), "head": (0, r(-5), 0)}), (20, {**neutral, "upper_arm.R": (r(-38), r(10), r(8)), "lower_arm.R": (r(75), 0, 0), "head": (0, r(5), 0)}), (32, neutral)],
        "nod": [(1, neutral), (10, {**neutral, "head": (r(13), 0, 0)}), (20, {**neutral, "head": (r(-9), 0, 0)}), (32, neutral)],
        "shrug": [(1, neutral), (16, {**neutral, "shoulder.L": (r(10), 0, 0), "shoulder.R": (r(10), 0, 0), "upper_arm.L": (r(-52), 0, r(-8)), "upper_arm.R": (r(-52), 0, r(8)), "lower_arm.L": (r(85), 0, 0), "lower_arm.R": (r(85), 0, 0), "head": (r(-2), r(7), 0)}), (32, neutral)],
        "think": [(1, neutral), (18, {**neutral, "upper_arm.R": (r(-35), r(8), r(6)), "lower_arm.R": (r(118), 0, 0), "head": (r(7), r(-9), 0)}), (36, neutral)],
        "rest": [(1, neutral), (18, {**neutral, "head": (r(4), r(-4), 0), "chest": (r(3), 0, 0), "upper_arm.L": (r(-74), r(3), r(-4)), "upper_arm.R": (r(-74), r(-3), r(4))}), (36, neutral)],
    }
    actions = {}
    animated_bones = sorted({bone for frames in specs.values() for _, pose in frames for bone in pose})
    for name, frames in specs.items():
        action = bpy.data.actions.new(name=name)
        armature.animation_data_create()
        armature.animation_data.action = action
        for frame, pose in frames:
            reset_pose(armature)
            for bone_name, rotation in pose.items():
                armature.pose.bones[bone_name].rotation_euler = rotation
            if name == "sit" and frame > 1:
                armature.pose.bones["hips"].location.y = -0.28
            if name == "stand_up":
                armature.pose.bones["hips"].location.y = {1: -0.28, 18: -0.14, 36: 0.0}[frame]
            for bone_name in animated_bones:
                bone = armature.pose.bones[bone_name]
                bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)
                bone.keyframe_insert(data_path="location", frame=frame, group=bone_name)
                bone.keyframe_insert(data_path="scale", frame=frame, group=bone_name)
        action.use_fake_user = True
        actions[name] = action
    armature.animation_data.action = None
    reset_pose(armature)
    return actions


def look_at(obj, point):
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_setup():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 360
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.world.color = (0.008, 0.015, 0.035)
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.image_settings.compression = 85
    bpy.ops.object.camera_add(location=(0.0, -4.05, 1.08))
    camera = bpy.context.object
    camera.name = "ProofCamera"
    camera.data.lens = 58
    look_at(camera, (0.0, 0.0, 0.91))
    scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(-1.8, -2.3, 2.5))
    key = bpy.context.object
    key.name = "CyanKey"
    key.data.energy = 500
    key.data.color = (0.08, 0.5, 1.0)
    key.data.shape = "DISK"
    key.data.size = 2.0
    look_at(key, (0.0, 0.0, 1.0))
    bpy.ops.object.light_add(type="AREA", location=(1.5, 0.8, 1.8))
    rim = bpy.context.object
    rim.name = "VioletRim"
    rim.data.energy = 650
    rim.data.color = (0.28, 0.08, 1.0)
    rim.data.size = 1.5
    look_at(rim, (0.0, 0.0, 1.0))
    return camera


def clear_shapes(face):
    for block in face.data.shape_keys.key_blocks:
        block.value = 0.0


def render_proofs(armature, face, actions, camera):
    scene = bpy.context.scene
    moods = {"listen": "puzzled", "talk_beats": "aa", "nod": "amused", "shrug": "puzzled", "rest": "neutral"}
    for name, action in actions.items():
        armature.animation_data.action = action
        scene.frame_set({"sit": 36, "stand_up": 27, "talk_beats": 10, "nod": 10}.get(name, int((action.frame_range[0] + action.frame_range[1]) * 0.5)))
        clear_shapes(face)
        face.data.shape_keys.key_blocks[moods.get(name, "neutral")].value = 1.0
        if name in {"sit", "stand_up"}:
            camera.location = (2.15, -3.45, 1.08)
        else:
            camera.location = (0.0, -4.05, 1.08)
        look_at(camera, (0.0, 0.0, 0.91))
        scene.render.filepath = str(PROOF / f"{name}.png")
        bpy.ops.render.render(write_still=True)
    armature.animation_data.action = actions["idle_breathing"]
    scene.frame_set(18)
    clear_shapes(face)
    face.data.shape_keys.key_blocks["amused"].value = 0.45
    for index in range(12):
        angle = 2.0 * math.pi * index / 12.0
        camera.location = (3.65 * math.sin(angle), -3.65 * math.cos(angle), 1.08)
        look_at(camera, (0.0, 0.0, 0.91))
        scene.render.filepath = str(PROOF / f"turntable-{index:02d}.png")
        bpy.ops.render.render(write_still=True)
    armature.animation_data.action = actions["rest"]
    scene.frame_set(18)
    scene.render.resolution_x = 300
    scene.render.resolution_y = 300
    camera.location = (0.0, -1.23, 1.70)
    look_at(camera, (0.0, 0.0, 1.70))
    for shape in ("neutral", "aa", "ih", "ou", "ee", "oh", "blink", "amused", "puzzled"):
        clear_shapes(face)
        face.data.shape_keys.key_blocks[shape].value = 1.0
        scene.render.filepath = str(PROOF / f"expression-{shape}.png")
        bpy.ops.render.render(write_still=True)
    scene.render.resolution_x = 360
    scene.render.resolution_y = 640
    camera.location = (0.0, -4.05, 1.08)
    look_at(camera, (0.0, 0.0, 0.91))
    armature.animation_data.action = None
    reset_pose(armature)
    clear_shapes(face)


def main():
    bpy.ops.preferences.addon_enable(module="VRM_Addon_for_Blender-release")
    clean_scene()
    bpy.ops.icyp.make_basic_armature()
    armature = bpy.context.object
    armature.name = "LumenRelayRig"
    armature.data.name = "LumenRelayHumanoid"
    armature.show_in_front = True
    for obj in list(bpy.context.scene.objects):
        if obj != armature:
            bpy.data.objects.remove(obj, do_unlink=True)
    body = make_material("HologramBody", (0.018, 0.22, 0.52), 0.24, (0.01, 0.32, 0.76), (0.08, 0.78, 1.0), 1.35)
    signal = make_material("SignalLight", (0.06, 0.62, 0.88), 0.78, (0.14, 0.78, 1.0), (0.42, 0.95, 1.0), 2.25)
    prism("Pelvis", (-0.0, 0.0, 0.84), (0.0, 0.0, 1.00), 0.17, 0.13, (1.0, 0.62), "hips", body, armature, 8)
    prism("Waist", (0.0, 0.0, 1.00), (0.0, 0.0, 1.14), 0.13, 0.16, (1.0, 0.64), "spine", body, armature, 8)
    prism("Torso", (0.0, 0.0, 1.14), (0.0, 0.0, 1.42), 0.16, 0.235, (1.0, 0.58), "chest", body, armature, 8)
    prism("Neck", (0.0, 0.0, 1.42), (0.0, 0.0, 1.56), 0.058, 0.07, (1.0, 0.82), "neck", body, armature, 6)
    ellipsoid("FacetedHead", (0.0, 0.0, 1.70), (0.155, 0.13, 0.205), "head", body, armature, 2)
    for side, x in (("L", 1.0), ("R", -1.0)):
        prism(f"UpperArm.{side}", (x * 0.19, 0.0, 1.405), (x * 0.43, 0.0, 1.405), 0.075, 0.057, (1.0, 0.86), f"upper_arm.{side}", body, armature, 6)
        prism(f"LowerArm.{side}", (x * 0.43, 0.0, 1.405), (x * 0.68, 0.0, 1.405), 0.055, 0.042, (1.0, 0.86), f"lower_arm.{side}", body, armature, 6)
        ellipsoid(f"Hand.{side}", (x * 0.73, -0.005, 1.405), (0.085, 0.043, 0.055), f"hand.{side}", body, armature, 1)
        prism(f"UpperLeg.{side}", (x * 0.105, 0.0, 0.84), (x * 0.095, 0.0, 0.51), 0.105, 0.078, (1.0, 0.78), f"upper_leg.{side}", body, armature, 7)
        prism(f"LowerLeg.{side}", (x * 0.095, 0.0, 0.51), (x * 0.083, 0.0, 0.105), 0.078, 0.060, (1.0, 0.78), f"lower_leg.{side}", body, armature, 7)
        ellipsoid(f"Foot.{side}", (x * 0.083, -0.085, 0.07), (0.072, 0.15, 0.055), f"foot.{side}", body, armature, 1)
    torus("RelayHalo", (0.0, 0.0, 0.035), 0.31, 0.009, "root", signal, armature)
    face = make_face(armature, signal)
    set_vrm(armature, face)
    actions = make_actions(armature)
    camera = render_setup()
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 36
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "lumen-relay.blend"))
    render_proofs(armature, face, actions, camera)
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "lumen-relay.blend"))
    export_objects = [obj for obj in bpy.context.scene.objects if obj.type in {"MESH", "ARMATURE"}]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in export_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    glb_result = bpy.ops.export_scene.gltf(
        filepath=str(ROOT / "lumen-relay.glb"),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_morph=True,
        export_skins=True,
        export_lights=False,
        export_cameras=False,
    )
    if glb_result != {"FINISHED"}:
        raise RuntimeError(f"glb export failed: {glb_result}")
    vrm_result = bpy.ops.export_scene.vrm(
        filepath=str(ROOT / "lumen-relay.vrm"),
        export_only_selections=True,
        enable_advanced_preferences=True,
        export_gltf_animations=True,
        export_lights=False,
        ignore_warning=True,
        armature_object_name=armature.name,
    )
    if vrm_result != {"FINISHED"}:
        raise RuntimeError(f"vrm export failed: {vrm_result}")
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / "lumen-relay.blend"))
    triangles = sum(len(poly.loop_indices) - 2 for obj in export_objects if obj.type == "MESH" for poly in obj.data.polygons)
    print(f"AVATAR_TRIANGLES_SOURCE={triangles}")
    print(f"AVATAR_ACTIONS={','.join(sorted(actions))}")


if __name__ == "__main__":
    main()
