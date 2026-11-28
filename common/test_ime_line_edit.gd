extends SceneTree
## 실행: godot --headless --path . -s res://common/test_ime_line_edit.gd


func _init() -> void:
	var fails: int = 0
	for c: Array in [["핫", "하"], ["닭", "달"], ["한", "하"], ["가", "가"], ["값", "갑"]]:
		if ImeLineEdit.drop_final(c[0]) != c[1]:
			fails += 1
			printerr("FAIL: %s → %s (got %s)" % [c[0], c[1], ImeLineEdit.drop_final(c[0])])
	if ImeLineEdit.is_syllable("ㄱ") or not ImeLineEdit.is_syllable("가"):
		fails += 1
		printerr("FAIL: is_syllable")
	print("TEST OK" if fails == 0 else "TEST FAILED: %d" % fails)
	quit(fails)
