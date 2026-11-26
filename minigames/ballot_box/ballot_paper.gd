class_name BallotPaper
extends RigidBody3D
## 접힌 표 한 장. 몸 중심 기준 직사각형(Rect2) 조각을 이어 붙인 모양. 평면(z=0)에서만 움직인다.
## 충돌은 조각마다 상자. 겉모습은 모양마다 접힌 단서(겹친 단 + 그림자, 접힌 가장자리, 뒷면 색)를 넣는다:
##   ㄱ자 = 띠를 45° 대각선으로 꺾은 쪽지 / 긴 띠 = 끝을 접어 넘긴 두 겹 / 네모 = 반 접은 선 + 귀퉁이 접힘.
## 종이는 카메라(+z)를 보고, 위에 덮인 겹일수록 z가 크다.

const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const DEPTH: float = 0.5 # 충돌 두께(z). 겉모습은 이보다 얇다
const SHEET_T: float = 0.06 # 종이 한 겹 두께. 겹친 단이 정면에서도 보이게 실제보다 두껍게
const SHADOW_OFFSET: Vector2 = Vector2(0.035, -0.035) # 윗겹이 아랫겹에 드리우는 그림자(오른쪽 아래)
const STRIP_COVER: float = 0.55 # 긴 띠에서 접어 넘긴 윗겹이 덮는 길이 비율
const DOG_EAR: float = 0.35 # 네모 표 귀퉁이 접힌 크기
const STAMP_SCALE: float = 0.7

var rects: Array = []
var _front: StandardMaterial3D
var _back: StandardMaterial3D # 접혀서 뒤집힌 면
var _shade: StandardMaterial3D # 겹친 단 그림자·접힌 선


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
	_front = _mat(paper)
	_back = _mat(paper.darkened(0.16)) # 조명을 받으면 거의 하얘져서 이 정도는 어둡게 해야 앞면과 갈린다
	_shade = _mat(paper.darkened(0.35))
	var stamp_at: Vector2
	if rects.size() == 2:
		stamp_at = _build_note(rects[0], rects[1])
	elif rects[0].size.x >= rects[0].size.y * 2.5:
		stamp_at = _build_strip(rects[0])
	else:
		stamp_at = _build_square(rects[0])
	if not stamped:
		return
	var stamp: Node3D = STAMP_MARK.instantiate()
	stamp.ink = ink
	stamp.scale = Vector3.ONE * STAMP_SCALE
	stamp.rotation.x = PI / 2.0 # 원래 눕혀 찍는 자국이라 세워서 카메라 쪽(+z)을 보게
	stamp.position = Vector3(stamp_at.x, stamp_at.y, SHEET_T / 2.0 + 0.01)
	add_child(stamp)


# ㄱ자: 가로 팔(앞면, 아랫겹)에서 45° 대각선으로 꺾여 세로 팔(뒷면, 윗겹)로 이어진다.
# 겹치는 네모 칸의 바깥 모서리 O와 안쪽 모서리 I를 잇는 대각선이 접힌 선. 기표 위치를 돌려준다
func _build_note(a: Rect2, b: Rect2) -> Vector2:
	var h: Rect2 = a if a.size.x >= a.size.y else b
	var v: Rect2 = b if h == a else a
	var q: Rect2 = h.intersection(v)
	var hx: float = signf(h.get_center().x - q.get_center().x) # 가로 팔이 뻗는 쪽
	var vy: float = signf(v.get_center().y - q.get_center().y) # 세로 팔이 뻗는 쪽
	var o: Vector2 = q.get_center() - Vector2(hx * q.size.x, vy * q.size.y) / 2.0
	var i: Vector2 = q.get_center() + Vector2(hx * q.size.x, vy * q.size.y) / 2.0
	var hf: float = h.end.x if hx > 0.0 else h.position.x
	var vf: float = v.end.y if vy > 0.0 else v.position.y
	_slab(PackedVector2Array([o, Vector2(hf, o.y), Vector2(hf, i.y), i]), 0.0, _front)
	_layer(PackedVector2Array([o, i, Vector2(i.x, vf), Vector2(o.x, vf)]))
	return Vector2((i.x + hf) / 2.0, h.get_center().y)


