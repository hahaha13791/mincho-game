class_name FigureLook
extends RefCounted
## assets/figure/figure.glb(하얀 인형)의 겉모습 도우미. 인물 서브씬(주민·감시자 등)이 같이 쓴다.
## glb 안 파츠: Body, Shirt, Hat, Jacket, Pants, Tie, Sunglasses, Armband / 애니메이션: walk, idle


## outfit에 적은 파츠만 보이고 그 색으로 칠한다. 적지 않은 파츠는 숨긴다
static func dress(figure: Node3D, outfit: Dictionary) -> void:
	for m in figure.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = m
		mesh.visible = outfit.has(String(mesh.name))
		if mesh.visible:
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = outfit[String(mesh.name)]
			mesh.material_override = mat


## 애니메이션을 반복 재생한다
static func play(figure: Node3D, anim_name: String) -> void:
	var player: AnimationPlayer = figure.find_child("AnimationPlayer", true, false)
	player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	player.play(anim_name)
