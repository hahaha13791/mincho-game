extends Node3D
## 피아노표(id: piano_ballot). 컨베이어로 리듬에 맞춰 오는 표 중 반민초 표(빈 흰 종이)만 박자에 맞춰 찍는다. 민초 표는 민트 도장이 미리 찍혀 있다.
## 날 따라해봐요: 표는 고리처럼 돈다. 뒤 레일을 왼쪽으로 흐르며 찍는 자리 맞은편을 지날 때 소리로 리듬을 보여 주고(보여 주기 마디),
## 왼쪽 끝에서 앞 레일로 넘어와 정확히 한 마디 뒤 같은 리듬으로 찍는 자리에 온다(따라 하기 마디).
## 감시자는 한 박자 전에 소리와 화면으로 예고하며, 그 표를 찍으면 적발. 클릭 = 찍기.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: PianoConfig = preload("res://minigames/piano_ballot/piano_config.tres")
const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const CONVEYOR: PackedScene = preload("res://minigames/piano_ballot/props/conveyor.tscn")
const STAMP: PackedScene = preload("res://minigames/piano_ballot/props/stamp.tscn")
const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const SPACING: float = 5.0 # 한 박 동안 표가 가는 거리. 고리(레일 길이 × 2)가 1마디가 되게 레일 길이와 맞춘다
const BALLOT_SIZE: Vector3 = Vector3(0.66, 0.06, 1.0) # 흐르는 방향(x)으로 좁은 쪽지
const BELT_END: float = Conveyor.LENGTH / 2.0 # 레일 끝. 여기서 미리보기 레일 → 앞 레일로 넘어온다
const CALL_LAG: float = 4.0 # 뒤 레일 가운데 → 찍는 자리 = 1마디. 고리 길이(2 × BELT_END)가 SPACING × 이 값과 같아야 한다
const PREVIEW_Z: float = -4.5 # 미리보기 레일(뒤쪽, 반대 방향)
const WATCH_SHOW: float = 0.5 # 감시자 표 앞뒤로 감시자가 다 올라와 있는 시간(박)
# 감시자 상반신: 카메라에 붙여 화면 오른쪽 아래에서 비스듬히 올라온다(카메라 기준 좌표, 직교 카메라 size 10 = 세로 ±5)
const WATCHER_SCALE: float = 6.5 # 머리~가슴이 화면 세로의 2/3쯤
# 크기 6.5에서 발 → 머리 끝 ≈ 12.2(캡처로 잼). 화면 아래 끝 = -5
const WATCHER_UP: Vector3 = Vector3(7.5, -10.5, -3.0) # 다 올라온 자리(발 기준). 머리 끝이 화면 위에서 1/3쯤 = 세로 2/3
const WATCHER_DOWN_Y: float = -18.0 # 숨은 자리. 머리 끝까지 화면 아래
const WATCHER_PEEK: float = 0.27 # 예고 동안 올라오는 비율(머리 끝만)
const WATCHER_LEAN: float = 0.15 # 화면 안쪽으로 기우는 각도(라디안). 발 기준으로 돌아 머리가 크게 움직이니 작게
const STAMPER_REST_Y: float = 2.5
const STAMPER_PRESS_Y: float = 0.5
const TUTORIAL_TEXT: String = "날 따라해봐요! 먼저 뒤쪽 레일의 표가 가운데를 지나며 리듬을 들려줍니다. 듣기만 하세요.\n다음 마디에 같은 표가 같은 리듬으로 앞 레일의 찍는 틀에 옵니다. 그때 클릭!\n빈 표(반민초)만 찍습니다. 민트 도장이 찍힌 표(민초)는 그냥 보내세요.\n낮은 소리와 함께 감시자가 고개를 내밀면, 감시자가 다 올라온 순간 오는 표는 찍으면 안 됩니다. 감시자 앞에서 찍으면 바로 들킵니다!"

@export var id: StringName = &"piano_ballot"

var _state: State = State.TUTORIAL
var _beats: Array[Dictionary] = [] # 표 목록(시간순). PianoRules.build 참고
var _windows: PackedFloat32Array = PackedFloat32Array() # 표마다 판정 허용 오차(초)
var _watch_list: Array[int] = [] # 감시자 표 번호(시간순)
var _next_warn: int = 0
var _next_call: int = 0 # 다음에 뒤 레일 가운데를 지날 표
var _call_sfx: AudioStreamPlayer # 보여 주기 소리. 메트로놈과 겹쳐도 끊기지 않게 따로
var _resolved: Array[bool] = []
var _ballots: Array[MeshInstance3D] = []
var _beat_dur: float
var _first: float # 0박(첫 마디 첫 박)이 찍는 지점에 닿는 시각
var _t: float = 0.0
var _next_resolve: int = 0
var _mistakes: int = 0
var _warn_until: float = -1.0
var _sfx: AudioStreamPlayer
var _stamper: Node3D
var _watcher: Watcher
var _conveyors: Array[Conveyor] = []
var _stamp_tween: Tween

