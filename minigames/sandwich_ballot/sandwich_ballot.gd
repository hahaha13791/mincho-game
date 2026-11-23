extends Node3D
## 샌드위치표(id: sandwich_ballot). 5장 묶음을 하나씩 쌓을지(히트) 닫을지(스탠드) 고른다.
## 닫은 다발의 맨 위·맨 아래 묶음이 민초면 가운데 반민초 표가 전부 민초로 집계된다. 100장을 넘기면 버스트.

enum State { TUTORIAL, PLAYING, BETWEEN, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: SandwichConfig = preload("res://minigames/sandwich_ballot/sandwich_config.tres")
const FLOOR_Y: float = -3.0
const BUNDLE_H: float = 0.3 # 5장 한 묶음의 높이. 100장 = 6.0
const BUNDLE_SIZE: Vector3 = Vector3(3.2, 0.27, 2.2) # 높이보다 살짝 얇게 해 묶음 사이 틈을 낸다
const BETWEEN_TIME: float = 1.6
const TUTORIAL_TEXT: String = "5장 묶음이 하나씩 쌓입니다. 초록은 민초, 갈색은 반민초 묶음입니다.\n[쌓기]로 한 묶음 더, [닫기]로 다발을 마무리합니다.\n닫았을 때 맨 위와 맨 아래가 민초 묶음이면, 가운데 반민초 표까지 전부 민초표로 집계됩니다.\n하지만 100장을 넘기면 두께로 들킵니다!"

@export var id: StringName = &"sandwich_ballot"

var _state: State = State.TUTORIAL
var _round: int = 0
var _successes: int = 0
var _min_sheets: int = 1 << 30
var _bundles: Array[bool] = [] # 아래→위, true = 민초
var _action: Callable

@onready var _camera: Camera3D = $Camera3D
@onready var _stack: Node3D = $Stack
@onready var _overlay: Control = $HUD/Overlay
@onready var _message: Label = $HUD/Overlay/Center/Box/Message
@onready var _action_button: Button = $HUD/Overlay/Center/Box/Action
@onready var _hint: Label = $HUD/HintLabel
@onready var _hit_button: Button = $HUD/Buttons/HitButton
@onready var _stand_button: Button = $HUD/Buttons/StandButton


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(5.0, 5.0, 10.0), Vector3(0.0, 0.5, 0.0))
	_build_visuals()
	_action_button.pressed.connect(func() -> void: _action.call())
	_hit_button.pressed.connect(_on_hit)
	_stand_button.pressed.connect(_on_stand)
	_show_overlay(TUTORIAL_TEXT, "시작", _start)


func _start() -> void:
	_overlay.hide()
	_round = 0
	_next_round()


func _next_round() -> void:
	_round += 1
	_bundles.clear()
	for c in _stack.get_children():
		c.queue_free()
	_push(true) # 맨 아래는 항상 민초 묶음
	$HUD/RoundLabel.text = "%d / %d번째 다발" % [_round, CONFIG.rounds]
	_hint.text = ""
	_state = State.PLAYING
	_refresh()


func _on_hit() -> void:
	if _state != State.PLAYING:
		return
	_push(randf() < CONFIG.mincho_ratio)
	_refresh()
	if _sheets() > CONFIG.bust_limit:
		_end_round(false, "%d장! 두께로 들켰다." % _sheets())


func _on_stand() -> void:
	if _state != State.PLAYING:
		return
	var sheets: int = _sheets()
	match SandwichRules.evaluate(_bundles, CONFIG.sheets_per_bundle, CONFIG.bust_limit, CONFIG.gain_target):
		SandwichRules.Outcome.OK:
			_min_sheets = mini(_min_sheets, sheets)
			_end_round(true, "%d장이 민초표로 집계됐다." % SandwichRules.gain(_bundles, CONFIG.sheets_per_bundle))
		SandwichRules.Outcome.BAD_ENDS:
			_end_round(false, "맨 위에 반민초 표가 있다. 그대로 집계됐다.")
		_:
			_end_round(false, "바꾼 표가 너무 적다. 헛수고였다.")


func _end_round(ok: bool, msg: String) -> void:
	_state = State.BETWEEN
	if ok:
		_successes += 1
	_hint.text = msg
	_refresh()
	await get_tree().create_timer(BETWEEN_TIME).timeout
	if _round >= CONFIG.rounds:
		_finish()
	else:
		_next_round()


func _finish() -> void:
	_state = State.ENDED
	_hint.text = ""
	var rank: Grade.Rank = SandwichRules.judge(_successes, CONFIG.rounds, CONFIG.need_success, _min_sheets, CONFIG.perfect_sheets)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "다발은 두툼하고 맨 위 묶음은 방긋 웃고 있다. 아무도 속을 열어보지 않았다."
		Grade.Rank.SUCCESS:
			msg = "다발은 다소 얇아졌지만 겉보기엔 흠잡을 데 없다."
		_:
			msg = "다발이 어딘가 이상하다. 개표원이 다발을 펼쳐 보기 시작했다."
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _sheets() -> int:
	return _bundles.size() * CONFIG.sheets_per_bundle


func _refresh() -> void:
	$HUD/SheetLabel.text = "%d / %d장" % [_sheets(), CONFIG.bust_limit]
	var playing: bool = _state == State.PLAYING
	_hit_button.disabled = not playing
	_stand_button.disabled = not playing


func _show_overlay(text: String, button_text: String, action: Callable) -> void:
	_message.text = text
	_action_button.text = button_text
	_action = action
	_overlay.show()


# --- 화면 ---

func _push(is_mincho: bool) -> void:
	var y: float = FLOOR_Y + BUNDLE_H * (_bundles.size() + 0.5)
	_bundles.append(is_mincho)
	var m: MeshInstance3D = _box(BUNDLE_SIZE, PALETTE.mincho if is_mincho else PALETTE.anti_mincho)
	m.position = Vector3(0.0, y + 3.0, 0.0)
	_stack.add_child(m)
	create_tween().tween_property(m, "position:y", y, 0.15)


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

	var table: MeshInstance3D = _box(Vector3(10.0, 0.4, 6.0), PALETTE.background.darkened(0.15))
	table.position.y = FLOOR_Y - 0.2
	add_child(table)

	# 100장 선. 넘기면 버스트
	var line: MeshInstance3D = _box(Vector3(4.2, 0.05, 0.05), PALETTE.danger)
	line.position = Vector3(0.0, FLOOR_Y + CONFIG.bust_limit / float(CONFIG.sheets_per_bundle) * BUNDLE_H, 1.3)
	add_child(line)
