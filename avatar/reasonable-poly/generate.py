from pathlib import Path
import json
import math
import bpy
from mathutils import Vector


HERE = Path(__file__).resolve().parent
PROOF = HERE / "proof"
FRAMES = HERE / ".proof-frames"
TEXTURES = HERE / "textures"
AVATAR_OBJECTS = []
FPS = 24


def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights, bpy.data.armatures, bpy.data.actions):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def make_grid_texture():
    TEXTURES.mkdir(parents=True, exist_ok=True)
    path = TEXTURES / "holo-grid.png"
    size = 256
    image = bpy.data.images.new("HoloGridTexture", width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)
    for y in range(size):
        for x in range(size):
            i = (y * size + x) * 4
            line = 1.0 if y % 24 == 0 else 0.0
            node = 1.0 if x % 64 in (0, 1) and y % 64 in (0, 1) else 0.0
            pulse = 0.5 + 0.5 * math.sin((y / size) * math.tau * 3.0)
            pixels[i : i + 4] = (0.04 + node * 0.15, 0.55 + line * 0.14, 0.84 + pulse * 0.08, 0.76 + line * 0.10)
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    image.pack()
    return image


def material(name, color, emission, alpha, image=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, alpha)
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = 0.08
    bsdf.inputs["Roughness"].default_value = 0.28
    bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Strength"].default_value = emission
    bsdf.inputs["Alpha"].default_value = alpha
    if "Coat Weight" in bsdf.inputs:
        bsdf.inputs["Coat Weight"].default_value = 0.35
    if image:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        fresnel = nodes.new("ShaderNodeFresnel")
        fresnel.inputs["IOR"].default_value = 1.32
        edge = nodes.new("ShaderNodeMath")
        edge.operation = "MULTIPLY_ADD"
        edge.inputs[1].default_value = emission * 2.2
        edge.inputs[2].default_value = emission * 0.65
        mat.node_tree.links.new(fresnel.outputs[0], edge.inputs[0])
        mat.node_tree.links.new(edge.outputs[0], bsdf.inputs["Emission Strength"])
    try:
        mat.surface_render_method = "DITHERED"
    except Exception:
        pass
    mat.use_transparency_overlap = True
    mtoon = mat.vrm_addon_extension.mtoon1
    mtoon.enabled = True
    mtoon.pbr_metallic_roughness.base_color_factor = (*color, alpha)
    if image:
        mtoon.pbr_metallic_roughness.base_color_texture.index.source = image
    mtoon.alpha_mode = "BLEND"
    mtoon.double_sided = True
    mtoon.emissive_factor = color
    mtoon.extensions.khr_materials_emissive_strength.emissive_strength = emission
    mtoon.extensions.vrmc_materials_mtoon.shading_toony_factor = 0.85
    mtoon.extensions.vrmc_materials_mtoon.parametric_rim_color_factor = (0.25, 0.9, 1.0)
    mtoon.extensions.vrmc_materials_mtoon.rim_lighting_mix_factor = 0.8
    mtoon.extensions.vrmc_materials_mtoon.parametric_rim_fresnel_power_factor = 2.5
    return mat


def smooth(obj):
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = True


def skin_to_bone(obj, armature, bone_name):
    obj.parent = armature
    modifier = obj.modifiers.new("HumanoidSkin", "ARMATURE")
    modifier.object = armature
    group = obj.vertex_groups.new(name=bone_name)
    group.add(range(len(obj.data.vertices)), 1.0, "REPLACE")
    obj["retopology"] = "fixed 32x20 quad cage derived from original proportion stations"
    AVATAR_OBJECTS.append(obj)