@onready var _camera: Camera3D = $Camera3D
@onready var _hint: Label = $HUD/HintLabel
@onready var _warn: Label = $HUD/WarnLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 5.5, 9.5), Vector3(0.0, 0.0, -2.0)) # 약 30도. 컨베이어 옆면(롤러)과 뒤 미리보기 레일이 보이게
	_beat_dur = 60.0 / CONFIG.bpm
	_first = CONFIG.count_in * _beat_dur
	assert(is_equal_approx(2.0 * BELT_END, SPACING * CALL_LAG), "고리 길이가 1마디와 안 맞음: Conveyor.LENGTH 또는 SPACING 확인")
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	_call_sfx = AudioStreamPlayer.new()
	add_child(_call_sfx)
	_build_visuals()
	Tutorial.open(self, TUTORIAL_TEXT, _start)


func _start() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_beats = PianoRules.build(CONFIG, rng)
	for g in PianoRules.half_gaps(_beats):
		_windows.append(minf(CONFIG.window, g * _beat_dur))
	_resolved.resize(_beats.size())
	_resolved.fill(false)
	for i in _beats.size():
		var beat: Dictionary = _beats[i]
		if beat["watcher"]:
			_watch_list.append(i)
		var b: MeshInstance3D = _box(BALLOT_SIZE, PALETTE.paper)
		if not beat["anti"]: # 민초 표: 민트 도장이 손으로 찍은 듯 조금씩 다른 자리·각도로
			var vote: Node3D = STAMP_MARK.instantiate()
			vote.ink = PALETTE.mincho.darkened(0.2) # 흰 종이 위에서 잘 보이게
			vote.scale = Vector3.ONE * 1.0
			vote.position = Vector3(randf_range(-0.04, 0.04), 0.035, randf_range(-0.2, 0.2))
			vote.rotation.y = randf_range(-0.4, 0.4)
			b.add_child(vote)
		b.visible = false
		add_child(b)
		_ballots.append(b)
	_refresh()
	_state = State.PLAYING


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	var prev: float = _t
	_t += delta
	var now: float = (_t - _first) / _beat_dur # 지금이 몇 박째인가 (0박이 찍는 지점에 닿는 순간 = 0)
	if floori(now) > floori((prev - _first) / _beat_dur):
		Beep.play(_sfx, 880.0) # 메트로놈: 4분음표마다
	if _next_call < _beats.size() and now >= _beats[_next_call]["time"] - CALL_LAG:
		Beep.play(_call_sfx, 523.0, 0.12) # 보여 주기: 뒤 레일 가운데를 지나는 표마다
		_next_call += 1
	if _next_warn < _watch_list.size() and now >= _beats[_watch_list[_next_warn]]["time"] - CONFIG.warn_beats:
		_warn_until = _first + (_beats[_watch_list[_next_warn]]["time"] + WATCH_SHOW) * _beat_dur
		Beep.play(_sfx, 330.0, 0.2)
		_next_warn += 1
	var rise: float = 0.0 # 감시자가 올라온 정도: 0 숨음, WATCHER_PEEK 예고, 1 다 올라옴
	for i in _ballots.size():
		var u: float = now - _beats[i]["time"] # 찍는 지점까지 남은(음수)·지난(양수) 박
		_place_ballot(_ballots[i], u * SPACING)
		if _beats[i]["watcher"]:
			rise = maxf(rise, _watcher_rise(u))
	for c in _conveyors:
		c.scroll(_t / _beat_dur * SPACING) # 표와 같은 속도
	_watcher.position = WATCHER_UP
	_watcher.position.y = lerpf(WATCHER_DOWN_Y, WATCHER_UP.y, rise)
	_warn.visible = _t < _warn_until
	# 판정 창이 지난 표는 안 찍은 것으로 확정한다
	while _next_resolve < _beats.size() and _t > _first + _beats[_next_resolve]["time"] * _beat_dur + _windows[_next_resolve]:
		if not _resolved[_next_resolve] and PianoRules.should_stamp(_beats[_next_resolve]):
			_mistake("놓쳤다!")
		_resolved[_next_resolve] = true
		_next_resolve += 1
	if _next_resolve >= _beats.size():
		_finish(false, "")


