class_name PaperStack
extends Node3D
## 샌드위치표 다발 겉모습과 쌓이는 연출. 로직은 reset / add_bundle / add_sheets / collapse만 쓴다.
## 반민초 표 = 흰 종이 한 장씩, 민초 묶음 = 민트 띠지를 두른 흰 종이 덩어리(맨 위 묶음엔 민트 '卜' 도장).

signal sheet_landed ## 종이 한 장이 내려앉을 때마다

const PALETTE: Palette = preload("res://common/style/palette.tres")
const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const FALL_TIME: float = 0.12 # 종이 한 장이 떨어지는 시간
const DROP_FROM: float = 0.7 # 이만큼 위에서 떨어진다
const STICK_OUT_CHANCE: float = 0.12 # 옆으로 삐져나오는 종이 비율
const SLIDE_OFF_X: float = 5.6 # 버스트 때 종이가 미끄러져 나가는 거리. 탁자 반폭(5)보다 커야 한다

var bundle_xz: Vector2 = Vector2(3.2, 2.2)
var sheet_h: float = 0.06
var bundle_h: float = 0.25
var interval: float = 0.05 # 종이 사이 간격(초)

var _top_y: float = 0.0
var _sheets: Array[Node3D] = []


func reset(floor_y: float) -> void:
	for c in get_children():
		c.queue_free()
	_sheets.clear()
	_top_y = floor_y


## 민초 묶음을 한 덩어리로 툭 떨어뜨린다. 끝나면 돌아온다(await 가능)
func add_bundle(top: bool) -> void:
	var y: float = _top_y + bundle_h / 2.0
	_top_y += bundle_h
	var bundle: Node3D = Node3D.new()
	add_child(bundle)
	_add_box(bundle, Vector3(bundle_xz.x, bundle_h * 0.94, bundle_xz.y), Vector3.ZERO, PALETTE.paper.darkened(0.03))
	_add_box(bundle, Vector3(0.55, bundle_h + 0.02, bundle_xz.y + 0.02), Vector3.ZERO, PALETTE.mincho) # 띠지
	if top:
		var mark: Node3D = STAMP_MARK.instantiate()
		mark.ink = PALETTE.mincho.darkened(0.2)
		mark.scale = Vector3.ONE * 2.2
		mark.position = Vector3(-0.9, bundle_h / 2.0 + 0.005, 0.1)
		mark.rotation.y = randf_range(-0.3, 0.3)
		bundle.add_child(mark)
	bundle.position = Vector3(0, y + 2.0, 0)
	var t: Tween = create_tween()
	t.tween_property(bundle, "position:y", y, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(bundle, "scale", Vector3(1.03, 0.8, 1.03), 0.05) # 쿵: 살짝 눌렸다 펴짐
	t.tween_property(bundle, "scale", Vector3.ONE, 0.1)
	await t.finished


## 종이를 n장 한 장씩 떨어뜨린다. 모두 내려앉으면 돌아온다(await 가능)
func add_sheets(n: int) -> void:
	var last: Tween
	for i in n:
		last = _drop_sheet()
		if i < n - 1:
			await get_tree().create_timer(interval).timeout
	if last != null:
		await last.finished


## 버스트: 다발이 부르르 떨고 맨 위 종이 몇 장이 미끄러져 떨어진다
func collapse() -> void:
	var shake: Tween = create_tween()
	for i in 6:
		shake.tween_property(self, "position:x", 0.08 if i % 2 == 0 else -0.08, 0.04)
	shake.tween_property(self, "position:x", 0.0, 0.04)
	await shake.finished
	# 탁자 가장자리 밖까지 옆으로 미끄러진 뒤 아래로 떨어진다(탁자를 뚫지 않게 두 단계)
	var last: Tween
	var k: int = mini(8, _sheets.size())
	for i in k:
		var s: Node3D = _sheets[_sheets.size() - 1 - i]
		var dir: float = 1.0 if i % 3 != 0 else -1.0
		var t: Tween = create_tween()
		t.tween_interval(i * 0.05)
		t.tween_property(s, "position:x", dir * randf_range(SLIDE_OFF_X, SLIDE_OFF_X + 1.0), 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(s, "rotation:y", s.rotation.y + randf_range(-0.6, 0.6), 0.35)
		t.tween_property(s, "position:y", s.position.y - 8.0, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(s, "rotation:z", -dir * randf_range(0.8, 1.4), 0.4)
		last = t
	if last != null:
		await last.finished


func _drop_sheet() -> Tween:
	var y: float = _top_y + sheet_h / 2.0
	_top_y += sheet_h
	var sheet: Node3D = Node3D.new()
	add_child(sheet)
	_sheets.append(sheet)
	var shade: Color = PALETTE.paper.darkened(randf_range(0.0, 0.07)) # 장마다 미세하게 달라 옆면에 결이 생긴다
	_add_box(sheet, Vector3(bundle_xz.x * randf_range(0.97, 1.0), sheet_h * 0.85, bundle_xz.y * randf_range(0.97, 1.0)), Vector3.ZERO, shade)
	var rest_pos: Vector3 = Vector3(randf_range(-0.04, 0.04), y, randf_range(-0.04, 0.04))
	var rest_rot: Vector3 = Vector3(0, randf_range(-0.03, 0.03), 0)
	if randf() < STICK_OUT_CHANCE: # 삐져나온 종이: 한쪽으로 크게 밀리고 끝이 살짝 들림
		var along_x: bool = randf() < 0.6
		var push: float = randf_range(0.15, 0.35) * (1.0 if randf() < 0.5 else -1.0)
		rest_pos += Vector3(push, 0, 0) if along_x else Vector3(0, 0, push)
		rest_rot += Vector3(randf_range(-0.03, 0.03), randf_range(-0.15, 0.15), randf_range(-0.03, 0.03))
	sheet.position = rest_pos + Vector3(randf_range(-0.2, 0.2), DROP_FROM, randf_range(-0.1, 0.1))
	sheet.rotation = rest_rot + Vector3(randf_range(-0.25, 0.25), randf_range(-0.2, 0.2), randf_range(-0.25, 0.25))
	var t: Tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(sheet, "position", rest_pos, FALL_TIME)
	t.tween_property(sheet, "rotation", rest_rot, FALL_TIME)
	t.chain().tween_callback(sheet_landed.emit)
	return t


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
