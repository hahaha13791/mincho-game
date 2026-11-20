extends Node3D
## 배부른 투표함(뱃속 패킹, id: ballot_box). 표 뭉치를 드래그해 투표함 격자를 채우고,
## 참관인이 도착하기 전에 뚜껑을 닫는다. 가로 x, 세로 y 평면(z=0)에서만 움직인다.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const GRID_W: int = 6
const GRID_H: int = 4
const GRID_ORIGIN: Vector3 = Vector3(-4.5, -1.5, 0.0) # 칸 (0,0)의 중심
const TRAY_POS: Vector3 = Vector3(5.0, 0.0, 0.0)
const LID_OPEN_Y: float = 4.2
const LID_CLOSED_Y: float = 2.2
const OBSERVER_FROM_X: float = -10.0
const OBSERVER_TO_X: float = -6.8
# 표 뭉치 모양: 2칸, 3칸, ㄱ자, 정사각형
const SHAPES: Array = [
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
]
const TUTORIAL_TEXT: String = "민초 표 뭉치를 끌어다 투표함 칸에 채우세요. (우클릭: 회전, 칸 밖에 놓으면 버림)\n쿵쿵 소리가 나면 참관인이 곧 도착합니다. 그 전에 [뚜껑 닫기]!\n목표 칸 수를 채우고 닫으면 성공."

@export var id: StringName = &"ballot_box"
@export var time_limit: float = 30.0
@export var target_fill: int = 18
@export var warn_range: Vector2 = Vector2(12.0, 24.0) # 발소리 시작 시점(초) 범위
@export var warn_lead: float = 2.0 # 발소리 → 도착
@export var safe_margin: float = 1.0 # 도착 전 이 시간 이상 남기고 닫으면 완전범죄

class Piece:
	var node: Node3D
	var shape: Array
	var origin: Vector2i
	var placed: bool = false
	var in_tray: bool = true
	var uid: int

var _grid: PackingGrid = PackingGrid.new(GRID_W, GRID_H)
var _pieces: Array[Piece] = []
var _held: Piece
var _held_offset: Vector3
var _prev_shape: Array
var _prev_placed: bool
var _prev_origin: Vector2i
var _next_uid: int = 0
var _state: State = State.TUTORIAL
var _elapsed: float = 0.0
var _warn_at: float = 0.0
var _body: MeshInstance3D
var _lid: MeshInstance3D
var _observer: MeshInstance3D
var _action: Callable

@onready var _camera: Camera3D = $Camera3D
@onready var _overlay: Control = $HUD/Overlay
@onready var _message: Label = $HUD/Overlay/Center/Box/Message
@onready var _action_button: Button = $HUD/Overlay/Center/Box/Action


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-35.0, 20.0, 0.0)
	_build_visuals()
	$HUD/CloseButton.pressed.connect(_on_close_pressed)
	_action_button.pressed.connect(func() -> void: _action.call())
	_show_overlay(TUTORIAL_TEXT, "시작", _start)


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	_elapsed += delta
	$HUD/TimerLabel.text = "%.1f" % maxf(time_limit - _elapsed, 0.0)
	if _elapsed >= _warn_at:
		$HUD/AlertLabel.visible = true
		var t: float = clampf((_elapsed - _warn_at) / warn_lead, 0.0, 1.0)
		_observer.position.x = lerpf(OBSERVER_FROM_X, OBSERVER_TO_X, t)
	if _elapsed >= _warn_at + warn_lead:
		_end(Grade.Rank.CAUGHT, "참관인이 뚜껑을 열었다. 표가 우르르 쏟아졌다.", false)
	elif _elapsed >= time_limit:
		_end(Grade.Rank.CAUGHT, "시간 초과. 참관인이 슬쩍 들여다봤다.", false)


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.PLAYING:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _held == null:
				_try_pick(_mouse_to_plane(mb.position))
			elif not mb.pressed and _held != null:
				_drop()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and _held != null:
			_held.shape = PackingGrid.rotated(_held.shape)
			_rebuild(_held)
	elif event is InputEventMouseMotion and _held != null:
		var mm: InputEventMouseMotion = event
		_held.node.position = _mouse_to_plane(mm.position) + _held_offset


func _start() -> void:
	_overlay.hide()
	_state = State.PLAYING
	_elapsed = 0.0
	_warn_at = randf_range(warn_range.x, warn_range.y)
	_spawn_tray_piece()
	_refresh()


func _on_close_pressed() -> void:
	if _state != State.PLAYING:
		return
	if _held != null:
		_drop()
	var margin: float = _warn_at + warn_lead - _elapsed
	var rank: Grade.Rank = BallotBoxRules.judge(_grid.filled(), target_fill, margin, safe_margin)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "참관인은 아무것도 눈치채지 못했다. 투표함이 조금 배불렀을 뿐."
		Grade.Rank.SUCCESS:
			msg = "아슬아슬! 뚜껑이 닫히는 순간 참관인이 들어왔다."
		_:
			msg = "투표함이 너무 홀쭉하다. 참관인이 고개를 갸웃한다."
	_end(rank, msg, true)


func _end(rank: Grade.Rank, msg: String, close_lid: bool) -> void:
	if _state == State.ENDED:
		return
	_state = State.ENDED
	if _held != null:
		_drop()
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	if close_lid:
		var tw: Tween = create_tween()
		tw.tween_property(_lid, "position:y", LID_CLOSED_Y, 0.25)
		await tw.finished
	_show_overlay("%s\n%s\n민초 %.1f%% → %.1f%%" % [Grade.NAMES[rank], msg, before, GameState.mincho_percent], "다시하기 (임시)", _restart)