def sphere_part(name, location, scale, mat, armature, bone, segments=32, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    smooth(obj)
    skin_to_bone(obj, armature, bone)
    return obj


def torus_part(name, location, rotation, major, minor, mat, armature, bone, major_segments=48, minor_segments=8):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_segments, minor_segments=minor_segments, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    smooth(obj)
    skin_to_bone(obj, armature, bone)
    return obj


def add_bone(edit_bones, name, head, tail, parent=None):
    bone = edit_bones.new(name)
    bone.head = head
    bone.tail = tail
    bone.parent = edit_bones.get(parent) if parent else None
    bone.use_connect = bool(parent and (Vector(head) - Vector(edit_bones[parent].tail)).length < 0.0001)
    return bone


def create_armature():
    data = bpy.data.armatures.new("AsterEchoHumanoid")
    armature = bpy.data.objects.new("AsterEchoRig", data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    e = data.edit_bones
    bones = [
        ("mixamorig:Hips", (0, 0, 1.35), (0, 0, 1.62), None),
        ("mixamorig:Spine", (0, 0, 1.62), (0, 0, 1.90), "mixamorig:Hips"),
        ("mixamorig:Spine1", (0, 0, 1.90), (0, 0, 2.18), "mixamorig:Spine"),
        ("mixamorig:Spine2", (0, 0, 2.18), (0, 0, 2.39), "mixamorig:Spine1"),
        ("mixamorig:Neck", (0, 0, 2.39), (0, 0, 2.59), "mixamorig:Spine2"),
        ("mixamorig:Head", (0, 0, 2.59), (0, 0, 3.06), "mixamorig:Neck"),
        ("mixamorig:LeftEye", (0.11, -0.20, 2.86), (0.11, -0.31, 2.86), "mixamorig:Head"),
        ("mixamorig:RightEye", (-0.11, -0.20, 2.86), (-0.11, -0.31, 2.86), "mixamorig:Head"),
        ("mixamorig:Jaw", (0, -0.08, 2.74), (0, -0.23, 2.62), "mixamorig:Head"),
        ("mixamorig:LeftShoulder", (0.08, 0, 2.34), (0.48, 0, 2.34), "mixamorig:Spine2"),
        ("mixamorig:LeftArm", (0.48, 0, 2.34), (1.08, 0, 2.30), "mixamorig:LeftShoulder"),
        ("mixamorig:LeftForeArm", (1.08, 0, 2.30), (1.50, 0, 2.28), "mixamorig:LeftArm"),
        ("mixamorig:LeftHand", (1.50, 0, 2.28), (1.76, 0, 2.28), "mixamorig:LeftForeArm"),
        ("mixamorig:RightShoulder", (-0.08, 0, 2.34), (-0.48, 0, 2.34), "mixamorig:Spine2"),
        ("mixamorig:RightArm", (-0.48, 0, 2.34), (-1.08, 0, 2.30), "mixamorig:RightShoulder"),
        ("mixamorig:RightForeArm", (-1.08, 0, 2.30), (-1.50, 0, 2.28), "mixamorig:RightArm"),
        ("mixamorig:RightHand", (-1.50, 0, 2.28), (-1.76, 0, 2.28), "mixamorig:RightForeArm"),
        ("mixamorig:LeftUpLeg", (0.23, 0, 1.45), (0.23, 0, 0.77), "mixamorig:Hips"),
        ("mixamorig:LeftLeg", (0.23, 0, 0.77), (0.23, 0, 0.12), "mixamorig:LeftUpLeg"),
        ("mixamorig:LeftFoot", (0.23, 0, 0.12), (0.23, -0.30, -0.02), "mixamorig:LeftLeg"),
        ("mixamorig:LeftToeBase", (0.23, -0.30, -0.02), (0.23, -0.52, -0.02), "mixamorig:LeftFoot"),
        ("mixamorig:RightUpLeg", (-0.23, 0, 1.45), (-0.23, 0, 0.77), "mixamorig:Hips"),
        ("mixamorig:RightLeg", (-0.23, 0, 0.77), (-0.23, 0, 0.12), "mixamorig:RightUpLeg"),
        ("mixamorig:RightFoot", (-0.23, 0, 0.12), (-0.23, -0.30, -0.02), "mixamorig:RightLeg"),
        ("mixamorig:RightToeBase", (-0.23, -0.30, -0.02), (-0.23, -0.52, -0.02), "mixamorig:RightFoot"),
    ]
    for args in bones:
        add_bone(e, *args)
    fingers = (("Thumb", -0.065), ("Index", -0.032), ("Middle", 0.0), ("Ring", 0.032), ("Pinky", 0.064))
    for side, sign in (("Left", 1), ("Right", -1)):
        hand = f"mixamorig:{side}Hand"
        for finger, y in fingers:
            parent = hand
            start_x = sign * 1.68
            for index, suffix in enumerate(("1", "2", "3")):
                name = f"mixamorig:{side}Hand{finger}{suffix}"
                x0 = start_x + sign * (0.065 * index)
                x1 = x0 + sign * 0.065
                add_bone(e, name, (x0, y, 2.28), (x1, y, 2.28), parent)
                parent = name
    bpy.ops.object.mode_set(mode="OBJECT")
    armature.show_in_front = True
    armature.data.vrm_addon_extension.spec_version = "1.0"
    AVATAR_OBJECTS.append(armature)
    return armature


def configure_vrm(armature, face):
    ext = armature.data.vrm_addon_extension.vrm1
    meta = ext.meta
    meta.vrm_name = "Aster Echo"
    meta.version = "1.0.0"
    meta.authors.add().value = "bddap-bot/3d-models"
    meta.copyright_information = "Original asset released under MIT"
    meta.contact_information = "https://github.com/bddap-bot/3d-models"
    meta.references.add().value = "https://github.com/bddap-bot/3d-models/tree/main/avatar/reasonable-poly"
    meta.third_party_licenses = "VRM Add-on for Blender is used as an export tool under MIT; no third-party mesh or texture is included."
    meta.avatar_permission = "everyone"
    meta.commercial_usage = "corporation"
    meta.credit_notation = "unnecessary"
    meta.allow_redistribution = True
    meta.modification = "allowModificationRedistribution"
    meta.allow_excessively_violent_usage = True
    meta.allow_excessively_sexual_usage = True
    meta.allow_political_or_religious_usage = True
    meta.allow_antisocial_or_hate_usage = True
    meta.other_license_url = "https://github.com/bddap-bot/3d-models/blob/main/LICENSE"
    human = ext.humanoid.human_bones
    mapping = {
        "hips": "mixamorig:Hips", "spine": "mixamorig:Spine", "chest": "mixamorig:Spine1", "upper_chest": "mixamorig:Spine2",
        "neck": "mixamorig:Neck", "head": "mixamorig:Head", "left_eye": "mixamorig:LeftEye", "right_eye": "mixamorig:RightEye", "jaw": "mixamorig:Jaw",
        "left_shoulder": "mixamorig:LeftShoulder", "left_upper_arm": "mixamorig:LeftArm", "left_lower_arm": "mixamorig:LeftForeArm", "left_hand": "mixamorig:LeftHand",
        "right_shoulder": "mixamorig:RightShoulder", "right_upper_arm": "mixamorig:RightArm", "right_lower_arm": "mixamorig:RightForeArm", "right_hand": "mixamorig:RightHand",
        "left_upper_leg": "mixamorig:LeftUpLeg", "left_lower_leg": "mixamorig:LeftLeg", "left_foot": "mixamorig:LeftFoot", "left_toes": "mixamorig:LeftToeBase",
        "right_upper_leg": "mixamorig:RightUpLeg", "right_lower_leg": "mixamorig:RightLeg", "right_foot": "mixamorig:RightFoot", "right_toes": "mixamorig:RightToeBase",
    }
    finger_map = {"thumb": ("metacarpal", "proximal", "distal"), "index": ("proximal", "intermediate", "distal"), "middle": ("proximal", "intermediate", "distal"), "ring": ("proximal", "intermediate", "distal"), "little": ("proximal", "intermediate", "distal")}
    mixamo = {"thumb": "Thumb", "index": "Index", "middle": "Middle", "ring": "Ring", "little": "Pinky"}
    for side in ("left", "right"):
        for finger, joints in finger_map.items():
            for number, joint in enumerate(joints, 1):
                mapping[f"{side}_{finger}_{joint}"] = f"mixamorig:{side.title()}Hand{mixamo[finger]}{number}"
    for slot, bone in mapping.items():
        getattr(human, slot).node.bone_name = bone

    expressions = ext.expressions
    preset_bindings = {"aa": "aa", "ih": "ih", "ou": "ou", "ee": "ee", "oh": "oh", "blink": "blink", "neutral": "neutral", "happy": "amused", "surprised": "puzzled"}
    for preset, shape in preset_bindings.items():
        expression = getattr(expressions.preset, preset)
        bind = expression.morph_target_binds.add()
        bind.node.mesh_object_name = face.name
        bind.index = shape
        bind.weight = 1.0
    for custom_name in ("amused", "puzzled"):
        expression = expressions.custom.add()
        expression.custom_name = custom_name
        bind = expression.morph_target_binds.add()
        bind.node.mesh_object_name = face.name
        bind.index = custom_name
        bind.weight = 1.0


def create_face(armature, mat):
    pieces = []
    for x in (-0.115, 0.115):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1.0, location=(x, -0.278, 2.87))
        eye = bpy.context.object
        eye.scale = (0.082, 0.018, 0.035)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        pieces.append(eye)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.092, minor_radius=0.014, major_segments=32, minor_segments=8, location=(0, -0.284, 2.68), rotation=(math.pi / 2, 0, 0))
    mouth = bpy.context.object
    mouth.scale = (1.22, 0.28, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    pieces.append(mouth)
    bpy.ops.object.select_all(action="DESELECT")
    for piece in pieces:
        piece.select_set(True)
    bpy.context.view_layer.objects.active = mouth
    bpy.ops.object.join()
    face = bpy.context.object
    face.name = "FaceMorphs"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    face.data.materials.append(mat)
    smooth(face)
    face.shape_key_add(name="Basis")
    names = ("aa", "ih", "ou", "ee", "oh", "blink", "neutral", "amused", "puzzled")
    center_z = 2.68
    for name in names:
        key = face.shape_key_add(name=name, from_mix=False)
        for point in key.data:
            co = point.co
            if co.z < 2.78:
                dx, dz = co.x, co.z - center_z
                factors = {
                    "aa": (0.92, 4.40), "ih": (1.45, 0.48), "ou": (0.48, 1.55), "ee": (2.05, 0.42), "oh": (1.00, 2.65),
                    "neutral": (1.06, 0.88), "amused": (1.40, 0.82), "puzzled": (1.05, 1.05), "blink": (1.0, 1.0),
                }[name]
                co.x = dx * factors[0]
                co.z = center_z + dz * factors[1]
                if name == "amused":
                    co.z += 0.035 * abs(dx) / 0.10
                elif name == "puzzled":
                    co.z += 0.045 * dx / 0.10
            elif name == "blink":
                eye_center = 0.115 if co.x > 0 else -0.115
                co.z = 2.87 + (co.z - 2.87) * 0.12
                co.x = eye_center + (co.x - eye_center) * 1.08
    skin_to_bone(face, armature, "mixamorig:Head")
    return face


def build_avatar(armature, body_mat, core_mat, glow_mat, accent_mat):
    parts = [
        ("HeadShell", (0, 0, 2.82), (0.35, 0.29, 0.42), "mixamorig:Head"),
        ("NeckShell", (0, 0, 2.50), (0.15, 0.15, 0.18), "mixamorig:Neck"),
        ("UpperTorso", (0, 0, 2.18), (0.52, 0.27, 0.43), "mixamorig:Spine1"),
        ("CoreTorso", (0, 0, 1.82), (0.39, 0.22, 0.38), "mixamorig:Spine"),
        ("HipShell", (0, 0, 1.47), (0.44, 0.24, 0.29), "mixamorig:Hips"),
        ("LeftShoulderShell", (0.55, 0, 2.30), (0.17, 0.17, 0.17), "mixamorig:LeftShoulder"),
        ("RightShoulderShell", (-0.55, 0, 2.30), (0.17, 0.17, 0.17), "mixamorig:RightShoulder"),
        ("LeftUpperArmShell", (0.82, 0, 2.31), (0.35, 0.135, 0.145), "mixamorig:LeftArm"),
        ("RightUpperArmShell", (-0.82, 0, 2.31), (0.35, 0.135, 0.145), "mixamorig:RightArm"),
        ("LeftForearmShell", (1.29, 0, 2.29), (0.30, 0.115, 0.125), "mixamorig:LeftForeArm"),
        ("RightForearmShell", (-1.29, 0, 2.29), (0.30, 0.115, 0.125), "mixamorig:RightForeArm"),
        ("LeftHandShell", (1.62, -0.01, 2.28), (0.16, 0.08, 0.115), "mixamorig:LeftHand"),
        ("RightHandShell", (-1.62, -0.01, 2.28), (0.16, 0.08, 0.115), "mixamorig:RightHand"),
        ("LeftThighShell", (0.23, 0, 1.08), (0.195, 0.185, 0.49), "mixamorig:LeftUpLeg"),
        ("RightThighShell", (-0.23, 0, 1.08), (0.195, 0.185, 0.49), "mixamorig:RightUpLeg"),
        ("LeftCalfShell", (0.23, 0, 0.43), (0.155, 0.155, 0.44), "mixamorig:LeftLeg"),
        ("RightCalfShell", (-0.23, 0, 0.43), (0.155, 0.155, 0.44), "mixamorig:RightLeg"),
        ("LeftFootShell", (0.23, -0.18, 0.03), (0.18, 0.28, 0.11), "mixamorig:LeftFoot"),
        ("RightFootShell", (-0.23, -0.18, 0.03), (0.18, 0.28, 0.11), "mixamorig:RightFoot"),
    ]
    for name, location, scale, bone in parts:
        part_mat = core_mat if name in {"UpperTorso", "CoreTorso", "HipShell"} else body_mat
        sphere_part(name, location, scale, part_mat, armature, bone)
    face = create_face(armature, glow_mat)
    torus_part("ChestOrbit", (0, -0.285, 2.12), (math.pi / 2, 0, 0), 0.34, 0.022, accent_mat, armature, "mixamorig:Spine1")
    torus_part("WaistOrbit", (0, 0, 1.56), (0, 0, 0), 0.41, 0.020, accent_mat, armature, "mixamorig:Hips")
    for i, (x, z, scale, rot) in enumerate(((0.0, 3.28, (0.052, 0.070, 0.20), 0.0), (0.10, 3.22, (0.045, 0.065, 0.16), -0.38), (-0.10, 3.22, (0.045, 0.065, 0.16), 0.38))):
        crest = sphere_part(f"SignalCrest{i+1}", (x, 0.03, z), scale, accent_mat, armature, "mixamorig:Head", segments=24, rings=14)
        crest.rotation_euler.y = rot
    return face


def reset_pose(armature):
    for bone in armature.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)
        bone.scale = (1, 1, 1)