# 긴 띠: 왼쪽 끝을 접어 넘겨 윗겹(뒷면)이 앞쪽 STRIP_COVER만큼 덮는다. 접힌 끝은 둥글게 말린 가장자리
# shortcut: 가로로 긴 띠만 가정(SHAPES가 다 가로). 세로 띠를 넣으면 축을 바꿔 그려야 한다
func _build_strip(r: Rect2) -> Vector2:
	_slab(_rect_poly(r), 0.0, _front)
	var cover: float = r.size.x * STRIP_COVER
	_layer(_rect_poly(Rect2(r.position.x + SHEET_T, r.position.y, cover - SHEET_T, r.size.y)))
	var fold: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new() # 세로축 원기둥 = 위아래 겹을 잇는 말린 끝
	cyl.top_radius = SHEET_T
	cyl.bottom_radius = SHEET_T
	cyl.height = r.size.y
	cyl.radial_segments = 12
	cyl.material = _back
	fold.mesh = cyl
	fold.position = Vector3(r.position.x + SHEET_T, r.get_center().y, SHEET_T / 2.0)
	add_child(fold)
	return Vector2((r.position.x + cover + r.end.x) / 2.0, r.get_center().y)


# 네모: 가운데 가로로 반 접은 선(얇은 홈) + 오른쪽 위 귀퉁이를 안쪽으로 접어 뒷면 삼각형이 보인다
func _build_square(r: Rect2) -> Vector2:
	var x0: float = r.position.x
	var y0: float = r.position.y
	var x1: float = r.end.x
	var y1: float = r.end.y
	_slab(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1 - DOG_EAR), Vector2(x1 - DOG_EAR, y1), Vector2(x0, y1)]), 0.0, _front)
	# 잘린 귀퉁이를 대각선에 대해 뒤집은 삼각형
	_layer(PackedVector2Array([Vector2(x1, y1 - DOG_EAR), Vector2(x1 - DOG_EAR, y1), Vector2(x1 - DOG_EAR, y1 - DOG_EAR)]))
	var crease: MeshInstance3D = _slab(_rect_poly(Rect2(x0, r.get_center().y - 0.015, r.size.x, 0.03)), 0.0, _shade)
	crease.position.z = 0.003 # 앞면 바로 위
	return Vector2(r.get_center().x - r.size.x * 0.15, (y0 + r.get_center().y) / 2.0)


# 아랫겹 위에 덮인 윗겹(뒷면 색) + 아래로 비껴 드리운 그림자
func _layer(poly: PackedVector2Array) -> void:
	var shadow: PackedVector2Array = []
	for p in poly:
		shadow.append(p + SHADOW_OFFSET)
	_slab(shadow, SHEET_T * 0.5, _shade)
	_slab(poly, SHEET_T, _back)


# 다각형 poly를 SHEET_T 두께로 뽑은 판. z = 두께 중심
func _slab(poly: PackedVector2Array, z: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front: float = z + SHEET_T / 2.0
	var back: float = z - SHEET_T / 2.0
	var tris: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	for t in range(0, tris.size(), 3):
		var p: Array[Vector2] = [poly[tris[t]], poly[tris[t + 1]], poly[tris[t + 2]]]
		_tri(st, Vector3(p[0].x, p[0].y, front), Vector3(p[1].x, p[1].y, front), Vector3(p[2].x, p[2].y, front), Vector3.BACK)
		_tri(st, Vector3(p[0].x, p[0].y, back), Vector3(p[1].x, p[1].y, back), Vector3(p[2].x, p[2].y, back), Vector3.FORWARD)
	var center: Vector2 = Vector2.ZERO
	for p in poly:
		center += p / poly.size()
	for k in poly.size():
		var a: Vector2 = poly[k]
		var b: Vector2 = poly[(k + 1) % poly.size()]
		var n2: Vector2 = (b - a).orthogonal().normalized()
		if n2.dot((a + b) / 2.0 - center) < 0.0:
			n2 = -n2
		var n: Vector3 = Vector3(n2.x, n2.y, 0.0)
		_tri(st, Vector3(a.x, a.y, front), Vector3(b.x, b.y, front), Vector3(b.x, b.y, back), n)
		_tri(st, Vector3(a.x, a.y, front), Vector3(b.x, b.y, back), Vector3(a.x, a.y, back), n)
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = mat
	add_child(m)
	return m


# Godot는 시계 방향 감김을 앞면으로 본다. 법선 n 쪽에서 봐서 시계 방향이 되게 순서를 맞춘다
# (반대면 양면 재질이 법선을 뒤집어 어둡게 칠한다)
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	var order: PackedVector3Array = [a, b, c]
	if (b - a).cross(c - a).dot(n) > 0.0:
		order = [a, c, b]
	for v in order:
		st.set_normal(n)
		st.add_vertex(v)


static func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func _mat(color: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # 다각형 감김 방향과 상관없이 보이게
	return mat


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
