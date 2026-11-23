class_name MinigameEntry
extends Resource

## 폴더명과 같은 영문 고정 id
@export var id: StringName
@export var display_name: String
## 씬이 아직 없으면 빈 문자열 (선택 화면에서 "준비 중")
@export_file("*.tscn") var scene: String = ""