def set_bone(armature, name, rotation=None, location=None):
    bone = armature.pose.bones[name]
    if rotation is not None:
        bone.rotation_euler = rotation
    if location is not None:
        bone.location = location


def key_pose(armature, frame):
    for bone in armature.pose.bones:
        bone.keyframe_insert("rotation_euler", frame=frame, group=bone.name)
        bone.keyframe_insert("location", frame=frame, group=bone.name)


def standing(armature):
    reset_pose(armature)
    set_bone(armature, "mixamorig:LeftArm", (-1.18, 0, 0))
    set_bone(armature, "mixamorig:RightArm", (-1.18, 0, 0))


def seated(armature):
    standing(armature)
    set_bone(armature, "mixamorig:Hips", location=(0, 0, -0.62))
    set_bone(armature, "mixamorig:LeftUpLeg", (-1.35, 0, 0))
    set_bone(armature, "mixamorig:RightUpLeg", (-1.35, 0, 0))
    set_bone(armature, "mixamorig:LeftLeg", (1.30, 0, 0))
    set_bone(armature, "mixamorig:RightLeg", (1.30, 0, 0))
    set_bone(armature, "mixamorig:LeftForeArm", (-1.50, 0, 0))
    set_bone(armature, "mixamorig:RightForeArm", (-1.50, 0, 0))


