"""하얀 인형 OBJ(body, shirt, hat)에 뼈대와 애니메이션(walk, idle)을 붙여 ../figure.glb로 내보낸다.

먼저 Godot으로 res://assets/figure/build_figure.gd를 실행해 OBJ를 만든 뒤:
  blender -b --factory-startup -P assets/figure/src/rig_figure.py

좌표: OBJ는 Godot 좌표(y 위, +z 앞). 불러오면 블렌더 좌표(x, -z, y)가 되어 캐릭터는 -Y를 본다.
"""
import math
import os

import bpy
from mathutils import Quaternion, Vector

SRC = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(SRC, "..", "figure.glb"))
FRAMES = 24  # 걷기 한 주기(두 걸음). 24fps 기준 1초


def B(x, y, z):
    """Godot 좌표 -> 블렌더 좌표"""
    return Vector((x, -z, y))


# 이름: (머리, 꼬리, 부모)
BONES = {
    "hips": (B(0, 0.55, 0), B(0, 0.72, 0), None),
    "spine": (B(0, 0.72, 0), B(0, 1.1, 0), "hips"),
    "head": (B(0, 1.1, 0), B(0, 1.7, 0), "spine"),
}
for side, sx in (("L", 1.0), ("R", -1.0)):
    BONES["upper_arm." + side] = (B(0.2 * sx, 1.05, 0), B(0.265 * sx, 0.8, 0), "spine")
    BONES["forearm." + side] = (B(0.265 * sx, 0.8, 0), B(0.29 * sx, 0.5, 0.04), "upper_arm." + side)
    BONES["thigh." + side] = (B(0.095 * sx, 0.68, 0), B(0.095 * sx, 0.4, 0.01), "hips")
    BONES["shin." + side] = (B(0.095 * sx, 0.4, 0.01), B(0.1 * sx, 0.0, 0.05), "thigh." + side)


def load(name, ratio):
    bpy.ops.wm.obj_import(filepath=os.path.join(SRC, name.lower() + ".obj"))
    ob = bpy.context.selected_objects[0]
    ob.name = name
    ob.data.name = name
    bpy.context.view_layer.objects.active = ob
    # OBJ 가져오기는 축 변환을 오브젝트 회전으로 넣는다. 가중치 계산이 꼭짓점 좌표를 쓰므로 메시에 굳힌다
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    mod = ob.modifiers.new("decimate", "DECIMATE")
    mod.ratio = ratio
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.ops.object.shade_smooth()
    return ob


def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.dot(ab)))
    return (p - (a + ab * t)).length


def skin(ob, arm, only=None):
    """가까운 뼈 2개에 거리 기반 가중치. 왼쪽 꼭짓점은 오른쪽 팔다리 뼈를 받지 않는다(반대도 같음)"""
    groups = {name: ob.vertex_groups.new(name=name) for name in BONES}
    for v in ob.data.vertices:
        if only:
            groups[only].add([v.index], 1.0, "REPLACE")
            continue
        p = v.co
        cands = []
        for name, (a, b, _) in BONES.items():
            if name.endswith(".R") and p.x > 0.03 or name.endswith(".L") and p.x < -0.03:
                continue
            cands.append((seg_dist(p, a, b), name))
        cands.sort()
        ws = [(1.0 / (d + 0.01) ** 6, n) for d, n in cands[:2]]
        total = sum(w for w, _ in ws)
        for w, n in ws:
            groups[n].add([v.index], w / total, "REPLACE")
    mod = ob.modifiers.new("armature", "ARMATURE")
    mod.object = arm
    ob.parent = arm


def build_armature():
    data = bpy.data.armatures.new("Armature")
    arm = bpy.data.objects.new("Armature", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (a, b, parent) in BONES.items():
        eb = data.edit_bones.new(name)
        eb.head = a
        eb.tail = b
    for name, (_, _, parent) in BONES.items():
        if parent:
            data.edit_bones[name].parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return arm


def swing(arm, name, angle, frame):
    """캐릭터 좌우 축(블렌더 X) 기준 회전. 양수 = 아래로 뻗은 부위가 뒤(+Y)로 간다"""
    pb = arm.pose.bones[name]
    rest = pb.bone.matrix_local.to_quaternion()
    pb.rotation_quaternion = rest.inverted() @ Quaternion((1, 0, 0), angle) @ rest
    pb.keyframe_insert("rotation_quaternion", frame=frame)


def make_action(arm, name, pose):
    act = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = act
    for f in range(0, FRAMES + 1, 3):
        pose(arm, f, 2 * math.pi * f / FRAMES)
    track = arm.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, act)
    arm.animation_data.action = None


