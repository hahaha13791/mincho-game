class_name Villager
extends Node3D
## 주민. 겉모습은 이 서브씬에만 있다. 로직은 setup()과 is_mincho만 쓴다.
## 모델은 assets/figure/figure.glb(하얀 인형). 입히는 방법은 FigureLook.

const PALETTE: Palette = preload("res://common/style/palette.tres")

var is_mincho: bool = true

@onready var _figure: Node3D = $Figure


func _ready() -> void:
	FigureLook.play(_figure, "walk")


## 옷 색은 is_mincho가 정한다. decoy_hat이면 반대 편 색 모자를 쓴다(헷갈리게 하는 단서, 판정에는 무관)
func setup(mincho: bool, decoy_hat: bool) -> void:
	is_mincho = mincho
	var outfit: Dictionary = {
		"Body": PALETTE.doll,
		"Shirt": PALETTE.mincho if mincho else PALETTE.anti_mincho,
	}
	if decoy_hat:
		outfit["Hat"] = PALETTE.anti_mincho if mincho else PALETTE.mincho
	FigureLook.dress(_figure, outfit)
