extends Node3D
## 피아노표(id: piano_ballot). 컨베이어로 일정한 박자로 오는 표 중 반민초 표(빈 흰 종이)만 박자에 맞춰 찍는다. 민초 표는 민트 도장이 미리 찍혀 있다.
## 감시자는 한 박자 전에 소리와 화면으로 예고하며, 그 박자에 찍으면 적발. 클릭 = 찍기.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: PianoConfig = preload("res://minigames/piano_ballot/piano_config.tres")
const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const CONVEYOR: PackedScene = preload("res://minigames/piano_ballot/props/conveyor.tscn")
const STAMP: PackedScene = preload("res://minigames/piano_ballot/props/stamp.tscn")
const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const SPACING: float = 2.0 # 박자당 표 사이 거리
const STAMPER_REST_Y: float = 2.5
const STAMPER_PRESS_Y: float = 0.5
const TUTORIAL_TEXT: String = "표가 일정한 박자로 컨베이어를 타고 옵니다. 중앙의 찍는 틀에 닿는 박자에 맞춰 클릭하세요.\n빈 표(반민초)만 찍습니다. 민트 도장이 찍힌 표(민초)는 그냥 보내세요.\n'감시자 등장!'이 뜨고 낮은 소리가 나면, 바로 다음 박자에는 아무것도 찍으면 안 됩니다.\n감시자 앞에서 찍으면 바로 들킵니다!"

@export var id: StringName = &"piano_ballot"

var _state: State = State.TUTORIAL
var _beats: Array[Dictionary] = []
var _resolved: Array[bool] = []
var _ballots: Array[MeshInstance3D] = []
var _beat_dur: float
var _first: float # 첫 표가 찍는 지점에 닿는 시각
var _t: float = 0.0
var _next_resolve: int = 0
var _mistakes: int = 0
var _warn_until: float = -1.0
var _sfx: AudioStreamPlayer
var _stamper: Node3D
var _watcher: Watcher
var _conveyor: Conveyor
var _stamp_tween: Tween

@onready var _camera: Camera3D = $Camera3D
@onready var _hint: Label = $HUD/HintLabel
@onready var _warn: Label = $HUD/WarnLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 5.5, 9.5), Vector3(0.0, 0.0, 0.0)) # 약 30도. 컨베이어 옆면(롤러)이 보이게
	_beat_dur = 60.0 / CONFIG.bpm
	_first = CONFIG.count_in * _beat_dur
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	_build_visuals()
	Tutorial.open(self, TUTORIAL_TEXT, _start)


