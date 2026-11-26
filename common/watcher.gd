class_name Watcher
extends Node3D
## 감시자. 겉모습은 이 서브씬에만 있다. 로직은 set_present()와 face()만 쓴다.
## 모델은 assets/figure/figure.glb(하얀 인형)에 재킷·바지·넥타이·선글라스. 완장(Armband)은 만들어만 두었다.

const PALETTE: Palette = preload("res://common/style/palette.tres")

var _walking: bool = false

@onready var _figure: Node3D = $Figure


func _ready() -> void:
	FigureLook.dress(_figure, {
		"Body": PALETTE.doll, # V자 앞섶 안으로 보이는 흰 몸이 셔츠 역할
		"Jacket": PALETTE.suit,
		"Pants": PALETTE.suit.darkened(0.35), # 재킷보다 어둡게 해 위아래 구분
		"Tie": PALETTE.tie,
		"Sunglasses": PALETTE.sunglasses,
	})
	FigureLook.play(_figure, "idle")


func set_present(on: bool) -> void:
	visible = on


## 걷기/서 있기 애니메이션 전환. 이동 자체는 쓰는 쪽이 position으로 한다
func set_walking(on: bool) -> void:
	if on != _walking:
		_walking = on
		FigureLook.play(_figure, "walk" if on else "idle")


## 격자 방향(열, 행)을 바라본다. 행은 월드 +z. 방향이 없으면 그대로 둔다
func face(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO:
		rotation.y = atan2(dir.x, dir.y) # 인형 앞은 +z
