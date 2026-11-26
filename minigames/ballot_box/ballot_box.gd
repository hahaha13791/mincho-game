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
const BOX_D: float = 2.5 # 상자 깊이(z)
const TRAY_POS: Vector3 = Vector3(5.0, 0.0, 0.0)
const LID_T: float = 0.4
const LID_CLOSED_POS: Vector3 = Vector3(BOX_CENTER_X, LINE_Y + LID_T / 2.0, 0.0) # 벽 윗면에 얹힘
const LID_OPEN_POS: Vector3 = Vector3(BOX_CENTER_X, LINE_Y + 2.5, -BOX_D) # 뒤로 치워 안쪽을 안 가림
const LEAVE_TIME: float = 0.5 # 참관인이 화면 밖으로 빠지는 시간
const PEEK_AFTER: float = 0.4 # 마지막 쿵 뒤 이만큼 있다가 참관인이 머리를 내민다
const RISE_TIME: float = 0.25 # 머리만 → 다 들어오는 시간. 도착 순간에 다 들어와 있다
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
const THUMPS: int = 3 # 도착 예고 발소리 수. 하나씩 늘어난다
const THUMP_GAP: float = 0.8 # 발소리 간격. 마지막 쿵 → 도착 = warn_lead - (THUMPS - 1) × 이 값
const INTRO_TEXT: String = "투표가 시작되기 전에 투표함에 민초 표를 미리 넣어 둔다. 개표하면 투표한 사람보다 민초 표가 더 많이 나올 것이다." # 튜토리얼 위 칸: 어떤 수법인지
const TUTORIAL_TEXT: String = "접힌 민초 표를 끌어다 투표함에 떨어뜨려 쌓으세요.\n쿵, 쿵, 쿵 발소리가 세 번 나면 참관인이 도착합니다.\n참관인이 오기 전에 뚜껑을 닫으세요!\n선을 넘으면 뚜껑이 닫히지 않습니다. 10장을 넣으면 미션성공, 12장이면 완전범죄!"

@export var id: StringName = &"ballot_box"
@export var perfect_papers: int = 12 # 이 장수 이상 + 여유 있게 닫으면 완전범죄
@export var success_papers: int = 10 # 이 장수 미만이면 적발
@export var initial_papers: int = 2 # 시작 때 상자 안에 들어 있는 표
@export var visit_count: int = 3
@export var first_visit: float = 8.0 # 첫 도착 시각(초)
@export var visit_gap: float = 8.0 # 방문 간격
@export var visit_jitter: float = 3.0 # 도착 시각에 더하는 랜덤(0~이 값)
@export var warn_lead: float = 3.0 # 첫 발소리 → 도착
@export var stay: float = 2.0 # 도착 후 머무는 시간. 이동안 뚜껑을 못 연다
@export var safe_margin: float = 1.0 # 도착 전 이 시간 이상 남기고 닫으면 완전범죄

var _papers: Array[BallotPaper] = []
var _tray: BallotPaper
var _held: BallotPaper
var _held_offset: Vector3
var _state: State = State.TUTORIAL
var _elapsed: float = 0.0
var _visits: Array[float] = [] # 도착 시각
var _next_visit: int = 0
var _lid_closed: bool = false
var _closed_at: float = 0.0
var _min_margin: float = INF
var _lid_tween: Tween
var _lid: MeshInstance3D
var _observer: PeekWatcher # 참관인: 화면 가장자리에서 들이미는 감시자 상반신(피아노표와 같은 방식)
var _entry_visit: int = 0 # 등장 방향을 마지막으로 정한 방문 번호
var _thump_key: int = -1 # 마지막으로 소리 낸 (방문 번호, 발소리 번호). 같은 쿵을 두 번 울리지 않게
var _sfx: AudioStreamPlayer

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-35.0, 20.0, 0.0)
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	_build_visuals()
	for i in initial_papers: # 상자 안에 미리 들어 있는 표. 시작 전에 물리로 자리잡는다
		var p: BallotPaper = _make_paper(Vector3(BOX_CENTER_X + (i % 2 - 0.5) * 2.0, FLOOR_Y + 1.0 + i * 1.6, 0.0))
		p.set_waiting(false)
	$HUD/CloseButton.pressed.connect(_on_close_pressed)
	Tutorial.open(self, INTRO_TEXT, TUTORIAL_TEXT, _start)


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	_elapsed += delta
	var end_at: float = _visits[-1] + stay
	$HUD/TimerLabel.text = "%.1f" % maxf(end_at - _elapsed, 0.0)
	_refresh()
	_move_observer()
	if _next_visit < _visits.size() and _elapsed >= _visits[_next_visit]:
		if not _lid_closed:
			_end(Grade.Rank.CAUGHT, "참관인이 열린 투표함을 보자, 민트표가 산더미처럼 쌓여 있었다.", false)
			return
		_min_margin = minf(_min_margin, _visits[_next_visit] - _closed_at)
		_next_visit += 1
	if _elapsed >= end_at:
		_finish()