def make_action(armature, name, end, poses):
    action = bpy.data.actions.new(name=name)
    action.use_fake_user = True
    armature.animation_data_create()
    armature.animation_data.action = action
    for frame, pose in poses:
        pose()
        key_pose(armature, frame)
    action["state_clip"] = name
    return action


def create_actions(armature):
    actions = {}
    stand = lambda: standing(armature)
    seat = lambda: seated(armature)
    actions["sit"] = make_action(armature, "sit", 36, [(1, stand), (36, seat)])
    actions["stand_up"] = make_action(armature, "stand_up", 36, [(1, seat), (36, stand)])

    def breathe_high():
        standing(armature)
        set_bone(armature, "mixamorig:Spine1", (-0.12, 0, 0))
        set_bone(armature, "mixamorig:Spine2", (0.07, 0, 0))
        set_bone(armature, "mixamorig:Head", (-0.06, 0, 0))
        set_bone(armature, "mixamorig:LeftShoulder", (-0.16, 0, -0.06))
        set_bone(armature, "mixamorig:RightShoulder", (-0.16, 0, 0.06))
    actions["idle_breathing"] = make_action(armature, "idle_breathing", 72, [(1, stand), (18, breathe_high), (36, stand), (54, breathe_high), (72, stand)])

    def listening():
        standing(armature)
        set_bone(armature, "mixamorig:Head", (0.12, -0.18, -0.18))
        set_bone(armature, "mixamorig:Spine2", (0.04, 0.08, 0))
        set_bone(armature, "mixamorig:LeftArm", (0.28, -0.18, -0.12))
        set_bone(armature, "mixamorig:LeftForeArm", (0.82, 0, -2.95))
    actions["listen"] = make_action(armature, "listen", 48, [(1, stand), (16, listening), (32, listening), (48, stand)])

    def talk_left():
        standing(armature)
        set_bone(armature, "mixamorig:LeftArm", (0.05, -0.18, -0.30))
        set_bone(armature, "mixamorig:LeftForeArm", (-0.72, 0.10, -0.42))
        set_bone(armature, "mixamorig:RightArm", (-0.92, 0.08, 0.10))
        set_bone(armature, "mixamorig:RightForeArm", (-0.32, 0.05, 0.16))
    def talk_right():
        standing(armature)
        set_bone(armature, "mixamorig:RightArm", (-0.28, 0.18, 0.28))
        set_bone(armature, "mixamorig:RightForeArm", (-1.10, -0.10, 0.45))
        set_bone(armature, "mixamorig:LeftArm", (-0.62, -0.10, -0.18))
        set_bone(armature, "mixamorig:LeftForeArm", (-0.65, -0.08, -0.25))
    actions["talk_beats"] = make_action(armature, "talk_beats", 60, [(1, stand), (14, talk_left), (28, stand), (42, talk_right), (60, stand)])

    def nod_down():
        standing(armature)
        set_bone(armature, "mixamorig:Head", (0.38, 0, 0))
    def nod_up():
        standing(armature)
        set_bone(armature, "mixamorig:Head", (-0.09, 0, 0))
    actions["nod"] = make_action(armature, "nod", 42, [(1, stand), (10, nod_down), (19, nod_up), (28, nod_down), (42, stand)])

    def shrug_up():
        standing(armature)
        set_bone(armature, "mixamorig:LeftShoulder", (0.34, -0.05, 0.08))
        set_bone(armature, "mixamorig:RightShoulder", (0.34, 0.05, -0.08))
        set_bone(armature, "mixamorig:LeftArm", (-0.38, -0.12, -0.16))
        set_bone(armature, "mixamorig:RightArm", (-0.38, 0.12, 0.16))
        set_bone(armature, "mixamorig:LeftForeArm", (-1.05, 0.15, -0.42))
        set_bone(armature, "mixamorig:RightForeArm", (-1.05, -0.15, 0.42))
    actions["shrug"] = make_action(armature, "shrug", 48, [(1, stand), (18, shrug_up), (30, shrug_up), (48, stand)])

    def thinking():
        standing(armature)
        set_bone(armature, "mixamorig:Head", (0.10, -0.22, 0.18))
        set_bone(armature, "mixamorig:RightArm", (0.40, 0.20, 0.15))
        set_bone(armature, "mixamorig:RightForeArm", (0.80, 0, 3.0))
    actions["think"] = make_action(armature, "think", 60, [(1, stand), (22, thinking), (42, thinking), (60, stand)])

    def rest_breathe():
        seated(armature)
        set_bone(armature, "mixamorig:Head", (0.03, 0, 0))
        set_bone(armature, "mixamorig:Spine1", (-0.02, 0, 0))
    actions["rest"] = make_action(armature, "rest", 72, [(1, seat), (24, rest_breathe), (48, seat), (72, seat)])
    armature.animation_data.action = None
    reset_pose(armature)
    return actions


