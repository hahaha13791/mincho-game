extends Node3D
## 배부른 투표함(id: ballot_box). 접힌 표를 마우스로 끌어다 투표함에 떨어뜨려 쌓고,
## 참관인이 도착하기 전에 뚜껑을 닫는다. 선을 넘게 쌓으면 뚜껑이 안 닫힌다. 가로 x, 세로 y 평면(z=0)에서만 움직인다.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const BOX_CENTER_X: float = -2.0
const BOX_W: float = 6.0 # 안쪽 폭
const BOX_H: float = 4.0 # 안쪽 높이. 윗면이 선(뚜껑 높이)
const FLOOR_Y: float = -2.0
const LINE_Y: float = FLOOR_Y + BOX_H
const WALL_T: float = 0.4
const TRAY_POS: Vector3 = Vector3(5.0, 0.0, 0.0)
const LID_OPEN_Y: float = 4.2
const LID_CLOSED_Y: float = 2.2
const OBSERVER_FROM_X: float = -10.0
const OBSERVER_TO_X: float = -6.8
const KILL_Y: float = -8.0
const GRAB_GAIN: float = 25.0 # 집은 표가 마우스를 따라오는 속도 (거리 × 이 값)
const MAX_GRAB_SPEED: float = 30.0
# 접힌 표 모양: 몸 중심 기준 직사각형 조각들
const SHAPES: Array = [
	[Rect2(-1.0, -0.25, 2.0, 0.5)],
	[Rect2(-1.5, -0.25, 3.0, 0.5)],
	[Rect2(-0.75, -0.5, 1.5, 1.0)],
	[Rect2(-0.75, -0.25, 1.5, 0.5), Rect2(-0.75, -0.25, 0.5, 1.25)],
]
const TUTORIAL_TEXT: String = "접힌 민초 표를 끌어다 투표함에 떨어뜨려 쌓으세요.\n쿵쿵 소리가 나면 참관인이 곧 도착합니다. 그 전에 [뚜껑 닫기]!\n목표 장수를 넣고, 선을 넘지 않게 쌓아야 뚜껑이 닫힙니다."

@export var id: StringName = &"ballot_box"
@export var time_limit: float = 30.0
@export var target_papers: int = 6
@export var warn_range: Vector2 = Vector2(12.0, 24.0) # 발소리 시작 시점(초) 범위
@export var warn_lead: float = 2.0 # 발소리 → 도착
@export var safe_margin: float = 1.0 # 도착 전 이 시간 이상 남기고 닫으면 완전범죄

var _papers: Array[BallotPaper] = []
var _tray: BallotPaper
var _held: BallotPaper
var _held_offset: Vector3
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
	_refresh()
	if _elapsed >= _warn_at:
		$HUD/AlertLabel.visible = true
		var t: float = clampf((_elapsed - _warn_at) / warn_lead, 0.0, 1.0)
		_observer.position.x = lerpf(OBSERVER_FROM_X, OBSERVER_TO_X, t)
	if _elapsed >= _warn_at + warn_lead:
		_end(Grade.Rank.CAUGHT, "참관인이 뚜껑을 열었다. 표가 우르르 쏟아졌다.", false)
	elif _elapsed >= time_limit:
		_end(Grade.Rank.CAUGHT, "시간 초과. 참관인이 슬쩍 들여다봤다.", false)


func _physics_process(_delta: float) -> void:
	if _held != null:
		# 위치를 직접 대입하면 물리 엔진이 덮어쓰므로, 속도로 마우스 쪽으로 끌어온다 (쌓인 표도 통과하지 않음)
		var target: Vector3 = _mouse_to_plane(get_viewport().get_mouse_position()) + _held_offset
		_held.linear_velocity = ((target - _held.position) * GRAB_GAIN).limit_length(MAX_GRAB_SPEED)
		_held.angular_velocity = Vector3.ZERO
	for p in _papers.duplicate():
		if p != _held and p != _tray and p.position.y < KILL_Y:
			_papers.erase(p)
			p.queue_free()


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


func _start() -> void:
	_overlay.hide()
	_state = State.PLAYING
	_elapsed = 0.0
	_warn_at = randf_range(warn_range.x, warn_range.y)
	_spawn_tray_paper()
	_refresh()


