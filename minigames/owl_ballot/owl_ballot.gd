extends Node3D
## 올빼미표(id: owl_ballot). 불이 켜진 동안 맵(방해물·투표함·감시자 시야)을 외우고, 꺼진 동안에만 움직여 투표함을 처리한다.
## 불이 켜지는 순간 감시자 시야에 있으면 적발. 이동은 칸을 클릭하면 가로 먼저, 세로 다음으로 걸어가며 방해물에서 멈춘다.

enum State { TUTORIAL, LIGHT, DARK, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: OwlConfig = preload("res://minigames/owl_ballot/owl_config.tres")
const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const BALLOT_BOX: PackedScene = preload("res://minigames/owl_ballot/props/ballot_box.tscn")
const CELL: float = 1.2
## 엄폐물 겉모습 서브씬. 기준 칸이 원점, 회전 전 모양은 +x(열)·+z(행) 방향으로 뻗는다
const PROPS: Dictionary = {
	&"crates": preload("res://minigames/owl_ballot/props/crates.tscn"),
	&"table": preload("res://minigames/owl_ballot/props/table.tscn"),
	&"partition": preload("res://minigames/owl_ballot/props/partition.tscn"),
}
const INTRO_TEXT: String = "개표장 불이 꺼진 사이 투표함마다 몰래 민초 표를 넣는다. 아침이 되면 모든 투표함에 민초 표가 늘어나 있을 것이다." # 튜토리얼 위 칸: 어떤 수법인지
const TUTORIAL_TEXT: String = "불이 켜져 있는 동안 방해물, 투표함(파랑), 감시자 시야(빨강)를 외우세요. 이때는 움직일 수 없습니다.\n불이 꺼지면 칸을 클릭해 이동하세요. 가로로 먼저, 그다음 세로로 가며 방해물에 막히면 멈춥니다.\n투표함 칸에 들어가면 그 투표함은 처리 끝! 전부 처리하면 성공입니다.\n불이 켜질 때 감시자 시야 안에 있으면 들킵니다. 불이 깜빡이면 곧 켜지거나 꺼진다는 신호입니다.\n불이 켜진 동안 감시자는 다음 자리로 걸어갑니다. 어디로 가는지 잘 봐 두세요!"

@export var id: StringName = &"owl_ballot"

var _state: State = State.TUTORIAL
var _cycle: int = 0 # 불이 켜진 횟수 (처음 켜짐 = 0)
var _t_left: float = 0.0
var _light_dur: float = 0.0
var _cell: Vector2i
var _target: Vector2i
var _moving: bool = false
var _step_acc: float = 0.0
var _done: Array[bool] = []
var _near_missed: bool = false
var _env: Environment
var _pawn: MeshInstance3D
var _box_meshes: Array[OwlBallotBox] = []
var _vision_tiles: Dictionary = {} # Vector2i -> MeshInstance3D
var _watchers: Array[Watcher] = []

@onready var _camera: Camera3D = $Camera3D
@onready var _props: Node3D = $Props
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-60.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 11.0, 6.0), Vector3.ZERO)
	_build_visuals()
	Tutorial.open(self, INTRO_TEXT, TUTORIAL_TEXT, _start)


func _start() -> void:
	_cell = OwlLevel.START
	_pawn.position = _pawn_pos(_cell)
	_done.resize(OwlLevel.BOXES.size())
	_done.fill(false)
	_enter_light(CONFIG.first_light, true)