def setup_render():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.resolution_percentage = 100
    scene.render.resolution_x = 384
    scene.render.resolution_y = 512
    scene.render.image_settings.color_depth = "8"
    scene.render.fps = FPS
    scene.world.color = (0.002, 0.004, 0.012)
    world_nodes = scene.world.node_tree.nodes if scene.world.use_nodes else None
    scene.world.use_nodes = True
    background = scene.world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.002, 0.006, 0.025, 1)
    background.inputs["Strength"].default_value = 0.12

    bpy.ops.object.camera_add(location=(4.35, -7.0, 3.15))
    camera = bpy.context.object
    camera.name = "ProofCamera"
    camera.data.lens = 62
    scene.camera = camera
    bpy.ops.object.light_add(type="AREA", location=(2.8, -3.0, 4.6))
    key = bpy.context.object
    key.name = "ProofKey"
    key.data.energy = 900
    key.data.color = (0.15, 0.68, 1.0)
    key.data.shape = "DISK"
    key.data.size = 3.0
    aim(key, (0, 0, 1.55))
    bpy.ops.object.light_add(type="AREA", location=(-3.0, 1.0, 2.5))
    rim = bpy.context.object
    rim.name = "ProofRim"
    rim.data.energy = 1100
    rim.data.color = (0.55, 0.12, 1.0)
    rim.data.size = 2.0
    aim(rim, (0, 0, 1.7))
    return camera


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def prepare_proof_materials():
    settings = {
        "HoloBody": ((0.025, 0.48, 0.78), 1.9, 0.76),
        "HoloCore": ((0.010, 0.16, 0.42), 1.4, 0.70),
        "SignalLight": ((0.18, 0.92, 1.00), 4.0, 0.92),
        "VioletAccent": ((0.48, 0.16, 1.00), 3.0, 0.82),
    }
    for name, (color, emission, alpha) in settings.items():
        mat = bpy.data.materials[name]
        mat.node_tree.nodes.clear()
        output = mat.node_tree.nodes.new("ShaderNodeOutputMaterial")
        bsdf = mat.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.18
        bsdf.inputs["Roughness"].default_value = 0.30
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
        bsdf.inputs["Alpha"].default_value = alpha
        mat.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
        mat.diffuse_color = (*color, alpha)
        mat.surface_render_method = "DITHERED"


