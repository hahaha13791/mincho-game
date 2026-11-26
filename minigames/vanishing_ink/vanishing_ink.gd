extends Node3D
## 사라지는 잉크(id: vanishing_ink). 마우스나 Space를 누르는 동안 다리미를 댄다. 김이 나면 기표가 지워진 것이고,
## 그 뒤 다리미 둘레가 타기 전에 떼야 성공. 한 번 떼면 그 라운드는 끝이다.
## 종이는 왼쪽에서 들어와 오른쪽으로 나간다. 종이마다 지워지는 시간이 빠름·보통·느림으로 다르고, 누레지는 속도도 그에 비례한다.
## 김 나기 전에 떼도 충분히 댔으면 기표가 옅게 남는다(지운 장으로 치지만 완전범죄는 아님).

enum State { TUTORIAL, READY, IRONING, BETWEEN, ENDED }

const PALETTE: Palette = preload("res://common/style/palette.tres")
const CONFIG: IroningConfig = preload("res://minigames/vanishing_ink/ironing_config.tres")
const IRON: PackedScene = preload("res://minigames/vanishing_ink/props/iron.tscn")
const IRON_SCRIPT: Script = preload("res://minigames/vanishing_ink/props/iron.gd")
const STAMP_MARK: PackedScene = preload("res://common/stamp_mark.tscn")
const PAPER_SIZE: Vector3 = Vector3(5.6, 0.1, 4.0) # 그을음 띠(바닥판 + 띠 두께)가 종이 안에 들어오게
const SCORCH_WIDTH: float = 0.45 # 그을음 띠 = 바닥판 윤곽을 이 두께만큼 고르게 넓히고 모서리를 둥글린 모양. 바닥판 밖으로 나온 둘레만 보인다
const IRON_REST_POS: Vector3 = Vector3(0.0, 3.5, 0.0) # 종이 바로 위에 들어 둔다
const IRON_PRESS_POS: Vector3 = Vector3(0.0, 0.45, 0.0) # 수직으로 내려와 종이 가운데(기표 위)를 덮는다
const PAPER_OFF_X: float = 13.0 # 종이가 들어오고 나가는 화면 밖 거리
const SLIDE_TIME: float = 0.3
const BETWEEN_TIME: float = 0.7
const INTRO_TEXT: String = "기표소 펜을 열을 받으면 지워지는 잉크로 몰래 바꿔 두었다. 반민초 표를 다리미로 다리면 아무도 찍지 않은 기권 표가 될 것이다." # 튜토리얼 위 칸: 어떤 수법인지
const TUTORIAL_TEXT: String = "반민초 표의 빨간 기표를 다리미로 지우세요. 마우스나 Space를 누르고 있으면 다리미가 내려갑니다.\n김이 나면 다 지워졌다는 뜻입니다. 그때 손을 떼세요!\n너무 오래 대면 다리미 둘레가 누레지다가 타 버립니다. 빨리 누레지는 종이는 빨리 지워집니다.\n조금 일찍 떼면 기표가 옅게 남습니다. 한 번 떼면 다시 댈 수 없습니다!"

@export var id: StringName = &"vanishing_ink"

var _state: State = State.TUTORIAL
var _round: int = 0
var _successes: int = 0 # 깨끗이 지운 장
var _faints: int = 0 # 옅게 남은 장
var _min_margin: float = INF # 깨끗이 지운 장 중 가장 빠듯했던 여유(김 남 → 탐 사이 비율)
var _tier_bag: PackedFloat32Array = PackedFloat32Array() # 아직 안 낸 속도 단계
var _t: float = 0.0
var _steam_at: float = 0.0
var _burn_at: float = 0.0
var _steamed: bool = false
var _paper: Node3D # 종이 묶음(종이·그을음 띠·기표). 이것만 좌우로 미끄러진다
var _paper_mat: StandardMaterial3D
var _scorch_mat: StandardMaterial3D
var _mark: Node3D # 지울 반민초 기표
var _iron: Node3D
var _steam: CPUParticles3D
var _iron_tween: Tween

@onready var _camera: Camera3D = $Camera3D
@onready var _hint: Label = $HUD/HintLabel


func _ready() -> void:
	$Sun.rotation_degrees = Vector3(-50.0, 20.0, 0.0)
	_camera.look_at_from_position(Vector3(0.0, 7.0, 7.0), Vector3.ZERO)
	_build_visuals()
	Tutorial.open(self, INTRO_TEXT, TUTORIAL_TEXT, _start)


func _process(delta: float) -> void:
	if _state != State.IRONING:
		return
	_t += delta
	_scorch_mat.albedo_color = PALETTE.paper.lerp(PALETTE.scorch, clampf(_t / _burn_at, 0.0, 1.0))
	if not _steamed and _t >= _steam_at:
		_steamed = true
		_mark.hide()
		_steam.emitting = true
	if _t >= _burn_at:
		_end_round(false, "앗, 종이가 타 버렸다!", true)


func _unhandled_input(event: InputEvent) -> void:
	var down: bool
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		down = event.pressed
	elif event.is_action("mg_action") and not event.is_echo(): # Space를 누르고 있는 동안 = 마우스를 누르고 있는 동안
		down = event.is_pressed()
	else:
		return
	if down and _state == State.READY:
		_state = State.IRONING
		_hint.text = "…"
		_move_iron(IRON_PRESS_POS)
	elif not down and _state == State.IRONING:
		_release()


