class_name Tutorial
extends CanvasLayer
## 공통 튜토리얼 틀. 미니게임은 _ready()에서 Tutorial.open(self, 수법 소개, 설명, _start)만 호출한다.
## 위 칸: 미니게임 이름(크게) + 어떤 부정선거 수법인지 / 구분선 / 아래 칸: 조작법 + [시작].
## 이름은 main/minigame_list.tres에서 미니게임 씬 경로로 찾는다(이름은 그 파일에만 둔다).
## 설명은 몇 초 안에 읽혀야 한다. 모양은 디자인 단계에서 이 파일 한 곳만 고친다.

const LIST: MinigameList = preload("res://main/minigame_list.tres")
const PALETTE: Palette = preload("res://common/style/palette.tres")
const WIDTH: float = 1000.0
const INTRO_SIZE: int = 34
const RULES_SIZE: int = 26


static func open(host: Node, intro: String, text: String, on_start: Callable) -> void:
	var screen: Tutorial = Tutorial.new()
	screen.layer = 10
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72) # 뒤 게임 화면이 글자와 겹쳐 읽히지 않을 만큼
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)
	var title: Label = _label(_display_name(host), 0)
	title.theme_type_variation = &"HandLabel"
	title.add_theme_color_override("font_color", PALETTE.paper) # 손글씨 기본색(진한 잉크)은 어두운 배경에 묻힌다
	box.add_child(title)
	box.add_child(_label(intro, INTRO_SIZE))
	var line: HSeparator = HSeparator.new()
	line.custom_minimum_size = Vector2(WIDTH, 0)
	box.add_child(line)
	box.add_child(_label(text, RULES_SIZE))
	var button: Button = Button.new()
	button.text = "시작"
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void:
		screen.queue_free()
		on_start.call())
	box.add_child(button)
	host.add_child(screen)


# 미니게임 씬 경로로 목록에서 표시 이름을 찾는다. 목록에 없으면(단독 실행 등) 빈 칸
static func _display_name(host: Node) -> String:
	for entry in LIST.entries:
		if entry.scene == host.scene_file_path:
			return entry.display_name
	return ""


static func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(WIDTH, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	return label
