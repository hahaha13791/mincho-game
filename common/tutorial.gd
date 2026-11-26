class_name Tutorial
extends CanvasLayer
## 공통 튜토리얼 틀. 미니게임은 _ready()에서 Tutorial.open(self, 수법 소개, 설명, _start)만 호출한다.
## 위 칸: 미니게임 이름(크게) + 어떤 부정선거 수법인지 / 구분선 / 아래 칸: 조작법 + [시작].
## 이름은 main/minigame_list.tres에서 미니게임 씬 경로로 찾는다(이름은 그 파일에만 둔다).
## 설명은 몇 초 안에 읽혀야 한다. 모양은 디자인 단계에서 이 파일 한 곳만 고친다.

const LIST: MinigameList = preload("res://main/minigame_list.tres")
const PALETTE: Palette = preload("res://common/style/palette.tres")
const WIDTH: float = 1000.0
const TITLE_SIZE: int = 80 # 손글씨체는 같은 크기에서 작아 보여서 소개글보다 확실히 크게
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
	var title: Label = _label(_display_name(host), TITLE_SIZE)
	title.theme_type_variation = &"HandLabel"
	box.add_child(title)
	var intro_label: Label = _label(intro, INTRO_SIZE)
	box.add_child(intro_label)
	var line: HSeparator = HSeparator.new()
	line.custom_minimum_size = Vector2(WIDTH, 0)
	box.add_child(line)
	var rules_label: Label = _label(text, RULES_SIZE)
	box.add_child(rules_label)
	var button: Button = Button.new()
	button.text = "시작"
	button.custom_minimum_size = Vector2(300, 80) # 타이틀 버튼과 같은 크기
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void:
		screen.queue_free()
		on_start.call())
	box.add_child(button)
	host.add_child(screen)
	wrap_words(intro_label, WIDTH) # 글꼴은 트리에 들어간 뒤에야 테마에서 얻는다
	wrap_words(rules_label, WIDTH)


## 띄어쓰기에서만 줄을 바꾼다. Godot 자동 줄바꿈은 한글을 음절 사이("개표하/면")에서도 끊는다.
## 줄 수는 그대로 두고 폭을 줄여 가며 줄 길이를 고르게 한다(마지막 줄에 한 단어만 남지 않게).
## 한 단어가 width보다 길면 그 단어만 자동 줄바꿈에 맡긴다
static func wrap_words(label: Label, width: float) -> void:
	var font: Font = label.get_theme_font("font")
	var size: int = label.get_theme_font_size("font_size")
	var out: PackedStringArray = []
	for paragraph in label.text.split("\n"):
		var lines: PackedStringArray = _greedy(paragraph, font, size, width)
		var w: float = width
		while lines.size() > 1:
			var tighter: PackedStringArray = _greedy(paragraph, font, size, w - 10.0)
			if tighter.size() != lines.size():
				break
			lines = tighter
			w -= 10.0
		out.append_array(lines)
	label.text = "\n".join(out)


static func _greedy(paragraph: String, font: Font, size: int, width: float) -> PackedStringArray:
	var lines: PackedStringArray = []
	var line: String = ""
	for word in paragraph.split(" ", false):
		var tried: String = word if line.is_empty() else line + " " + word
		if line.is_empty() or font.get_string_size(tried, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
			line = tried
		else:
			lines.append(line)
			line = word
	lines.append(line)
	return lines


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
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", PALETTE.paper) # 기본 글씨색(진한 잉크)은 어두운 배경에 묻힌다
	return label
