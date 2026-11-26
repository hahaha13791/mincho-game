class_name BallotPaper
extends RigidBody3D
## 접힌 표 한 장. 몸 중심 기준 직사각형(Rect2) 조각을 이어 붙인 모양. 평면(z=0)에서만 움직인다.
## 충돌은 조각마다 상자. 겉모습은 한 번 접은 흰 종이: 한 면은 카메라를 보고 눕고, 나머지 면은 접힌 선에서
## 살짝 들려 V자로 벌어진다. 한 조각짜리는 반으로 접고, 여러 조각이면 첫 조각이 바닥 면, 나머지가 들린 면.

const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const DEPTH: float = 0.5 # 충돌 두께(z). 겉모습은 이보다 얇다
const SHEET_T: float = 0.04 # 종이 두께
const LIFT: float = deg_to_rad(15.0) # 들린 면이 카메라 쪽으로 벌어지는 각도
const STAMP_SCALE: float = 0.7

var rects: Array = []


## stamped = false면 기표 없이(뒤집힌 면). 여러 장 겹친 더미에서 기표가 어지럽게 겹치지 않게
func setup(shape: Array, paper: Color, ink: Color, stamped: bool = true) -> void:
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
	var base: Rect2 = rects[0]
	if rects.size() == 1: # 반으로 접기: 긴 쪽의 뒤쪽 절반이 들린 면
		if _vertical(base):
			_flap(Rect2(base.position.x, base.get_center().y, base.size.x, base.size.y / 2.0), mat)
			base.size.y /= 2.0
		else:
			_flap(Rect2(base.get_center().x, base.position.y, base.size.x / 2.0, base.size.y), mat)
			base.size.x /= 2.0
	for i in range(1, rects.size()):
		_flap(_visible_part(i), mat)
	var flat: MeshInstance3D = _sheet(base.size, mat)
	flat.position = Vector3(base.get_center().x, base.get_center().y, 0.0)
	add_child(flat)
	if not stamped:
		return
	var stamp: Node3D = STAMP_MARK.instantiate()
	stamp.ink = ink
	stamp.scale = Vector3.ONE * STAMP_SCALE
	stamp.rotation.x = PI / 2.0 # 원래 눕혀 찍는 자국이라 세워서 카메라 쪽(+z)을 보게
	stamp.position.z = SHEET_T / 2.0 + 0.01
	flat.add_child(stamp)


static func _vertical(r: Rect2) -> bool:
	return r.size.y > r.size.x


# 앞 조각과 겹치는 시작 부분을 잘라 낸다(ㄱ자 표가 한 장이 꺾여 접힌 것처럼 보이게). 충돌은 그대로
func _visible_part(i: int) -> Rect2:
	var r: Rect2 = rects[i]
	for j in i:
		var q: Rect2 = rects[j]
		if not r.intersects(q):
			continue
		if _vertical(r) and q.position.y <= r.position.y and q.end.y < r.end.y:
			r = Rect2(r.position.x, q.end.y, r.size.x, r.end.y - q.end.y)
		elif not _vertical(r) and q.position.x <= r.position.x and q.end.x < r.end.x:
			r = Rect2(q.end.x, r.position.y, r.end.x - q.end.x, r.size.y)
	return r


# 들린 면: r의 시작 변(왼쪽 또는 아래)이 접힌 선. 그 선을 축으로 카메라 쪽(+z)으로 LIFT만큼 들린다
func _flap(r: Rect2, mat: StandardMaterial3D) -> void:
	var hinge: Node3D = Node3D.new()
	var sheet: MeshInstance3D = _sheet(r.size, mat)
	if _vertical(r):
		hinge.position = Vector3(r.get_center().x, r.position.y, 0.0)
		hinge.rotation.x = LIFT
		sheet.position.y = r.size.y / 2.0
	else:
		hinge.position = Vector3(r.position.x, r.get_center().y, 0.0)
		hinge.rotation.y = -LIFT
		sheet.position.x = r.size.x / 2.0
	hinge.add_child(sheet)
	add_child(hinge)


func _sheet(size: Vector2, mat: StandardMaterial3D) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, SHEET_T)
	mesh.material = mat
	m.mesh = mesh
	return m


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
