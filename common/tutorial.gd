class_name Tutorial
extends CanvasLayer
## 공통 튜토리얼 틀. 미니게임은 _ready()에서 Tutorial.open(self, 설명, _start)만 호출한다.
## 설명은 몇 초 안에 읽혀야 한다. 모양은 디자인 단계에서 이 파일 한 곳만 고친다.


static func open(host: Node, text: String, on_start: Callable) -> void:
	var screen: Tutorial = Tutorial.new()
	screen.layer = 10
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(900, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	box.add_child(label)
	var button: Button = Button.new()
	button.text = "시작"
	button.pressed.connect(func() -> void:
		screen.queue_free()
		on_start.call())
	box.add_child(button)
	host.add_child(screen)
