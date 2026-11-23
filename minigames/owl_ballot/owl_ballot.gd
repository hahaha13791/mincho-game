extends Node3D
## 올빼미표(id: owl_ballot). 불이 켜진 동안 맵(방해물·투표함·감시자 시야)을 외우고, 꺼진 동안에만 움직여 투표함을 처리한다.
## 불이 켜지는 순간 감시자 시야에 있으면 적발. 이동은 칸을 클릭하면 가로 먼저, 세로 다음으로 걸어가며 방해물에서 멈춘다.

enum State { TUTORIAL, LIGHT, DARK, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: OwlConfig = preload("res://minigames/owl_ballot/owl_config.tres")
const WATCHER: PackedScene = preload("res://common/watcher.tscn")
const CELL: float = 1.2
const TUTORIAL_TEXT: String = "불이 켜진 동안 방해물, 투표함(파랑), 감시자의 시야(빨강)를 외우세요. 이때는 움직일 수 없습니다.\n불이 꺼지면 칸을 클릭해 이동합니다. 가로로 먼저, 세로로 걸어가며 방해물에서 멈춥니다.\n투표함 칸에 들어가면 손을 쓴 것입니다. 전부 처리하면 성공!\n불이 켜지는 순간 감시자 시야에 있으면 들킵니다. 깜빡이면 곧 전환됩니다. 감시자는 일정한 순서로 움직입니다."

@export var id: StringName = &"owl_ballot"

var _state: State = State.TUTORIAL
var _cycle: int = 0 # 불이 켜진 횟수 (처음 켜짐 = 0)
var _t_left: float = 0.0
var _cell: Vector2i
var _target: Vector2i
var _moving: bool = false
var _step_acc: float = 0.0
var _done: Array[bool] = []
var _near_missed: bool = false
var _env: Environment
var _pawn: MeshInstance3D
var _box_meshes: Array[MeshInstance3D] = []
var _vision_tiles: Dictionary = {} # Vector2i -> MeshInstance3D
var _watchers: Array[Watcher] = []

@onready var _camera: Camera3D = $Camera3D
@onready var _props: Node3D = $Props
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-60.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 11.0, 6.0), Vector3.ZERO)
	_build_visuals()
	Tutorial.open(self, TUTORIAL_TEXT, _start)


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
	_moving = false
	_set_lit(true, true)
	var seen: Array[Vector2i] = OwlRules.all_vision(OwlLevel.MAP, OwlLevel.WATCHERS, _cycle)
	for c in _vision_tiles:
		_vision_tiles[c].visible = seen.has(c)
	for i in _watchers.size():
		var s: Dictionary = OwlRules.watcher_at(OwlLevel.WATCHERS[i]["path"], _cycle)
		_watchers[i].position = _world(s["pos"])
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
			$HUD/StateLabel.text = "마지막 불! (이후 시간 초과)"


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
		if OwlRules.is_wall(OwlLevel.MAP, next):
			_moving = false
			_hint.text = "쿵! 방해물이다."
			break
		_cell = next
		var bi: int = OwlLevel.BOXES.find(_cell)
		if bi >= 0 and not _done[bi]:
			_done[bi] = true
			_box_meshes[bi].material_override = _mat(PALETTE.mincho)
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
	return Vector3((c.x - 4) * CELL, 0.0, (c.y - 3) * CELL)


func _pawn_pos(c: Vector2i) -> Vector3:
	return _world(c) + Vector3(0.0, 0.45, 0.0)


func _cell_of(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / CELL) + 4, roundi(p.z / CELL) + 3)


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

	var rows: int = OwlLevel.MAP.size()
	var cols: int = OwlLevel.MAP[0].length()
	for r in rows:
		for c in cols:
			var cell: Vector2i = Vector2i(c, r)
			var tile: MeshInstance3D = _box(Vector3(CELL * 0.94, 0.1, CELL * 0.94), PALETTE.paper)
			tile.position = _world(cell) + Vector3(0.0, -0.05, 0.0)
			add_child(tile) # 바닥은 불이 꺼져도 어렴풋이 보인다
			var sight: MeshInstance3D = _box(Vector3(CELL * 0.94, 0.04, CELL * 0.94), PALETTE.danger)
			sight.position = _world(cell) + Vector3(0.0, 0.02, 0.0)
			sight.visible = false
			_props.add_child(sight)
			_vision_tiles[cell] = sight
			if OwlLevel.MAP[r][c] == "#":
				var wall: MeshInstance3D = _box(Vector3(CELL * 0.9, 0.9, CELL * 0.9), PALETTE.iron)
				wall.position = _world(cell) + Vector3(0.0, 0.45, 0.0)
				_props.add_child(wall)
	for b in OwlLevel.BOXES:
		var bm: MeshInstance3D = _box(Vector3(CELL * 0.6, 0.6, CELL * 0.6), PALETTE.ballot_box)
		bm.position = _world(b) + Vector3(0.0, 0.3, 0.0)
		_props.add_child(bm)
		_box_meshes.append(bm)
	for w in OwlLevel.WATCHERS:
		var inst: Watcher = WATCHER.instantiate()
		_props.add_child(inst)
		_watchers.append(inst)

	_pawn = _box(Vector3(CELL * 0.5, 0.9, CELL * 0.5), PALETTE.mincho)
	_pawn.position = _world(OwlLevel.START) + Vector3(0.0, 0.45, 0.0)
	add_child(_pawn)