func _start() -> void:
	_round = 0
	_next_round()


func _next_round() -> void:
	_round += 1
	_t = 0.0
	_steamed = false
	if _tier_bag.is_empty(): # 단계를 한 번씩 다 낸 뒤 다시 섞는다. 같은 속도가 몰리지 않게
		_tier_bag = CONFIG.steam_tiers.duplicate()
	var pick: int = randi() % _tier_bag.size()
	if _tier_bag.size() > 1 and is_equal_approx(_tier_bag[pick], _steam_at): # 다시 섞은 직후에도 직전 단계와 겹치지 않게
		pick = (pick + 1) % _tier_bag.size()
	_steam_at = _tier_bag[pick]
	_tier_bag.remove_at(pick)
	_burn_at = _steam_at * CONFIG.burn_ratio
	_paper_mat.albedo_color = PALETTE.paper
	_scorch_mat.albedo_color = PALETTE.paper
	_mark.show()
	_mark.set_alpha(1.0)
	_steam.emitting = false
	_move_iron(IRON_REST_POS)
	$HUD/RoundLabel.text = "%d / %d장" % [_round, CONFIG.rounds]
	_hint.text = ""
	_paper.position.x = -PAPER_OFF_X
	await _slide_paper(0.0)
	_hint.text = "마우스나 Space를 꾹 누르세요"
	_state = State.READY


func _slide_paper(x: float) -> Signal:
	var t: Tween = create_tween()
	t.tween_property(_paper, "position:x", x, SLIDE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if x == 0.0 else Tween.EASE_IN)
	return t.finished


func _release() -> void:
	_move_iron(IRON_REST_POS)
	_scorch_mat.albedo_color = PALETTE.paper # 다리미를 들면 열기가 빠져 둘레가 하얗게 돌아온다
	if _t < _steam_at:
		var alpha: float = VanishingInkRules.faint_alpha(_t / _steam_at, CONFIG.faint_from)
		if alpha >= 1.0:
			_end_round(false, "너무 일찍 뗐다. 기표가 그대로다.", false)
			return
		_faints += 1
		_mark.set_alpha(alpha)
		_end_round(false, "조금 일렀다. 기표가 옅게 남았다… 눈 나쁜 참관인이길.", false)
		return
	_min_margin = minf(_min_margin, (_burn_at - _t) / (_burn_at - _steam_at))
	_end_round(true, "기표가 감쪽같이 사라졌다.", false)


func _end_round(ok: bool, msg: String, burned: bool) -> void:
	_state = State.BETWEEN
	if ok:
		_successes += 1
	if burned:
		_paper_mat.albedo_color = PALETTE.burnt
		_scorch_mat.albedo_color = PALETTE.burnt
		_move_iron(IRON_REST_POS)
	_hint.text = msg
	await get_tree().create_timer(BETWEEN_TIME).timeout
	_steam.emitting = false
	await _slide_paper(PAPER_OFF_X)
	if _round >= CONFIG.rounds:
		_finish()
	else:
		_next_round()


func _finish() -> void:
	_state = State.ENDED
	_hint.text = ""
	var rank: Grade.Rank = VanishingInkRules.judge(_successes, _faints, CONFIG.rounds, CONFIG.need_success, _min_margin, CONFIG.safe_margin)
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


func _move_iron(pos: Vector3) -> void:
	if _iron_tween != null:
		_iron_tween.kill()
	_iron_tween = create_tween()
	_iron_tween.tween_property(_iron, "position", pos, 0.15)


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

	_paper = Node3D.new()
	_paper.position.x = -PAPER_OFF_X
	add_child(_paper)
	var sheet: MeshInstance3D = _box(PAPER_SIZE, PALETTE.paper)
	sheet.position.y = PAPER_SIZE.y / 2.0
	_paper_mat = (sheet.mesh as BoxMesh).material as StandardMaterial3D
	_paper.add_child(sheet)

	# 그을음 띠: 다리미 바닥판과 같은 모양(조금 크게)으로 다리미 놓이는 자리에 깐다. 다리미와 같은 회전(앞이 -x)
	var scorch: CSGPolygon3D = CSGPolygon3D.new()
	scorch.polygon = Geometry2D.offset_polygon(IRON_SCRIPT.SOLE, SCORCH_WIDTH, Geometry2D.JOIN_ROUND)[0]
	scorch.depth = 0.01
	scorch.rotation.x = PI / 2.0 # 다리미 바닥판(iron.gd의 _slab)과 같은 방식으로 눕힌다
	scorch.position = Vector3(IRON_PRESS_POS.x, PAPER_SIZE.y, IRON_PRESS_POS.z)
	_scorch_mat = StandardMaterial3D.new()
	_scorch_mat.albedo_color = PALETTE.paper
	scorch.material = _scorch_mat
	_paper.add_child(scorch)

	_mark = STAMP_MARK.instantiate() # 반민초 쪽에 찍힌 '卜' 기표. 기본 인주색(빨강), 다른 미니게임의 반민초 기표와 같음
	_mark.scale = Vector3.ONE * 2.4
	_mark.position = Vector3(0.0, PAPER_SIZE.y + 0.015, 0.0)
	_mark.rotation.y = 0.15
	_paper.add_child(_mark)

	_iron = IRON.instantiate() # 바닥판이 안쪽 면을 덮고 테두리만 드러남
	_iron.position = IRON_REST_POS
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
	_steam.position = Vector3(0.0, 0.8, 0.0)
	add_child(_steam)