def walk_pose(arm, f, ph):
    s, c = math.sin(ph), math.cos(ph)
    swing(arm, "thigh.L", -0.45 * s, f)
    swing(arm, "thigh.R", 0.45 * s, f)
    # 다리를 앞으로 가져오는 동안 무릎을 굽힌다
    swing(arm, "shin.L", 0.7 * max(0.0, c), f)
    swing(arm, "shin.R", 0.7 * max(0.0, -c), f)
    swing(arm, "upper_arm.L", 0.35 * s, f)
    swing(arm, "upper_arm.R", -0.35 * s, f)
    swing(arm, "forearm.L", -0.25, f)
    swing(arm, "forearm.R", -0.25, f)
    hips = arm.pose.bones["hips"]
    hips.location = (0, 0.025 * math.cos(2 * ph), 0)  # 뼈 로컬 Y = 위. 다리가 모일 때 높아진다
    hips.keyframe_insert("location", frame=f)


def idle_pose(arm, f, ph):
    for name in BONES:
        if name != "hips":
            swing(arm, name, -0.25 if name.startswith("forearm") else 0.0, f)
    hips = arm.pose.bones["hips"]
    hips.location = (0, 0.006 * math.cos(ph), 0)  # 숨쉬듯 살짝
    hips.keyframe_insert("location", frame=f)


AXES = {"X": (1, 0, 0), "Y": (0, 1, 0), "Z": (0, 0, 1)}


def turn(arm, name, rots, frame):
    """블렌더 월드 축 기준 회전 여러 개를 차례로 적용(캐릭터는 -Y를 본다).
    X: 아래로 뻗은 팔다리는 음수 = 앞으로 / 위로 뻗은 척추·머리는 양수 = 앞으로 숙임
    Y: 팔 벌리기(왼팔 음수, 오른팔 양수 = 바깥으로) / 머리는 양수 = 왼쪽(+x)으로 갸웃
    Z: 몸·머리 돌리기(양수 = 왼쪽(+x)을 봄)"""
    q = Quaternion()
    for axis, angle in rots:
        q = Quaternion(AXES[axis], angle) @ q
    pb = arm.pose.bones[name]
    rest = pb.bone.matrix_local.to_quaternion()
    pb.rotation_quaternion = rest.inverted() @ q @ rest
    pb.keyframe_insert("rotation_quaternion", frame=frame)


def act_pose(spec):
    """spec(ph) -> {뼈 이름: [(축, 각도), ...]}. 적지 않은 뼈는 기본 자세"""
    def pose(arm, f, ph):
        rots = spec(ph)
        for name in BONES:
            if name != "hips":
                turn(arm, name, rots.get(name, []), f)
        hips = arm.pose.bones["hips"]
        hips.location = (0, 0.006 * math.cos(ph), 0)  # 숨쉬듯 살짝
        hips.keyframe_insert("location", frame=f)
    return pose