# 모든 방문 시각에 대해 발소리 표시와 참관인 등장을 갱신한다
func _move_observer() -> void:
	var rise: float = 0.0
	var warning: bool = false
	for vi in _visits.size():
		var t: float = _elapsed - (_visits[vi] - warn_lead) # 첫 쿵부터 지난 시간. warn_lead에 도착
		if t < 0.0 or t >= warn_lead + stay + LEAVE_TIME:
			continue
		if vi != _entry_visit: # 방문마다 다른 방향에서 들이민다
			_entry_visit = vi
			_observer.next_entry()
		rise = _observer_rise(t)
		warning = t < warn_lead
		if warning: # 쿵 → 쿵 쿵 → 쿵 쿵 쿵. 마지막 쿵 뒤 조금 쉬고 도착
			var n: int = mini(floori(t / THUMP_GAP) + 1, THUMPS)
			$HUD/AlertLabel.text = "쿵…  ".repeat(n).strip_edges()
			if vi * 10 + n != _thump_key:
				_thump_key = vi * 10 + n
				Beep.play(_sfx, 70.0, 0.25)
	_observer.set_rise(rise)
	$HUD/AlertLabel.visible = warning


# t = 첫 쿵부터 지난 시간. 쿵이 다 울린 뒤 머리를 내밀고, 도착(warn_lead) 순간 다 들어와 머물다 빠진다
func _observer_rise(t: float) -> float:
	var peek_at: float = (THUMPS - 1) * THUMP_GAP + PEEK_AFTER
	if t < peek_at:
		return 0.0
	if t < warn_lead - RISE_TIME:
		return PeekWatcher.PEEK * clampf((t - peek_at) / RISE_TIME, 0.0, 1.0)
	if t < warn_lead:
		return lerpf(PeekWatcher.PEEK, 1.0, (t - (warn_lead - RISE_TIME)) / RISE_TIME)
	if t < warn_lead + stay:
		return 1.0
	return 1.0 - clampf((t - warn_lead - stay) / LEAVE_TIME, 0.0, 1.0)


func _is_visiting() -> bool:
	for a in _visits:
		if _elapsed >= a and _elapsed < a + stay:
			return true
	return false


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
	if _state != State.PLAYING or _lid_closed:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _held == null:
				_try_pick(_mouse_to_plane(mb.position))
			elif not mb.pressed and _held != null:
				_drop()


func _start() -> void:
	_state = State.PLAYING
	_elapsed = 0.0
	_visits.clear()
	for i in visit_count:
		_visits.append(first_visit + i * visit_gap + randf_range(0.0, visit_jitter))
	_spawn_tray_paper()
	_refresh()


# 뚜껑 토글. 선을 넘었으면 닫히지 않고, 관리인이 머무는 동안은 열 수 없다
func _on_close_pressed() -> void:
	if _state != State.PLAYING:
		return
	if _lid_closed:
		if _is_visiting():
			return
		_set_lid(false)
		return
	if _overflows(_in_box()):
		return # 선 넘음 표시는 FillLabel에 이미 나온다
	if _held != null:
		_drop()
	_closed_at = _elapsed
	_set_lid(true)


func _set_lid(closed: bool) -> void:
	_lid_closed = closed
	$HUD/CloseButton.text = "뚜껑 열기" if closed else "뚜껑 닫기"
	if _lid_tween != null:
		_lid_tween.kill()
	_lid_tween = create_tween()
	_lid_tween.tween_property(_lid, "position", LID_CLOSED_POS if closed else LID_OPEN_POS, 0.25)


# 마지막 방문이 끝났을 때: 뚜껑은 닫혀 있고, 장수가 목표를 채웠는지 본다
func _finish() -> void:
	var inside: Array[BallotPaper] = _in_box()
	var rank: Grade.Rank = BallotBoxRules.judge(inside.size(), perfect_papers, success_papers, false, _min_margin, safe_margin)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "참관인은 아무것도 눈치채지 못했다. 투표함이 조금 무거워졌을 뿐."
		Grade.Rank.SUCCESS:
			msg = "아슬아슬! 참관인이 보기 전에 뚜껑을 닫았다!"
		_:
			msg = "투표함이 너무 홀쭉하다. 투표함이 가볍게 옮겨진다."
	_end(rank, msg, true)


