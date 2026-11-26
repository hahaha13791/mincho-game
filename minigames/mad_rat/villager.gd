class_name Villager
extends Node3D
## 주민. 겉모습은 이 서브씬에만 있다. 로직은 setup()과 is_mincho만 쓴다.
## 모델은 assets/figure/figure.glb(하얀 인형). 입히는 방법은 FigureLook.

const PALETTE: Palette = preload("res://common/style/palette.tres")

var is_mincho: bool = true


@onready var _figure: Node3D = $Figure


func _ready() -> void:
	FigureLook.play(_figure, "walk")


## 정체는 mincho. 변칙(twist)에 따라 겉모습만 바뀐다(판정 규칙은 MadRatRules.Twist 설명)
func setup(mincho: bool, twist: MadRatRules.Twist) -> void:
	is_mincho = mincho
	var own: Color = PALETTE.mincho if mincho else PALETTE.anti_mincho
	var other: Color = PALETTE.anti_mincho if mincho else PALETTE.mincho
	var outfit: Dictionary = {"Body": PALETTE.doll, "Shirt": own}
	match twist:
		MadRatRules.Twist.HAT:
			outfit["Hat"] = other
		MadRatRules.Twist.COAT:
			outfit.erase("Shirt")
			outfit["Coat"] = PALETTE.suit
			outfit["Armband"] = own
		MadRatRules.Twist.GLASSES:
			outfit["Shirt"] = other
			outfit["Sunglasses"] = PALETTE.sunglasses
	FigureLook.dress(_figure, outfit)