def select_avatar():
    bpy.ops.object.select_all(action="DESELECT")
    for obj in AVATAR_OBJECTS:
        obj.hide_viewport = False
        obj.hide_render = False
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(obj for obj in AVATAR_OBJECTS if obj.type == "ARMATURE")


def triangle_count():
    depsgraph = bpy.context.evaluated_depsgraph_get()
    total = 0
    for obj in AVATAR_OBJECTS:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        total += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    return total


def render_proofs(armature, actions, face, camera):
    PROOF.mkdir(parents=True, exist_ok=True)
    pose_frames = {"sit": 25, "stand_up": 18, "idle_breathing": 18, "listen": 16, "talk_beats": 14, "nod": 10, "shrug": 24, "think": 30, "rest": 48}
    for name, frame in pose_frames.items():
        bpy.ops.wm.open_mainfile(filepath=str(HERE / "aster-echo.blend"))
        scene = bpy.context.scene
        armature = bpy.data.objects["AsterEchoRig"]
        camera = bpy.data.objects["ProofCamera"]
        prepare_proof_materials()
        armature.animation_data.action = bpy.data.actions[name]
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        pose = {bone.name: bone.matrix_basis.copy() for bone in armature.pose.bones}
        armature.animation_data.action = None
        for bone in armature.pose.bones:
            bone.matrix_basis = pose[bone.name]
        bpy.context.view_layer.update()
        camera.data.lens = 56 if name in {"sit", "rest"} else 62
        camera.location = (4.8, -5.4, 2.85) if name in {"sit", "rest"} else ((0, -7.4, 3.15) if name == "talk_beats" else (2.50, -7.0, 3.15))
        aim(camera, (0, 0, 1.52))
        scene.render.resolution_x = 384
        scene.render.resolution_y = 512
        scene.render.filepath = str(PROOF / f"{name}.png")
        bpy.ops.render.render(write_still=True)

    bpy.ops.wm.open_mainfile(filepath=str(HERE / "aster-echo.blend"))
    scene = bpy.context.scene
    armature = bpy.data.objects["AsterEchoRig"]
    face = bpy.data.objects["FaceMorphs"]
    camera = bpy.data.objects["ProofCamera"]
    prepare_proof_materials()
    armature.animation_data.action = bpy.data.actions["idle_breathing"]
    scene.frame_set(18)
    bpy.context.view_layer.update()
    pose = {bone.name: bone.matrix_basis.copy() for bone in armature.pose.bones}
    armature.animation_data.action = None
    for bone in armature.pose.bones:
        bone.matrix_basis = pose[bone.name]
    bpy.context.view_layer.update()
    FRAMES.mkdir(parents=True, exist_ok=True)
    for index in range(18):
        angle = math.tau * index / 18
        camera.location = (6.5 * math.sin(angle), -6.5 * math.cos(angle), 2.75)
        aim(camera, (0, 0, 1.48))
        scene.render.filepath = str(FRAMES / f"frame_{index:02d}.png")
        bpy.ops.render.render(write_still=True)

    armature.animation_data.action = bpy.data.actions["idle_breathing"]
    scene.frame_set(18)
    camera.data.lens = 72
    camera.location = (0, -3.15, 2.90)
    aim(camera, (0, -0.03, 2.80))
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 256
    for key in face.data.shape_keys.key_blocks:
        key.value = 0.0
    for index, name in enumerate(("aa", "ih", "ou", "ee", "oh")):
        face.data.shape_keys.key_blocks[name].value = 1.0
        scene.render.resolution_x = 256
        scene.render.filepath = str(FRAMES / f"viseme_{index}.png")
        bpy.ops.render.render(write_still=True)
        face.data.shape_keys.key_blocks[name].value = 0.0
    camera.data.lens = 62
    scene.render.resolution_x = 384
    scene.render.resolution_y = 512