func _start() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_beats = PianoRules.build(CONFIG, rng)
	_resolved.resize(_beats.size())
	_resolved.fill(false)
	for beat in _beats:
		var b: MeshInstance3D = _box(Vector3(1.4, 0.06, 1.0), PALETTE.paper)
		if not beat["anti"]: # 민초 표: 민트 도장이 손으로 찍은 듯 조금씩 다른 자리·각도로
			var vote: Node3D = STAMP_MARK.instantiate()
			vote.ink = PALETTE.mincho.darkened(0.2) # 흰 종이 위에서 잘 보이게
			vote.scale = Vector3.ONE * 1.3
			vote.position = Vector3(randf_range(-0.3, 0.3), 0.035, randf_range(-0.15, 0.15))
			vote.rotation.y = randf_range(-0.4, 0.4)
			b.add_child(vote)
		b.position = Vector3(-100.0, 0.1, 0.0)
		add_child(b)
		_ballots.append(b)
	_refresh()
	_state = State.PLAYING


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	var prev: float = _t
	_t += delta
	var k: int = floori(_t / _beat_dur)
	if k > floori(prev / _beat_dur):
		_tick(k - CONFIG.count_in)
	for i in _ballots.size():
		_ballots[i].position.x = (_t - _first - i * _beat_dur) / _beat_dur * SPACING
	_conveyor.scroll(_t / _beat_dur * SPACING) # 표와 같은 속도
	var idx: int = roundi((_t - _first) / _beat_dur)
	_watcher.set_present(idx >= 0 and idx < _beats.size() and _beats[idx]["watcher"])
	_warn.visible = _t < _warn_until
	# 판정 창이 지난 표는 안 찍은 것으로 확정한다
	while _next_resolve < _beats.size() and _t > _first + _next_resolve * _beat_dur + CONFIG.window:
		if not _resolved[_next_resolve] and PianoRules.should_stamp(_beats[_next_resolve]):
			_mistake("놓쳤다!")
		_resolved[_next_resolve] = true
		_next_resolve += 1
	if _next_resolve >= _beats.size():
		_finish(false, "")


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.PLAYING or not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_press_stamper()
	var i: int = roundi((_t - _first) / _beat_dur)
	if i < 0 or i >= _beats.size() or _resolved[i] or absf(_t - _first - i * _beat_dur) > CONFIG.window:
		return # 박자에서 벗어난 클릭은 아무것도 찍지 못한다
	_resolved[i] = true
	var mark: Node3D = STAMP_MARK.instantiate()
	mark.position.y = 0.035 # 표 윗면
	_ballots[i].add_child(mark)
	if _beats[i]["watcher"]:
		_finish(true, "감시자 코앞에서 쾅! 도장 소리가 온 마을에 울렸다.")
	elif not _beats[i]["anti"]:
		_mistake("민초 표를 찍었다!")


# b = 박자 번호(카운트인 동안은 음수). 다음 박자에 감시자가 오면 예고한다
func _tick(b: int) -> void:
	if b + 1 >= 0 and b + 1 < _beats.size() and _beats[b + 1]["watcher"]:
		_warn_until = _first + (b + 1) * _beat_dur + _beat_dur * 0.5
		Beep.play(_sfx, 330.0)
	else:
		Beep.play(_sfx, 880.0)


func _mistake(msg: String) -> void:
	_mistakes += 1
	_hint.text = msg
	_refresh()


func _finish(caught: bool, msg: String) -> void:
	if _state == State.ENDED:
		return
	_state = State.ENDED
	_warn.hide()
	var rank: Grade.Rank = PianoRules.judge(caught, _mistakes, CONFIG.perfect_mistakes, CONFIG.success_mistakes)
	if not caught:
		match rank:
			Grade.Rank.PERFECT:
				msg = "리듬감이 너무 좋아서 아무도 이게 부정이라는 걸 눈치채지 못했다."
			Grade.Rank.SUCCESS:
				msg = "박자가 몇 번 어긋났지만 개표는 무사히 끝났다."
			_:
				msg = "박자가 엉망이다. 개표대가 시끄러워 사람들이 몰려왔다."
	await get_tree().create_timer(0.8).timeout
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _refresh() -> void:
	$HUD/MistakeLabel.text = "실수 %d" % _mistakes


func _press_stamper() -> void:
	if _stamp_tween != null:
		_stamp_tween.kill()
	_stamp_tween = create_tween()
	_stamp_tween.tween_property(_stamper, "position:y", STAMPER_PRESS_Y, 0.04)
	_stamp_tween.tween_property(_stamper, "position:y", STAMPER_REST_Y, 0.12)


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

	_conveyor = CONVEYOR.instantiate()
	add_child(_conveyor)

	# 찍는 지점 표시 틀
	var frame: MeshInstance3D = _box(Vector3(1.8, 0.02, 1.4), PALETTE.accent)
	frame.position.y = 0.06
	add_child(frame)

	_stamper = STAMP.instantiate()
	_stamper.position = Vector3(0.0, STAMPER_REST_Y, 0.0)
	add_child(_stamper)

	_watcher = WATCHER.instantiate()
	_watcher.position = Vector3(-3.0, 0.0, -2.5)
	add_child(_watcher)
