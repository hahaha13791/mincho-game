extends Node3D
## 사라지는 잉크(id: vanishing_ink). 마우스를 누르는 동안 다리미를 댄다. 김이 나면 기표가 지워진 것이고,
## 그 뒤 테두리가 타기 전에 떼야 성공. 한 번 떼면 그 라운드는 끝이다.

enum State { TUTORIAL, READY, IRONING, BETWEEN, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: IroningConfig = preload("res://minigames/vanishing_ink/ironing_config.tres")
const PAPER_SIZE: Vector3 = Vector3(4.0, 0.1, 3.0)
const INNER_SIZE: Vector3 = Vector3(3.5, 0.12, 2.5)
const IRON_REST_Y: float = 1.6
const IRON_PRESS_Y: float = 0.45
const BETWEEN_TIME: float = 1.2
const TUTORIAL_TEXT: String = "반민초 표의 기표를 지우세요. 마우스를 누르고 있으면 다리미가 내려갑니다.\n김이 나면 기표가 지워진 것입니다. 그 뒤에 마우스를 떼세요.\n테두리가 누레지다 타버리면 들킵니다. 종이마다 타는 속도가 다릅니다.\n한 번 떼면 끝!"

@export var id: StringName = &"vanishing_ink"

var _state: State = State.TUTORIAL
var _round: int = 0
var _successes: int = 0
var _min_margin: float = INF
var _t: float = 0.0
var _burn_at: float = 0.0
var _steamed: bool = false
var _action: Callable
var _edge_mat: StandardMaterial3D
var _inner_mat: StandardMaterial3D
var _mark: MeshInstance3D
var _iron: MeshInstance3D
var _steam: CPUParticles3D
var _iron_tween: Tween

@onready var _camera: Camera3D = $Camera3D
@onready var _overlay: Control = $HUD/Overlay
@onready var _message: Label = $HUD/Overlay/Center/Box/Message
@onready var _action_button: Button = $HUD/Overlay/Center/Box/Action
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 7.0, 7.0), Vector3.ZERO)
	_build_visuals()
	_action_button.pressed.connect(func() -> void: _action.call())
	_show_overlay(TUTORIAL_TEXT, "시작", _start)


func _process(delta: float) -> void:
	if _state != State.IRONING:
		return
	_t += delta
	var r: float = clampf(_t / _burn_at, 0.0, 1.0)
	_edge_mat.albedo_color = PALETTE.paper.lerp(PALETTE.scorch, r)
	if not _steamed and _t >= CONFIG.steam_time:
		_steamed = true
		_mark.hide()
		_steam.emitting = true
	if _t >= _burn_at:
		_end_round(false, "앗, 종이가 타버렸다!", true)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed and _state == State.READY:
		_state = State.IRONING
		_hint.text = "…"
		_move_iron(IRON_PRESS_Y)
	elif not mb.pressed and _state == State.IRONING:
		_release()


func _start() -> void:
	_overlay.hide()
	_round = 0
	_next_round()


func _next_round() -> void:
	_round += 1
	_t = 0.0
	_steamed = false
	_burn_at = randf_range(CONFIG.burn_min, CONFIG.burn_max)
	_edge_mat.albedo_color = PALETTE.paper
	_inner_mat.albedo_color = PALETTE.paper
	_mark.show()
	_steam.emitting = false
	_move_iron(IRON_REST_Y)
	$HUD/RoundLabel.text = "%d / %d장" % [_round, CONFIG.rounds]
	_hint.text = "마우스를 누르고 있으세요"
	_state = State.READY


func _release() -> void:
	_move_iron(IRON_REST_Y)
	if _t < CONFIG.steam_time:
		_end_round(false, "너무 일찍 뗐다. 기표가 그대로다.", false)
		return
	_min_margin = minf(_min_margin, _burn_at - _t)
	_end_round(true, "기표가 감쪽같이 사라졌다.", false)


func _end_round(ok: bool, msg: String, burned: bool) -> void:
	_state = State.BETWEEN
	if ok:
		_successes += 1
	if burned:
		_edge_mat.albedo_color = PALETTE.burnt
		_inner_mat.albedo_color = PALETTE.burnt
		_move_iron(IRON_REST_Y)
	_hint.text = msg
	await get_tree().create_timer(BETWEEN_TIME).timeout
	if _round >= CONFIG.rounds:
		_finish()
	else:
		_next_round()


func _finish() -> void:
	_state = State.ENDED
	_hint.text = ""
	var rank: Grade.Rank = VanishingInkRules.judge(_successes, CONFIG.rounds, CONFIG.need_success, _min_margin, CONFIG.safe_margin)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "투표지 더미는 처음부터 깨끗했던 것 같다. 다리미만 따뜻할 뿐."
		Grade.Rank.SUCCESS:
			msg = "몇 장은 눌어붙었지만 대체로 감쪽같다."
		_:
			msg = "방 안에 탄내가 진동한다. 이건 누가 봐도 수상하다."
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _show_overlay(text: String, button_text: String, action: Callable) -> void:
	_message.text = text
	_action_button.text = button_text
	_action = action
	_overlay.show()


func _move_iron(y: float) -> void:
	if _iron_tween != null:
		_iron_tween.kill()
	_iron_tween = create_tween()
	_iron_tween.tween_property(_iron, "position:y", y, 0.15)


# --- 화면 ---

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

	var table: MeshInstance3D = _box(Vector3(16.0, 0.2, 10.0), PALETTE.background.darkened(0.15))
	table.position.y = -0.1
	add_child(table)

	var edge: MeshInstance3D = _box(PAPER_SIZE, PALETTE.paper)
	edge.position.y = PAPER_SIZE.y / 2.0
	_edge_mat = (edge.mesh as BoxMesh).material as StandardMaterial3D
	add_child(edge)

	var inner: MeshInstance3D = _box(INNER_SIZE, PALETTE.paper)
	inner.position.y = INNER_SIZE.y / 2.0
	_inner_mat = (inner.mesh as BoxMesh).material as StandardMaterial3D
	add_child(inner)

	_mark = _box(Vector3(1.2, 0.02, 0.35), PALETTE.anti_mincho)
	_mark.position = Vector3(-0.9, INNER_SIZE.y + 0.01, 0.0)
	add_child(_mark)

	_iron = _box(Vector3(1.6, 0.6, 1.0), PALETTE.iron)
	_iron.position = Vector3(0.9, IRON_REST_Y, 0.0)
	add_child(_iron)

	var steam_mesh: SphereMesh = SphereMesh.new()
	steam_mesh.radius = 0.18
	steam_mesh.height = 0.36
	var steam_mat: StandardMaterial3D = StandardMaterial3D.new()
	steam_mat.albedo_color = Color(PALETTE.paper, 0.6)
	steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	steam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam_mesh.material = steam_mat
	_steam = CPUParticles3D.new()
	_steam.mesh = steam_mesh
	_steam.amount = 14
	_steam.lifetime = 1.2
	_steam.direction = Vector3.UP
	_steam.spread = 25.0
	_steam.initial_velocity_min = 1.0
	_steam.initial_velocity_max = 2.0
	_steam.gravity = Vector3.ZERO
	_steam.emitting = false
	_steam.position = Vector3(0.9, 0.5, 0.0)
	add_child(_steam)
