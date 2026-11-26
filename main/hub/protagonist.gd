class_name Protagonist
extends Node3D
## 작전본부실의 주인공(민초단원). 겉모습은 이 서브씬에만 있다. 로직은 set_stage()만 쓴다.
## 끝낸 작전 수에 따라 복장이 바뀐다:
##   0~1개 민트 셔츠 / 2~3개 셔츠 대신 머리띠 / 4~5개 머리띠+완장 / 6개 +중절모+초콜릿 코트(민트 배지)

const PALETTE: Palette = preload("res://common/style/palette.tres")

@onready var _figure: Node3D = $Figure


func _ready() -> void:
	FigureLook.play(_figure, "idle")


func set_stage(done: int) -> void:
	var outfit: Dictionary = {"Body": PALETTE.doll}
	if done < 2:
		outfit["Shirt"] = PALETTE.mincho
	else:
		outfit["Headband"] = PALETTE.mincho
	if done >= 4:
		outfit["Armband"] = PALETTE.mincho
	if done >= GameState.MINIGAME_COUNT:
		outfit["Fedora"] = PALETTE.chocolate
		outfit["Coat"] = PALETTE.chocolate
		outfit["Badge"] = PALETTE.mincho
	FigureLook.dress(_figure, outfit)
