extends Node3D
## 피아노표(id: piano_ballot). 컨베이어로 리듬에 맞춰 오는 표 중 반민초 표(빈 흰 종이)만 박자에 맞춰 찍는다. 민초 표는 민트 도장이 미리 찍혀 있다.
## 날 따라해봐요: 표마다 복사본이 뒤 레일을 왼쪽으로 흐르며 찍는 자리 맞은편을 지날 때 소리로 리듬을 보여 주고(보여 주기 마디),
## 정확히 한 마디 뒤 진짜 표가 같은 리듬으로 앞 레일의 찍는 자리에 온다(따라 하기 마디). 레일 끝은 화면 밖.
## 감시자는 미리 소리와 함께 화면 가장자리에서 고개를 내밀고, 그 표가 올 때 상반신이 다 들어온다. 그 표를 찍으면 적발. 클릭 = 찍기.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: PianoConfig = preload("res://minigames/piano_ballot/piano_config.tres")
const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const CONVEYOR: PackedScene = preload("res://minigames/piano_ballot/props/conveyor.tscn")
const STAMP: PackedScene = preload("res://minigames/piano_ballot/props/stamp.tscn")
const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const SPACING: float = 3.0 # 한 박 동안 표가 가는 거리. 16분(0.25박) 간격 0.75가 표 폭보다 넓게
const BALLOT_SIZE: Vector3 = Vector3(0.66, 0.06, 1.0) # 흐르는 방향(x)으로 좁은 쪽지
const BELT_END: float = Conveyor.LENGTH / 2.0 # 레일 끝(화면 밖). 이 밖의 표는 숨긴다
const CALL_LAG: float = 4.0 # 뒤 레일 가운데를 지난 뒤 찍는 자리에 오기까지 = 1마디
const PREVIEW_Z: float = -4.5 # 미리보기 레일(뒤쪽, 반대 방향)
const WATCH_SHOW: float = 0.5 # 감시자 표 앞뒤로 감시자가 다 들어와 있는 시간(박)
const WATCH_MOVE: float = 0.15 # 감시자가 들어오고 나가는 데 걸리는 박
# 감시자 상반신: 카메라에 붙인 축(허리)을 화면 가장자리에 두고, 몸이 축의 +y 쪽으로 화면 안에 들어온다. 허리 아래는 늘 화면 밖
const WATCHER_SCALE: float = 6.7 # 허리 → 머리 끝(크기 1에서 약 1.0)이 화면 세로(10)의 2/3쯤
const WATCHER_DEPTH: float = -3.0 # 카메라 앞 거리
const WATCHER_PEEK: float = 0.25 # 예고 동안 들어오는 비율(머리 끝만)
const WATCHER_TUCK: float = 0.9 # 다 들어와도 허리를 가장자리보다 이만큼 밖에 둔다. 몸이 기울어 엉덩이 모서리가 비치지 않게
## 등장 방향: edge = 화면 가장자리 위 축 자리(가로·세로 반폭 기준 비율), angle = 축 회전(라디안). 몸 방향 = (-sin, cos)
const WATCHER_ENTRIES: Array[Dictionary] = [
	{"edge": Vector2(0.62, -1.0), "angle": 0.3}, # 오른쪽 아래에서 왼쪽 위로
	{"edge": Vector2(-0.6, 1.0), "angle": PI + 0.45}, # 왼쪽 위에서 오른쪽 아래로(거꾸로 매달려 내려다봄)
	{"edge": Vector2(1.0, 0.25), "angle": PI / 2.0 + 0.35}, # 오른쪽 옆에서 왼쪽 아래로
	{"edge": Vector2(-1.0, -0.1), "angle": -PI / 2.0 - 0.3}, # 왼쪽 옆에서 오른쪽 아래로
]
const STAMPER_REST_Y: float = 2.5
const STAMPER_PRESS_Y: float = 0.5
const TUTORIAL_TEXT: String = "날 따라해봐요! 먼저 뒤쪽 레일의 표가 가운데를 지나며 리듬을 들려줍니다. 듣기만 하세요.\n다음 마디에 같은 표가 같은 리듬으로 앞 레일의 찍는 틀에 옵니다. 그때 클릭!\n빈 표(반민초)만 찍습니다. 민트 도장이 찍힌 표(민초)는 그냥 보내세요.\n낮은 소리와 함께 감시자가 화면 가장자리에서 고개를 내밀면, 감시자가 다 들어온 순간 오는 표는 찍으면 안 됩니다. 감시자 앞에서 찍으면 바로 들킵니다!"

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
var _previews: Array[MeshInstance3D] = [] # 뒤 레일을 흐르는 복사본(같은 번호)
var _beat_dur: float
var _first: float # 0박(첫 마디 첫 박)이 찍는 지점에 닿는 시각
var _t: float = 0.0
var _next_resolve: int = 0
var _mistakes: int = 0
var _warn_until: float = -1.0
var _sfx: AudioStreamPlayer
var _stamper: Node3D
var _watcher: Watcher
var _watch_rig: Node3D # 감시자 허리 축
var _watch_torso: float # 허리 → 머리 끝 길이(크기 반영)
var _entry: Dictionary = WATCHER_ENTRIES[0] # 이번 등장 방향
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
	assert(WATCH_SHOW + WATCH_MOVE < PianoRules.WATCH_MIN_GAP, "감시자가 들어와 있는 동안 옆 표가 지나갈 수 있음: WATCH_MIN_GAP을 늘릴 것")
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
		var p: MeshInstance3D = b.duplicate() # 뒤 레일 복사본. 도장 자국까지 같은 모습
		add_child(b)
		add_child(p)
		_ballots.append(b)
		_previews.append(p)
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
		_entry = WATCHER_ENTRIES[_next_warn % WATCHER_ENTRIES.size()] # 나올 때마다 다른 방향
		_next_warn += 1
	var rise: float = 0.0 # 감시자가 들어온 정도: 0 숨음, WATCHER_PEEK 예고, 1 다 들어옴
	for i in _ballots.size():
		var u: float = now - _beats[i]["time"] # 찍는 지점까지 남은(음수)·지난(양수) 박
		_place(_ballots[i], u * SPACING, 0.0)
		_place(_previews[i], -(u + CALL_LAG) * SPACING, PREVIEW_Z) # 한 마디 먼저 반대 방향으로 가운데를 지난다
		if _beats[i]["watcher"]:
			rise = maxf(rise, _watcher_rise(u))
	for c in _conveyors:
		c.scroll(_t / _beat_dur * SPACING) # 표와 같은 속도
	_place_watcher(rise)
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
	var up: float = WATCH_MOVE
	if u < -CONFIG.warn_beats or u > WATCH_SHOW + up:
		return 0.0
	if u < -WATCH_SHOW - up:
		return WATCHER_PEEK * clampf((u + CONFIG.warn_beats) / up, 0.0, 1.0)
	if u < -WATCH_SHOW:
		return lerpf(WATCHER_PEEK, 1.0, (u + WATCH_SHOW + up) / up)
	if u <= WATCH_SHOW:
		return 1.0
	return 1.0 - (u - WATCH_SHOW) / up