func _on_close_pressed() -> void:
	if _state != State.PLAYING:
		return
	if _held != null:
		_drop()
	var inside: Array[BallotPaper] = _in_box()
	var overflow: bool = _overflows(inside)
	var margin: float = _warn_at + warn_lead - _elapsed
	var rank: Grade.Rank = BallotBoxRules.judge(inside.size(), target_papers, overflow, margin, safe_margin)
	var msg: String
	if overflow:
		msg = "표가 선을 넘었다. 뚜껑이 닫히지 않는다. 참관인이 빙긋 웃는다."
	else:
		match rank:
			Grade.Rank.PERFECT:
				msg = "참관인은 아무것도 눈치채지 못했다. 투표함이 조금 배불렀을 뿐."
			Grade.Rank.SUCCESS:
				msg = "아슬아슬! 뚜껑이 닫히는 순간 참관인이 들어왔다."
			_:
				msg = "투표함이 너무 홀쭉하다. 참관인이 고개를 갸웃한다."
	_end(rank, msg, not overflow)


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


# --- 표 ---

func _spawn_tray_paper() -> void:
	var p: BallotPaper = BallotPaper.new()
	p.setup(SHAPES.pick_random(), PALETTE.mincho)
	p.freeze = true # 집어서 놓기 전까지 대기
	p.position = TRAY_POS
	add_child(p)
	_papers.append(p)
	_tray = p


func _try_pick(point: Vector3) -> void:
	for i in range(_papers.size() - 1, -1, -1):
		var p: BallotPaper = _papers[i]
		if p.contains(point):
			_held = p
			_held_offset = p.position - point
			p.freeze = false
			p.gravity_scale = 0.0
			p.linear_velocity = Vector3.ZERO
			p.angular_velocity = Vector3.ZERO
			if p == _tray:
				_spawn_tray_paper()
			return


func _drop() -> void:
	_held.gravity_scale = 1.0
	_held = null


# 투표함 안에 있는 표 (집은 표와 대기 표는 제외)
func _in_box() -> Array[BallotPaper]:
	var out: Array[BallotPaper] = []
	for p in _papers:
		if p != _held and p != _tray and absf(p.position.x - BOX_CENTER_X) < BOX_W / 2.0 and p.position.y > FLOOR_Y:
			out.append(p)
	return out


# shortcut: 아직 움직이는 표도 현재 위치로 판정, 닫는 순간 흔들리는 표가 억울하면 속도 조건 추가
func _overflows(inside: Array[BallotPaper]) -> bool:
	for p in inside:
		if p.top_y() > LINE_Y + 0.02:
			return true
	return false


func _refresh() -> void:
	var inside: Array[BallotPaper] = _in_box()
	$HUD/FillLabel.text = "%d / %d장%s" % [inside.size(), target_papers, "  (선 넘음!)" if _overflows(inside) else ""]
	var bulge: float = 1.0 + 0.12 * minf(float(inside.size()) / float(target_papers), 1.0)
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


func _wall(size: Vector3, pos: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.add_child(_box(size, PALETTE.anti_mincho))
	body.position = pos
	add_child(body)


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

	var mid_y: float = FLOOR_Y + BOX_H / 2.0
	var side_x: float = BOX_W / 2.0 + WALL_T / 2.0
	_wall(Vector3(WALL_T, BOX_H, 1.0), Vector3(BOX_CENTER_X - side_x, mid_y, 0.0))
	_wall(Vector3(WALL_T, BOX_H, 1.0), Vector3(BOX_CENTER_X + side_x, mid_y, 0.0))
	_wall(Vector3(BOX_W + 2.0 * WALL_T, WALL_T, 1.0), Vector3(BOX_CENTER_X, FLOOR_Y - WALL_T / 2.0, 0.0))

	_body = _box(Vector3(BOX_W, BOX_H, 0.2), PALETTE.anti_mincho.darkened(0.3))
	_body.position = Vector3(BOX_CENTER_X, mid_y, -0.4)
	add_child(_body)

	var line: MeshInstance3D = _box(Vector3(BOX_W + 2.0 * WALL_T, 0.06, 0.05), PALETTE.danger)
	line.position = Vector3(BOX_CENTER_X, LINE_Y, 0.4)
	add_child(line)

	_lid = _box(Vector3(BOX_W + 0.6, 0.4, 1.0), PALETTE.paper)
	_lid.position = Vector3(BOX_CENTER_X, LID_OPEN_Y, 1.2)
	add_child(_lid)

	_observer = _box(Vector3(1.0, 2.0, 1.0), PALETTE.danger)
	_observer.position = Vector3(OBSERVER_FROM_X, 0.0, 0.0)
	add_child(_observer)
