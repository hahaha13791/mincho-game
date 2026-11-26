extends Node3D
## 샌드위치표(id: sandwich_ballot). 위·아래는 확정된 민초 묶음이고, 가운데에 반민초 표를 쌓을지(히트) 닫을지(스탠드) 고른다.
## 쌓기마다 정해진 범위(공개)의 랜덤 장수가 늘고, 가운데 반민초 표가 100장을 넘기면 버스트. 민초 묶음은 장수에 안 센다.

enum State { TUTORIAL, PLAYING, ANIMATING, BETWEEN, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: SandwichConfig = preload("res://minigames/sandwich_ballot/sandwich_config.tres")
const FLOOR_Y: float = -3.0
const SHEET_H: float = 0.06 # 표 한 장의 높이. 100장 = 6.0
const BREAD_H: float = 0.25 # 위·아래 민초 묶음 높이 (장수에 안 셈)
const BUNDLE_XZ: Vector2 = Vector2(3.2, 2.2)
const BETWEEN_TIME: float = 1.6
const TUTORIAL_TEXT: String = "위·아래의 민트 띠지 민초 묶음은 항상 깔립니다. 장수에 세지 않습니다.\n[쌓기]를 누르면 가운데에 흰 반민초 표가 한 번에 %d~%d장씩 랜덤으로 쌓입니다.\n[닫기]로 위쪽 민초 묶음을 덮으면, 가운데 반민초 표가 전부 민초표로 집계됩니다.\n목표 %d장 이상이 필요하지만, %d장을 넘기면 두께로 들킵니다!"

@export var id: StringName = &"sandwich_ballot"

var _state: State = State.TUTORIAL
var _round: int = 0
var _successes: int = 0
var _min_sheets: int = 1 << 30
var _sheets: int = 0 # 가운데 반민초 표 장수(판정용. 누르는 순간 정해짐)
var _shown: int = 0 # 화면 표시 장수(종이가 내려앉을 때마다 오름)
var _line: MeshInstance3D

@onready var _camera: Camera3D = $Camera3D
@onready var _stack: PaperStack = $Stack
@onready var _hint: Label = $HUD/HintLabel
@onready var _hit_button: Button = $HUD/Buttons/HitButton
@onready var _stand_button: Button = $HUD/Buttons/StandButton


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(5.0, 5.0, 10.0), Vector3(0.0, 0.5, 0.0))
	_build_visuals()
	_stack.bundle_xz = BUNDLE_XZ
	_stack.sheet_h = SHEET_H
	_stack.bundle_h = BREAD_H
	_stack.interval = CONFIG.sheet_interval
	_stack.sheet_landed.connect(func() -> void:
		_shown += 1
		_refresh())
	_hit_button.pressed.connect(_on_hit)
	_stand_button.pressed.connect(_on_stand)
	Tutorial.open(self, TUTORIAL_TEXT % [CONFIG.add_min, CONFIG.add_max, CONFIG.gain_target, CONFIG.bust_limit], _start)


func _start() -> void:
	_round = 0
	_next_round()


func _next_round() -> void:
	_round += 1
	_sheets = 0
	_shown = 0
	_stack.reset(FLOOR_Y)
	$HUD/RoundLabel.text = "%d / %d번째 다발" % [_round, CONFIG.rounds]
	_hint.text = ""
	_state = State.ANIMATING
	_refresh()
	await _stack.add_bundle(false) # 맨 아래는 확정된 민초 묶음
	_state = State.PLAYING
	_refresh()


func _on_hit() -> void:
	if _state != State.PLAYING:
		return
	var add: int = randi_range(CONFIG.add_min, CONFIG.add_max)
	_sheets += add
	_hint.text = "+%d장" % add
	_state = State.ANIMATING
	_refresh()
	await _stack.add_sheets(add) # 한 장씩 쌓이는 동안 버튼은 막힌다
	if _sheets > CONFIG.bust_limit:
		_hint.text = "%d장! 두께로 들켰다." % _sheets
		_flash_line()
		await _stack.collapse()
		_end_round(false, _hint.text)
		return
	_state = State.PLAYING
	_refresh()


func _on_stand() -> void:
	if _state != State.PLAYING:
		return
	_state = State.ANIMATING
	_refresh()
	await _stack.add_bundle(true) # 위 민초 묶음도 확정
	await _stack.tie()
	match SandwichRules.evaluate(_sheets, CONFIG.bust_limit, CONFIG.gain_target):
		SandwichRules.Outcome.OK:
			_min_sheets = mini(_min_sheets, _sheets)
			_end_round(true, "%d장이 민초표로 집계됐다." % _sheets)
		_:
			_end_round(false, "바꾼 표가 %d장뿐이다. 헛수고였다." % _sheets)


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


func _refresh() -> void:
	$HUD/SheetLabel.text = "반민초 %d / %d장 (목표 %d장)\n쌓기 +%d~%d장" % [_shown, CONFIG.bust_limit, CONFIG.gain_target, CONFIG.add_min, CONFIG.add_max]
	var playing: bool = _state == State.PLAYING
	_hit_button.disabled = not playing
	_stand_button.disabled = not playing


# --- 화면 ---

# 버스트 때 100장 선이 깜빡인다
func _flash_line() -> void:
	for i in 4:
		_line.visible = i % 2 == 1
		await get_tree().create_timer(0.1).timeout
	_line.visible = true


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

	# 반민초 표 100장 선. 넘기면 버스트
	_line = _box(Vector3(4.2, 0.05, 0.05), PALETTE.danger)
	_line.position = Vector3(0.0, FLOOR_Y + BREAD_H + CONFIG.bust_limit * SHEET_H, 1.3)
	add_child(_line)