func _place(b: MeshInstance3D, x: float, z: float) -> void:
	b.position = Vector3(x, 0.1, z)
	b.visible = absf(x) <= BELT_END


# 허리 축을 실제 화면 가장자리에 둔다. 창 비율이 바뀌어도(stretch aspect = expand) 허리 아래는 늘 화면 밖이다
func _place_watcher(rise: float) -> void:
	var half_h: float = _camera.size / 2.0 # 직교 카메라는 세로 크기가 고정(keep_height)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var half_w: float = half_h * vp.x / vp.y
	var angle: float = _entry["angle"]
	var body_dir: Vector3 = Vector3(-sin(angle), cos(angle), 0.0) # 허리 → 머리
	var edge: Vector2 = _entry["edge"]
	var hidden: float = -(_watch_torso + 0.5) # 머리 끝까지 가장자리 밖
	_watch_rig.position = Vector3(edge.x * half_w, edge.y * half_h, WATCHER_DEPTH) + body_dir * lerpf(hidden, -WATCHER_TUCK, rise)
	_watch_rig.rotation.z = angle


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

	_watch_rig = Node3D.new() # 카메라 자식: 인형 앞(+z)이 카메라를 본다
	_camera.add_child(_watch_rig)
	_watcher = WATCHER.instantiate()
	_watcher.scale = Vector3.ONE * WATCHER_SCALE
	_watch_rig.add_child(_watcher)
	_watcher.set_present(true) # 서브씬은 숨은 채 시작한다. 등장은 화면 밖에 두었다가 들이미는 것으로 한다
	var h: Vector2 = _watcher.body_heights()
	_watcher.position.y = -h.x * WATCHER_SCALE # 허리가 축 원점
	_watch_torso = (h.y - h.x) * WATCHER_SCALE
	_place_watcher(0.0)