# u = 감시자 표가 찍는 지점까지 남은(음수)·지난(양수) 박. 예고 동안 머리만 내밀다가, 그 표가 올 때 다 올라왔다 내려간다
func _watcher_rise(u: float) -> float:
	var up: float = 0.15 # 오르내리는 데 걸리는 박
	if u < -CONFIG.warn_beats or u > WATCH_SHOW + up:
		return 0.0
	if u < -WATCH_SHOW - up:
		return WATCHER_PEEK * clampf((u + CONFIG.warn_beats) / up, 0.0, 1.0)
	if u < -WATCH_SHOW:
		return lerpf(WATCHER_PEEK, 1.0, (u + WATCH_SHOW + up) / up)
	if u <= WATCH_SHOW:
		return 1.0
	return 1.0 - (u - WATCH_SHOW) / up


# 고리 위치. d = 앞 레일에서 찍는 지점 기준 x. 앞 레일 왼쪽 끝보다 이전이면 미리보기 레일 위(반대 방향)
func _place_ballot(b: MeshInstance3D, d: float) -> void:
	if d >= -BELT_END:
		b.position = Vector3(d, 0.1, 0.0)
		b.visible = d <= BELT_END
	else:
		var x: float = -2.0 * BELT_END - d # 왼쪽 끝(-BELT_END)에서 앞 레일과 이어진다
		b.position = Vector3(x, 0.1, PREVIEW_Z)
		b.visible = x <= BELT_END


func _unhandled_input(event: InputEvent) -> void:
	if _state != State.PLAYING or not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	_press_stamper()
	var i: int = _nearest_open()
	if i < 0:
		return # 박자에서 벗어난 클릭은 아무것도 찍지 못한다
	_resolved[i] = true
	var mark: Node3D = STAMP_MARK.instantiate()
	mark.position.y = 0.035 # 표 윗면
	_ballots[i].add_child(mark)
	if _beats[i]["watcher"]:
		_finish(true, "감시자 코앞에서 쾅! 도장 소리가 온 마을에 울렸다.")
	elif not _beats[i]["anti"]:
		_mistake("민초 표를 찍었다!")


# 판정 창 안에 있는 아직 안 찍은 표. 창은 옆 표와 겹치지 않으므로 많아야 하나
func _nearest_open() -> int:
	for i in range(_next_resolve, _beats.size()):
		var off: float = _t - _first - _beats[i]["time"] * _beat_dur
		if off < -CONFIG.window:
			break
		if not _resolved[i] and absf(off) <= _windows[i]:
			return i
	return -1


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

	var main_belt: Conveyor = CONVEYOR.instantiate()
	add_child(main_belt)
	var preview_belt: Conveyor = CONVEYOR.instantiate() # 반 바퀴 돌려 놓아 -x로 흐른다
	preview_belt.position.z = PREVIEW_Z
	preview_belt.rotation.y = PI
	add_child(preview_belt)
	_conveyors = [main_belt, preview_belt]

	# 찍는 지점 표시 틀
	var frame: MeshInstance3D = _box(Vector3(BALLOT_SIZE.x + 0.3, 0.02, 1.4), PALETTE.accent)
	frame.position.y = 0.06
	add_child(frame)
	var call_frame: MeshInstance3D = _box(Vector3(BALLOT_SIZE.x + 0.3, 0.02, 1.4), PALETTE.accent.lightened(0.5)) # 보여 주기 지점(뒤 레일 가운데)
	call_frame.position = Vector3(0.0, 0.06, PREVIEW_Z)
	add_child(call_frame)

	_stamper = STAMP.instantiate()
	_stamper.position = Vector3(0.0, STAMPER_REST_Y, 0.0)
	add_child(_stamper)

	_watcher = WATCHER.instantiate() # 카메라 자식: 인형 앞(+z)이 카메라를 본다
	_watcher.scale = Vector3.ONE * WATCHER_SCALE
	_watcher.rotation.z = WATCHER_LEAN
	_watcher.position = Vector3(WATCHER_UP.x, WATCHER_DOWN_Y, WATCHER_UP.z)
	_camera.add_child(_watcher)
	_watcher.set_present(true) # 서브씬은 숨은 채 시작한다. 등장은 화면 아래로 숨겼다가 올리는 것으로 한다
