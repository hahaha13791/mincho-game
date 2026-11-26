extends Node3D
## 미친 쥐(id: mad_rat). 갈림길로 걸어오는 주민을 옷 색에 따라 왼쪽(투표소)·오른쪽(저수지)으로 보낸다.
## 민초(초록)는 투표소, 반민초(갈색)는 저수지. 모자는 헷갈리게 하는 장식이라 무시한다.

enum State { TUTORIAL, PLAYING, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: MadRatConfig = preload("res://minigames/mad_rat/mad_rat_config.tres")
const VILLAGER: PackedScene = preload("res://minigames/mad_rat/villager.tscn")
const SPAWN_Z: float = -9.0
const JUNCTION_Z: float = 0.0 # 이 선에 닿기 전에 골라야 한다
const EXIT_X: float = 6.5
const TUTORIAL_TEXT: String = "주민이 갈림길로 걸어옵니다. 옷 색을 보고 보내세요.\n초록 옷(민초)은 [투표소], 갈색 옷(반민초)은 [저수지]!\n모자는 헷갈리게 하는 장식입니다. 옷 색만 보세요.\n갈림길에 닿기 전에 고르지 않으면 틀린 것으로 칩니다. 점점 빨라집니다!"

@export var id: StringName = &"mad_rat"

var _state: State = State.TUTORIAL
var _spawned: int = 0
var _wrong: int = 0
var _next_spawn: float = 0.0
var _queue: Array[Villager] = [] # 갈림길에 가까운 주민이 앞(0번)

@onready var _camera: Camera3D = $Camera3D
@onready var _villagers: Node3D = $Villagers
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 9.0, 8.0), Vector3(0.0, 0.0, -2.0))
	_build_visuals()
	$HUD/LeftButton.pressed.connect(_send.bind(MadRatRules.Dir.LEFT))
	$HUD/RightButton.pressed.connect(_send.bind(MadRatRules.Dir.RIGHT))
	Tutorial.open(self, TUTORIAL_TEXT, _start)


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	var p: float = float(_spawned) / CONFIG.villager_count
	if _spawned < CONFIG.villager_count:
		_next_spawn -= delta
		if _next_spawn <= 0.0:
			_spawn(p)
			_next_spawn = lerpf(CONFIG.gap_start, CONFIG.gap_end, p)
	var step: float = lerpf(CONFIG.speed_start, CONFIG.speed_end, p) * delta
	for v in _queue:
		v.position.z += step
	if not _queue.is_empty() and _queue[0].position.z >= JUNCTION_Z:
		_wrong += 1
		_hint.text = "놓쳤다!"
		var missed: Villager = _queue.pop_front()
		_leave(missed, Vector3(missed.position.x, 0.0, 9.0))
		_refresh()
	if _spawned >= CONFIG.villager_count and _queue.is_empty():
		_finish()


func _start() -> void:
	_state = State.PLAYING
	_refresh()


func _spawn(p: float) -> void:
	var v: Villager = VILLAGER.instantiate()
	_villagers.add_child(v)
	v.position = Vector3(0.0, 0.0, SPAWN_Z)
	v.setup(randf() < CONFIG.mincho_ratio, randf() < lerpf(CONFIG.decoy_start, CONFIG.decoy_end, p))
	_queue.append(v)
	_spawned += 1
	_refresh()


func _send(dir: MadRatRules.Dir) -> void:
	if _state != State.PLAYING or _queue.is_empty():
		return
	var v: Villager = _queue.pop_front()
	if MadRatRules.is_correct(v.is_mincho, dir):
		_hint.text = ""
	else:
		_wrong += 1
		_hint.text = "엉뚱한 곳으로 갔다!"
	_leave(v, Vector3(-EXIT_X if dir == MadRatRules.Dir.LEFT else EXIT_X, 0.0, JUNCTION_Z))
	_refresh()


# 판정이 끝난 주민이 걸어나가 사라진다
func _leave(v: Villager, dest: Vector3) -> void:
	v.rotation.y = atan2(dest.x - v.position.x, dest.z - v.position.z) # 주민 앞은 +z
	var t: Tween = create_tween()
	t.tween_property(v, "position", dest, 0.6)
	t.tween_callback(v.queue_free)


func _finish() -> void:
	_state = State.ENDED
	var rank: Grade.Rank = MadRatRules.judge(_wrong, CONFIG.perfect_wrong, CONFIG.success_wrong)
	var msg: String
	match rank:
		Grade.Rank.PERFECT:
			msg = "모두 알아서 제 갈 길을 갔다. 저수지는 오늘도 평화롭다."
		Grade.Rank.SUCCESS:
			msg = "몇 명이 길을 헤맸지만 대체로 계획대로다."
		_:
			msg = "저수지 앞에 민초 주민이 줄을 섰다. 뭔가 잘못됐다."
	var before: float = GameState.mincho_percent
	GameState.submit_result(id, rank)
	ResultScreen.open(self, rank, msg, before)


func _refresh() -> void:
	$HUD/ProgressLabel.text = "%d / %d명  실수 %d" % [_spawned, CONFIG.villager_count, _wrong]


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


func _place(size: Vector3, pos: Vector3, color: Color, text: String) -> void:
	var m: MeshInstance3D = _box(size, color)
	m.position = pos
	add_child(m)
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 96
	label.pixel_size = 0.01
	label.position = Vector3(pos.x, size.y + 0.8, pos.z)
	add_child(label)


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

	var ground: MeshInstance3D = _box(Vector3(24.0, 0.2, 22.0), PALETTE.background.darkened(0.15))
	ground.position = Vector3(0.0, -0.1, -2.0)
	add_child(ground)

	var road: MeshInstance3D = _box(Vector3(2.0, 0.05, 11.0), PALETTE.road)
	road.position = Vector3(0.0, 0.02, -4.5)
	add_child(road)
	var cross: MeshInstance3D = _box(Vector3(2.0 * EXIT_X + 1.0, 0.05, 2.0), PALETTE.road)
	cross.position = Vector3(0.0, 0.02, JUNCTION_Z)
	add_child(cross)

	_place(Vector3(3.0, 1.5, 3.0), Vector3(-EXIT_X - 1.5, 0.75, JUNCTION_Z), PALETTE.ballot_box, "투표소")
	_place(Vector3(3.0, 0.4, 3.0), Vector3(EXIT_X + 1.5, 0.2, JUNCTION_Z), PALETTE.water, "저수지")
