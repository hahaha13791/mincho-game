class_name Watcher
extends Node3D
## 감시자. 겉모습은 이 서브씬에만 있다. 로직은 set_present()만 쓴다.


func set_present(on: bool) -> void:
	visible = on