func _process(delta: float) -> void:
	if _state != State.LIGHT and _state != State.DARK:
		return
	_t_left -= delta
	if _state == State.LIGHT:
		_set_lit(_t_left > CONFIG.flicker or int(_t_left * 10.0) % 2 == 0, true)
		_walk_watchers()
		if _t_left <= 0.0:
			_enter_dark()
	else:
		_move(delta)
		if _state != State.DARK:
			return # 이동 중 마지막 투표함을 처리해 끝난 경우
		var pulse: bool = _t_left <= CONFIG.flicker and int(_t_left * 10.0) % 2 == 0
		_set_lit(false, false)
		if pulse:
			_env.ambient_light_energy = 0.3 # 곧 켜진다는 예고. 맵은 여전히 안 보임
		if _t_left <= 0.0 and _state == State.DARK:
			_cycle += 1
			_enter_light(CONFIG.light_time, false)
	_pawn.position = _pawn.position.move_toward(_pawn_pos(_cell), CELL / CONFIG.step_time * 1.5 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	if _state == State.LIGHT:
		_hint.text = "불이 켜져 있는 동안은 움직일 수 없다. 외우자!"
	elif _state == State.DARK:
		var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(_camera.project_ray_origin(mb.position), _camera.project_ray_normal(mb.position))
		if hit != null:
			_target = _cell_of(hit)
			_moving = true
			_step_acc = CONFIG.step_time # 바로 첫 걸음


func _enter_light(duration: float, first: bool) -> void:
	_state = State.LIGHT
	_t_left = duration
	_light_dur = duration
	_moving = false
	_set_lit(true, true)
	var seen: Array[Vector2i] = OwlRules.all_vision(OwlLevel.map(), OwlLevel.WATCHERS, _cycle)
	for c in _vision_tiles:
		_vision_tiles[c].visible = seen.has(c)
	for i in _watchers.size():
		var s: Dictionary = OwlRules.watcher_at(OwlLevel.WATCHERS[i]["path"], _cycle)
		_watchers[i].position = _world(s["pos"])
		_watchers[i].face(s["dir"])
		_watchers[i].set_present(true)
	$HUD/StateLabel.text = "불 켜짐: 외우세요!"
	$HUD/CycleLabel.text = "어둠 %d / %d" % [_cycle, CONFIG.cycles]
	_hint.text = ""
	if not first:
		if seen.has(_cell):
			_finish(false, "불이 켜지자 감시자와 눈이 딱 마주쳤다.")
			return
		_near_missed = _near_missed or OwlRules.is_near(_cell, seen)
		if _cycle >= CONFIG.cycles:
			$HUD/StateLabel.text = "마지막 불! 이제 어둠은 오지 않는다"


# 불이 켜진 동안: 시야를 watch_hold초 보여 준 뒤 끄고, 감시자가 ① 걸어갈 쪽으로 몸을 돌리고 ② 다음 자리로 걸어간 뒤
# ③ 다음에 볼 방향으로 몸을 돌린다. 깜빡임이 시작되기 전에 다 끝내 다음 시야를 미리 보여 준다. 두리번 칸이면 걷지 않고 몸만 돌린다.
# 다음 불이 켜질 때 _enter_light가 같은 자리·방향에 세우므로 이어진다. 판정은 켜지는 순간뿐이라 움직이는 동안엔 시야가 없다
func _walk_watchers() -> void:
	var e: float = _light_dur - _t_left - CONFIG.watch_hold # 움직이기 시작한 뒤 지난 시간
	if e > 0.0:
		for tile in _vision_tiles.values():
			tile.visible = false
	var turn: float = CONFIG.turn_time
	var walk_end: float = maxf(_light_dur - CONFIG.flicker - CONFIG.watch_hold, 3.0 * turn) - turn # 걷기가 끝나는 때. 그 뒤 turn초 동안 다음 방향으로 돈다
	var walk_p: float = clampf((e - turn) / (walk_end - turn), 0.0, 1.0)
	for i in _watchers.size():
		var path: Array = OwlLevel.WATCHERS[i]["path"]
		var now: Dictionary = OwlRules.watcher_at(path, _cycle)
		var nxt: Dictionary = OwlRules.watcher_at(path, _cycle + 1)
		var moving: bool = now["pos"] != nxt["pos"]
		var walk_dir: Vector2i = Vector2i((nxt["pos"] - now["pos"]).sign()) if moving else now["dir"]
		var angle: float
		if e < turn: # ① 걸어갈 쪽으로(평소 순찰은 이미 그쪽을 보고 있어 그대로)
			angle = lerp_angle(_facing(now["dir"]), _facing(walk_dir), clampf(e / turn, 0.0, 1.0))
		elif e < walk_end: # ② 걷기: 늘 앞을 보고 걷는다
			angle = _facing(walk_dir)
		else: # ③ 다음에 볼 방향으로
			angle = lerp_angle(_facing(walk_dir), _facing(nxt["dir"]), clampf((e - walk_end) / turn, 0.0, 1.0))
		_watchers[i].rotation.y = angle
		_watchers[i].position = _world(now["pos"]).lerp(_world(nxt["pos"]), walk_p)
		_watchers[i].set_walking(moving and walk_p > 0.0 and walk_p < 1.0)


# 격자 방향 → 인형 y회전(Watcher.face와 같은 식, 인형 앞 = +z)
func _facing(dir: Vector2i) -> float:
	return atan2(dir.x, dir.y)


func _enter_dark() -> void:
	if _cycle >= CONFIG.cycles:
		_finish(false, "날이 밝아 버렸다. 투표함이 아직 남았다.")
		return
	_state = State.DARK
	_t_left = CONFIG.dark_time
	$HUD/StateLabel.text = "불 꺼짐: 이동!"
	_set_lit(false, false)


func _move(delta: float) -> void:
	if not _moving:
		return
	_step_acc += delta
	while _step_acc >= CONFIG.step_time and _moving:
		_step_acc -= CONFIG.step_time
		var d: Vector2i = Vector2i.ZERO
		if _cell.x != _target.x:
			d = Vector2i(signi(_target.x - _cell.x), 0)
		elif _cell.y != _target.y:
			d = Vector2i(0, signi(_target.y - _cell.y))
		else:
			_moving = false
			break
		var next: Vector2i = _cell + d
		if OwlRules.is_wall(OwlLevel.map(), next):
			_moving = false
			_hint.text = "쿵! 방해물이다."
			break
		_cell = next
		var bi: int = OwlLevel.BOXES.find(_cell)
		if bi >= 0 and not _done[bi]:
			_done[bi] = true
			_box_meshes[bi].set_done(true)
			_hint.text = "투표함 처리! (%d / %d)" % [_done.count(true), _done.size()]
			if not _done.has(false):
				_finish(true, "")
				return


func _finish(ok: bool, msg: String) -> void:
	if _state == State.ENDED:
		return
	_state = State.ENDED
	_set_lit(true, true)
	var rank: Grade.Rank = OwlRules.judge(ok, _near_missed)
	if ok:
		msg = "불이 켜지자 투표함은 아무 일 없다는 듯 서 있었다." if rank == Grade.Rank.PERFECT else "눈이 마주칠 뻔했지만, 투표함은 이미 손을 탄 뒤였다."
	await get_tree().create_timer(1.0).timeout
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _world(c: Vector2i) -> Vector3:
	return Vector3((c.x - (OwlLevel.SIZE.x - 1) * 0.5) * CELL, 0.0, (c.y - (OwlLevel.SIZE.y - 1) * 0.5) * CELL)


func _pawn_pos(c: Vector2i) -> Vector3:
	return _world(c) + Vector3(0.0, 0.45, 0.0)


func _cell_of(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / CELL + (OwlLevel.SIZE.x - 1) * 0.5), roundi(p.z / CELL + (OwlLevel.SIZE.y - 1) * 0.5))


