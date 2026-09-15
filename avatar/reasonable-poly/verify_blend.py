import math
import bpy


EXPECTED = {"sit", "stand_up", "idle_breathing", "listen", "talk_beats", "nod", "shrug", "think", "rest"}
actions = {action.name: action for action in bpy.data.actions}
if set(actions) != EXPECTED:
    raise RuntimeError(f"saved action set mismatch: {sorted(actions)}")

armature = bpy.data.objects.get("AsterEchoRig")
if not armature or armature.type != "ARMATURE":
    raise RuntimeError("saved humanoid armature missing")
if len(armature.data.bones) != 55:
    raise RuntimeError(f"saved humanoid bone count is {len(armature.data.bones)}, expected 55")


def snapshot(action_name, frame):
    action = actions[action_name]
    armature.animation_data.action = action
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()
    values = []
    for bone in armature.pose.bones:
        for row in bone.matrix_basis:
            values.extend(row)
    if not all(math.isfinite(value) for value in values):
        raise RuntimeError(f"non-finite pose in {action_name} at frame {frame}")
    return values


def assert_same(label, left, right, tolerance=1e-4):
    delta = max(abs(a - b) for a, b in zip(left, right))
    if delta > tolerance:
        raise RuntimeError(f"{label} boundary pop: matrix delta {delta}")


stand = snapshot("sit", 1)
seated = snapshot("sit", 36)
assert_same("sit to stand_up", seated, snapshot("stand_up", 1))
assert_same("stand_up to standing", stand, snapshot("stand_up", 36))
for name in ("idle_breathing", "listen", "talk_beats", "nod", "shrug", "think"):
    action = actions[name]
    assert_same(name, snapshot(name, int(action.frame_range[0])), snapshot(name, int(action.frame_range[1])))
rest = actions["rest"]
assert_same("rest", snapshot("rest", int(rest.frame_range[0])), snapshot("rest", int(rest.frame_range[1])))

face = bpy.data.objects.get("FaceMorphs")
shape_keys = set(face.data.shape_keys.key_blocks.keys()) if face and face.data.shape_keys else set()
expected_shapes = {"Basis", "aa", "ih", "ou", "ee", "oh", "blink", "neutral", "amused", "puzzled"}
if shape_keys != expected_shapes:
    raise RuntimeError(f"saved shape key set mismatch: {sorted(shape_keys)}")

print(f"BLEND_STRUCTURE actions={len(actions)} bones={len(armature.data.bones)} shape_keys={len(shape_keys) - 1} transition_boundaries=green")