def save_and_export(armature, actions):
    armature.animation_data.action = actions["idle_breathing"]
    bpy.context.scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / "aster-echo.blend"))
    select_avatar()
    result = bpy.ops.export_scene.vrm(
        filepath=str(HERE / "aster-echo.vrm"),
        export_only_selections=True,
        export_invisibles=False,
        export_lights=False,
        export_gltf_animations=True,
        export_try_sparse_sk=False,
    )
    if result != {"FINISHED"}:
        raise RuntimeError(f"VRM export failed: {result}")
    select_avatar()
    result = bpy.ops.export_scene.gltf(
        filepath=str(HERE / "aster-echo.glb"),
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_morph=True,
        export_skins=True,
    )
    if result != {"FINISHED"}:
        raise RuntimeError(f"GLB export failed: {result}")


def main():
    bpy.ops.preferences.addon_enable(module="VRM_Addon_for_Blender-release")
    bpy.context.preferences.filepaths.save_version = 0
    clean_scene()
    image = make_grid_texture()
    body_mat = material("HoloBody", (0.018, 0.62, 0.94), 2.2, 0.88, image)
    core_mat = material("HoloCore", (0.012, 0.28, 0.68), 1.35, 0.80, image)
    glow_mat = material("SignalLight", (0.16, 0.92, 1.0), 5.0, 0.92)
    accent_mat = material("VioletAccent", (0.42, 0.18, 1.0), 3.8, 0.78)
    armature = create_armature()
    face = build_avatar(armature, body_mat, core_mat, glow_mat, accent_mat)
    configure_vrm(armature, face)
    actions = create_actions(armature)
    camera = setup_render()
    triangles = triangle_count()
    if not 20000 <= triangles <= 50000:
        raise RuntimeError(f"triangle budget violated: {triangles}")
    bpy.ops.wm.save_as_mainfile(filepath=str(HERE / "aster-echo.blend"))
    bpy.ops.wm.open_mainfile(filepath=str(HERE / "aster-echo.blend"))
    armature = bpy.data.objects["AsterEchoRig"]
    face = bpy.data.objects["FaceMorphs"]
    camera = bpy.data.objects["ProofCamera"]
    actions = {name: bpy.data.actions[name] for name in actions}
    AVATAR_OBJECTS.clear()
    AVATAR_OBJECTS.extend([armature] + [obj for obj in bpy.data.objects if obj.type == "MESH" and any(modifier.type == "ARMATURE" for modifier in obj.modifiers)])
    render_proofs(armature, actions, face, camera)
    bpy.ops.wm.open_mainfile(filepath=str(HERE / "aster-echo.blend"))
    armature = bpy.data.objects["AsterEchoRig"]
    face = bpy.data.objects["FaceMorphs"]
    actions = {name: bpy.data.actions[name] for name in actions}
    AVATAR_OBJECTS.clear()
    AVATAR_OBJECTS.extend([armature] + [obj for obj in bpy.data.objects if obj.type == "MESH" and any(modifier.type == "ARMATURE" for modifier in obj.modifiers)])
    save_and_export(armature, actions)
    report = {
        "name": "Aster Echo",
        "triangles": triangles,
        "texture": {"path": "textures/holo-grid.png", "width": 256, "height": 256},
        "clips": {name: [int(action.frame_range[0]), int(action.frame_range[1])] for name, action in actions.items()},
        "shape_keys": [key.name for key in face.data.shape_keys.key_blocks if key.name != "Basis"],
        "humanoid_bones": len(armature.data.bones),
    }
    (HERE / "metrics.json").write_text(json.dumps(report, indent=2) + "\n")
    print("AVATAR_METRICS", json.dumps(report, sort_keys=True))


main()