func _end(rank: Grade.Rank, msg: String, close_lid: bool) -> void:
	if _state == State.ENDED:
		return
	_state = State.ENDED
	$HUD/AlertLabel.visible = false
	if _held != null:
		_drop()
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	if close_lid and not _lid_closed:
		_set_lid(true)
		await _lid_tween.finished
	ResultScreen.open(self, rank, msg, before)


# --- 표 ---

func _make_paper(pos: Vector3) -> BallotPaper:
	var p: BallotPaper = BallotPaper.new()
	p.setup(SHAPES.pick_random(), PALETTE.mincho)
	p.position = pos
	add_child(p)
	_papers.append(p)
	return p


func _spawn_tray_paper() -> void:
	_tray = _make_paper(TRAY_POS)
	_tray.set_waiting(true) # 집기 전까지 위치 고정, 물리 없음


func _try_pick(point: Vector3) -> void:
	for i in range(_papers.size() - 1, -1, -1):
		var p: BallotPaper = _papers[i]
		if p.contains(point):
			_held = p
			_held_offset = p.position - point
			p.set_waiting(false)
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
	$HUD/FillLabel.text = "%d / %d장 (최소 %d)%s" % [inside.size(), perfect_papers, success_papers, "  (선 넘음!)" if _overflows(inside) else ""]


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


func _wall(size: Vector3, pos: Vector3, color: Color) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.add_child(_box(size, color))
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
	var box_color: Color = PALETTE.ballot_box
	_wall(Vector3(WALL_T, BOX_H, BOX_D), Vector3(BOX_CENTER_X - side_x, mid_y, 0.0), box_color)
	_wall(Vector3(WALL_T, BOX_H, BOX_D), Vector3(BOX_CENTER_X + side_x, mid_y, 0.0), box_color)
	_wall(Vector3(BOX_W + 2.0 * WALL_T, WALL_T, BOX_D), Vector3(BOX_CENTER_X, FLOOR_Y - WALL_T / 2.0, 0.0), box_color)

	# 반투명 앞판(충돌 없음): 안쪽 표가 비쳐 보이고, 가운데에 '투표함'을 쓴다
	var front_h: float = BOX_H + WALL_T
	var front: MeshInstance3D = _box(Vector3(BOX_W + 2.0 * WALL_T, front_h, 0.04), box_color.lightened(0.3))
	var glass: StandardMaterial3D = (front.mesh as BoxMesh).material
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.28
	front.position = Vector3(BOX_CENTER_X, FLOOR_Y - WALL_T + front_h / 2.0, BOX_D / 2.0 + 0.02)
	add_child(front)
	var label: Label3D = Label3D.new()
	label.text = "투표함"
	label.font_size = 128
	label.pixel_size = 0.0065
	label.outline_size = 16
	label.modulate = PALETTE.paper
	label.outline_modulate = PALETTE.paper # 같은 색 외곽선으로 글씨를 굵게
	label.shaded = false
	label.position = Vector3(BOX_CENTER_X, FLOOR_Y - WALL_T + front_h / 2.0, BOX_D / 2.0 + 0.05)
	add_child(label)

	var back: MeshInstance3D = _box(Vector3(BOX_W, BOX_H, 0.2), box_color.darkened(0.3))
	back.position = Vector3(BOX_CENTER_X, mid_y, -BOX_D / 2.0 + 0.1)
	add_child(back)

	var line: MeshInstance3D = _box(Vector3(BOX_W + 2.0 * WALL_T, 0.06, 0.05), PALETTE.danger)
	line.position = Vector3(BOX_CENTER_X, LINE_Y, 0.4)
	add_child(line)

	# 뚜껑은 벽 윗면과 같은 크기(폭·깊이)라 닫히면 딱 맞물린다
	_lid = _box(Vector3(BOX_W + 2.0 * WALL_T, LID_T, BOX_D), box_color.lightened(0.25))
	_lid.position = LID_OPEN_POS
	add_child(_lid)
	var slot: MeshInstance3D = _box(Vector3(1.8, 0.03, 0.22), PALETTE.burnt) # 투표용지 넣는 구멍
	slot.position.y = LID_T / 2.0
	_lid.add_child(slot)

	_observer = PeekWatcher.new() # 카메라 자식: 화면 가장자리에서 상반신을 들이민다
	_camera.add_child(_observer)