# --- 화면 ---

# 불 켜짐/꺼짐 연출. 불이 꺼지면 맵 소품(방해물·투표함·감시자·시야)이 안 보이고 말만 남는다
func _set_lit(lit: bool, show_props: bool) -> void:
	_props.visible = show_props and lit
	_env.ambient_light_energy = 0.6 if lit else 0.12
	_env.background_color = PALETTE.background if lit else PALETTE.background.darkened(0.8)
	$Sun.light_energy = 1.0 if lit else 0.1


func _mat(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = _mat(color)
	return m


# 겉모습은 이 함수에만 모아 두어 스타일 확정 때 한 곳에서 교체한다
func _build_visuals() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = PALETTE.background
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.WHITE
	_env.ambient_light_energy = 0.6
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = _env
	add_child(we)

	for r in OwlLevel.SIZE.y:
		for c in OwlLevel.SIZE.x:
			var cell: Vector2i = Vector2i(c, r)
			var tile: MeshInstance3D = _box(Vector3(CELL * 0.94, 0.1, CELL * 0.94), PALETTE.paper)
			tile.position = _world(cell) + Vector3(0.0, -0.05, 0.0)
			add_child(tile) # 바닥은 불이 꺼져도 어렴풋이 보인다
			var sight: MeshInstance3D = _box(Vector3(CELL * 0.94, 0.04, CELL * 0.94), PALETTE.danger)
			sight.position = _world(cell) + Vector3(0.0, 0.02, 0.0)
			sight.visible = false
			_props.add_child(sight)
			_vision_tiles[cell] = sight
	for piece in OwlLevel.PIECES:
		var prop: Node3D = PROPS[piece["kind"]].instantiate()
		prop.position = _world(piece["at"])
		prop.rotation.y = -int(piece["rot"]) * PI * 0.5 # 칸 회전 (x, y) -> (-y, x)과 같은 방향
		_props.add_child(prop)
		for c in OwlLevel.cells(piece): # 막힌 칸 바닥을 어둡게 해 모양이 얇은 물건도 칸이 보이게
			var shade: MeshInstance3D = _box(Vector3(CELL * 0.94, 0.012, CELL * 0.94), PALETTE.furniture.lightened(0.15))
			shade.position = _world(c) + Vector3(0.0, 0.006, 0.0)
			_props.add_child(shade)
	for b in OwlLevel.BOXES:
		var bm: OwlBallotBox = BALLOT_BOX.instantiate()
		bm.position = _world(b)
		_props.add_child(bm)
		_box_meshes.append(bm)
	for w in OwlLevel.WATCHERS:
		var inst: Watcher = WATCHER.instantiate()
		_props.add_child(inst)
		_watchers.append(inst)

	_pawn = _box(Vector3(CELL * 0.5, 0.9, CELL * 0.5), PALETTE.mincho)
	_pawn.position = _world(OwlLevel.START) + Vector3(0.0, 0.45, 0.0)
	add_child(_pawn)
