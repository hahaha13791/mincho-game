class_name BallotPaper
extends RigidBody3D
## 접힌 표 한 장. 몸 중심 기준 직사각형(Rect2) 조각을 이어 붙인 모양. 평면(z=0)에서만 움직인다.
## 충돌은 조각마다 상자, 겉모습은 조각마다 병풍처럼 지그재그로 접힌 하얀 종이 + 민초 기표 하나.

const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const DEPTH: float = 0.5 # 충돌 두께(z). 겉모습은 이보다 얇다
const SHEET_T: float = 0.04 # 종이 두께
const FOLD_W: float = 0.5 # 접힌 면 하나의 폭(대략)
const FOLD_ANGLE: float = deg_to_rad(40.0) # 면이 번갈아 기울어 접힌 선이 명암으로 보인다
const STAMP_SCALE: float = 0.7

var rects: Array = []


func setup(shape: Array, paper: Color, ink: Color) -> void:
	rects = shape
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	var pm: PhysicsMaterial = PhysicsMaterial.new()
	pm.friction = 0.7
	pm.bounce = 0.0
	physics_material_override = pm
	for r: Rect2 in rects:
		var col: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = Vector3(r.size.x, r.size.y, DEPTH)
		col.shape = box
		col.position = Vector3(r.get_center().x, r.get_center().y, 0.0)
		add_child(col)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = paper
	mat.roughness = 1.0
	var panels: Array[MeshInstance3D] = []
	for i in rects.size():
		panels.append_array(_fold(_visible_part(i), mat))
	var stamp: Node3D = STAMP_MARK.instantiate()
	stamp.ink = ink
	stamp.scale = Vector3.ONE * STAMP_SCALE
	stamp.rotation.x = PI / 2.0 # 원래 눕혀 찍는 자국이라 세워서 카메라 쪽(+z)을 보게
	stamp.position.z = SHEET_T / 2.0 + 0.01
	panels.pick_random().add_child(stamp)


# 앞 조각과 겹치는 시작 부분을 잘라 낸다(ㄱ자 표가 한 장이 꺾여 접힌 것처럼 보이게). 충돌은 그대로
func _visible_part(i: int) -> Rect2:
	var r: Rect2 = rects[i]
	var vertical: bool = r.size.y > r.size.x
	for j in i:
		var q: Rect2 = rects[j]
		if not r.intersects(q):
			continue
		if vertical and q.position.y <= r.position.y and q.end.y < r.end.y:
			r = Rect2(r.position.x, q.end.y, r.size.x, r.end.y - q.end.y)
		elif not vertical and q.position.x <= r.position.x and q.end.x < r.end.x:
			r = Rect2(q.end.x, r.position.y, r.end.x - q.end.x, r.size.y)
	return r


# 긴 쪽을 따라 면 n개로 나눠 번갈아 ±FOLD_ANGLE 기울인다. 면 중심은 모두 z=0이라 이웃 면 끝이 접힌 선에서 만난다
func _fold(r: Rect2, mat: StandardMaterial3D) -> Array[MeshInstance3D]:
	var vertical: bool = r.size.y > r.size.x
	var length: float = r.size.y if vertical else r.size.x
	var n: int = maxi(2, roundi(length / FOLD_W))
	var w: float = length / n
	var out: Array[MeshInstance3D] = []
	for k in n:
		var m: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.material = mat
		var along: float = -length / 2.0 + w * (k + 0.5)
		var tilt: float = FOLD_ANGLE if k % 2 == 0 else -FOLD_ANGLE
		if vertical:
			mesh.size = Vector3(r.size.x, w / cos(FOLD_ANGLE), SHEET_T)
			m.position = Vector3(r.get_center().x, r.get_center().y + along, 0.0)
			m.rotation.x = tilt
		else:
			mesh.size = Vector3(w / cos(FOLD_ANGLE), r.size.y, SHEET_T)
			m.position = Vector3(r.get_center().x + along, r.get_center().y, 0.0)
			m.rotation.y = tilt
		m.mesh = mesh
		add_child(m)
		out.append(m)
	return out


## 대기 중인 표는 위치를 고정하고 충돌도 끈다 (집은 표나 쌓인 표를 밀어내지 않게)
func set_waiting(waiting: bool) -> void:
	freeze = waiting
	collision_layer = 0 if waiting else 1
	collision_mask = 0 if waiting else 1


## 월드 좌표 점이 이 표 위인지 (집을 때 사용)
func contains(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	for r: Rect2 in rects:
		if r.has_point(Vector2(local.x, local.y)):
			return true
	return false


## 현재 가장 높은 지점의 y (선 넘음 판정용)
func top_y() -> float:
	var top: float = -INF
	for r: Rect2 in rects:
		for corner: Vector2 in [r.position, r.end, Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y)]:
			top = maxf(top, to_global(Vector3(corner.x, corner.y, 0.0)).y)
	return top