# 작전본부실 주인공의 작전 행동. 소품(커피잔·전화기 등)은 Godot에서 오른손(forearm.R 끝)에 붙인다
ACTS = {
    # 턱 괴고 구상: 오른손을 턱에, 왼팔은 배 앞으로
    "think": lambda ph: {
        "upper_arm.R": [("X", -1.2), ("Y", -0.35)], "forearm.R": [("X", -2.2)],
        "upper_arm.L": [("X", -0.55), ("Y", 0.45)], "forearm.L": [("X", -1.5)],
        "head": [("X", 0.12), ("Y", 0.08 * math.sin(ph))], "spine": [("X", 0.05)],
    },
    # 지시봉으로 보드를 탁탁 짚기
    "point": lambda ph: {
        "upper_arm.R": [("X", -2.45), ("Y", 0.15)], "forearm.R": [("X", -0.15 - 0.2 * max(0.0, math.sin(2 * ph)))],
        "upper_arm.L": [("Y", -0.35)], "forearm.L": [("X", -1.9)],
        "head": [("X", -0.3)], "spine": [("X", -0.08)],
    },
    # 커피 들고 보드 노려보기(가끔 홀짝)
    "coffee": lambda ph: {
        "upper_arm.R": [("X", -0.45 - 0.35 * max(0.0, math.sin(ph))), ("Y", -0.15)], "forearm.R": [("X", -1.7)],
        "upper_arm.L": [("X", -0.1)], "forearm.L": [("X", -0.3)],
        "head": [("X", 0.05)],
    },
    # 책상에 지도를 펴고 몸을 숙여 살피기
    "map": lambda ph: {
        "spine": [("X", 0.55)], "head": [("X", 0.35), ("Z", 0.2 * math.sin(ph))],
        "upper_arm.L": [("X", -1.0), ("Y", -0.25)], "forearm.L": [("X", -0.3)],
        "upper_arm.R": [("X", -1.0), ("Y", 0.25)], "forearm.R": [("X", -0.3)],
    },
    # 전화기를 귀에 대고 몰래 통화
    "phone": lambda ph: {
        "upper_arm.R": [("X", -0.35), ("Y", 0.55)], "forearm.R": [("X", -2.6)],
        "upper_arm.L": [("Y", -0.4)], "forearm.L": [("X", -1.9)],
        "head": [("Y", -0.15), ("Z", 0.12 * math.sin(ph))],
    },
    # 의자 위에서 높은 곳에 핀 꽂기
    "pin": lambda ph: {
        "upper_arm.R": [("X", -2.9), ("Y", 0.1)], "forearm.R": [("X", -0.1 - 0.15 * max(0.0, math.sin(2 * ph)))],
        "upper_arm.L": [("X", -0.4)], "forearm.L": [("X", -0.8)],
        "head": [("X", -0.35)], "spine": [("X", -0.1)],
    },
    # 돋보기로 메모 들여다보기
    "magnifier": lambda ph: {
        "upper_arm.R": [("X", -1.1), ("Y", -0.1)], "forearm.R": [("X", -1.4)],
        "upper_arm.L": [("X", -0.4), ("Y", 0.2)], "forearm.L": [("X", -1.3)],
        "head": [("X", 0.05), ("Z", 0.15 * math.sin(ph))], "spine": [("X", 0.1)],
    },
    # 메모장에 끄적이기
    "write": lambda ph: {
        "spine": [("X", 0.3)], "head": [("X", 0.4)],
        "upper_arm.R": [("X", -0.7), ("Y", -0.1)], "forearm.R": [("X", -1.0 - 0.12 * math.sin(4 * ph))],
        "upper_arm.L": [("X", -0.6), ("Y", 0.2)], "forearm.L": [("X", -1.0)],
    },
}


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 24
    arm = build_armature()
    skin(load("Body", 0.25), arm)
    skin(load("Shirt", 0.7), arm)
    skin(load("Hat", 0.35), arm, only="head")
    skin(load("Jacket", 0.5), arm)
    skin(load("Pants", 0.5), arm)
    skin(load("Tie", 1.0), arm, only="spine")
    skin(load("Sunglasses", 1.0), arm, only="head")
    skin(load("Armband", 0.5), arm, only="upper_arm.L")
    skin(load("Headband", 0.6), arm, only="head")
    skin(load("Fedora", 0.5), arm, only="head")
    skin(load("Coat", 0.5), arm)
    skin(load("Badge", 1.0), arm, only="spine")
    make_action(arm, "walk", walk_pose)
    make_action(arm, "idle", idle_pose)
    for name, spec in ACTS.items():
        make_action(arm, name, act_pose(spec))
    bpy.ops.export_scene.gltf(
        filepath=OUT,
        export_format="GLB",
        export_yup=True,
        export_animations=True,
        export_skins=True,
        export_materials="NONE",
    )
    print("EXPORTED", OUT, {o.name: len(o.data.vertices) for o in bpy.data.objects if o.type == "MESH"})


main()