# shortcut: 허브가 없어 결과 후 전체 초기화 + 재시작, 허브 단계에서 Flow.go_hub로 교체
func _restart() -> void:
	GameState.reset()
	get_tree().reload_current_scene()


func _show_overlay(text: String, button_text: String, action: Callable) -> void:
	_message.text = text
	_action_button.text = button_text
	_action = action
	_overlay.show()


# --- 표 뭉치 ---

func _spawn_tray_piece() -> void:
	var p: Piece = Piece.new()
	p.uid = _next_uid
	_next_uid += 1
	p.shape = (SHAPES.pick_random() as Array).duplicate()
	p.node = Node3D.new()
	p.node.position = TRAY_POS
	add_child(p.node)
	_pieces.append(p)
	_rebuild(p)


func _rebuild(p: Piece) -> void:
	for child in p.node.get_children():
		child.queue_free()
	for c: Vector2i in p.shape:
		var m: MeshInstance3D = _box(Vector3(0.94, 0.94, 0.5), PALETTE.mincho)
		m.position = Vector3(c.x, c.y, 0.25)
		p.node.add_child(m)


func _try_pick(point: Vector3) -> void:
	for i in range(_pieces.size() - 1, -1, -1):
		var p: Piece = _pieces[i]
		for c: Vector2i in p.shape:
			var cell: Vector3 = p.node.position + Vector3(c.x, c.y, 0.0)
			if absf(point.x - cell.x) < 0.5 and absf(point.y - cell.y) < 0.5:
				_hold(p, point)
				return


func _hold(p: Piece, point: Vector3) -> void:
	_held = p
	_held_offset = p.node.position - point
	_prev_shape = p.shape.duplicate()
	_prev_placed = p.placed
	_prev_origin = p.origin
	if p.placed:
		_grid.remove(p.uid)
		p.placed = false
		_refresh()


func _drop() -> void:
	var p: Piece = _held
	_held = null
	var o: Vector2i = Vector2i(roundi(p.node.position.x - GRID_ORIGIN.x), roundi(p.node.position.y - GRID_ORIGIN.y))
	if _grid.can_place(p.shape, o):
		_put(p, o)
		if p.in_tray:
			p.in_tray = false
			_spawn_tray_piece()
	elif _near_grid(p.node.position):
		_restore(p)
	else:
		_pieces.erase(p)
		p.node.queue_free()
		if p.in_tray:
			_spawn_tray_piece()
	_refresh()


func _put(p: Piece, o: Vector2i) -> void:
	p.origin = o
	p.placed = true
	_grid.place(p.shape, o, p.uid)
	p.node.position = GRID_ORIGIN + Vector3(o.x, o.y, 0.0)


func _restore(p: Piece) -> void:
	p.shape = _prev_shape
	_rebuild(p)
	if _prev_placed:
		_put(p, _prev_origin)
	else:
		p.node.position = TRAY_POS


func _near_grid(pos: Vector3) -> bool:
	var rel: Vector3 = pos - GRID_ORIGIN
	return rel.x > -2.5 and rel.x < GRID_W + 1.5 and rel.y > -2.5 and rel.y < GRID_H + 1.5


func _refresh() -> void:
	var fill: int = _grid.filled()
	$HUD/FillLabel.text = "%d / %d칸 (목표 %d)" % [fill, GRID_W * GRID_H, target_fill]
	var bulge: float = 1.0 + 0.12 * float(fill) / float(GRID_W * GRID_H)
	_body.scale = Vector3(bulge, bulge, 1.0)


# --- 화면 ---

func _mouse_to_plane(pos: Vector2) -> Vector3:
	var hit: Variant = Plane(Vector3.BACK, 0.0).intersects_ray(_camera.project_ray_origin(pos), _camera.project_ray_normal(pos))
	return hit if hit != null else Vector3.ZERO


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material = mat
	m.mesh = mesh
	return m


# 겉모습은 이 함수에만 모아 두어 스타일 확정 때 한 곳에서 교체한다
func _build_visuals() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PALETTE.background
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	_body = _box(Vector3(GRID_W + 0.4, GRID_H + 0.4, 0.2), PALETTE.anti_mincho)
	_body.position = GRID_ORIGIN + Vector3((GRID_W - 1) / 2.0, (GRID_H - 1) / 2.0, -0.3)
	add_child(_body)
	for x in GRID_W:
		for y in GRID_H:
			var cell: MeshInstance3D = _box(Vector3(0.94, 0.94, 0.05), PALETTE.anti_mincho.darkened(0.3))
			cell.position = GRID_ORIGIN + Vector3(x, y, -0.15)
			add_child(cell)

	_lid = _box(Vector3(GRID_W + 0.6, 0.4, 1.0), PALETTE.paper)
	_lid.position = Vector3(GRID_ORIGIN.x + (GRID_W - 1) / 2.0, LID_OPEN_Y, 1.2)
	add_child(_lid)

	_observer = _box(Vector3(1.0, 2.0, 1.0), PALETTE.danger)
	_observer.position = Vector3(OBSERVER_FROM_X, 0.0, 0.0)
	add_child(_observer)
