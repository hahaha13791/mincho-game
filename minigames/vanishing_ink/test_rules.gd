extends SceneTree
## 실행: godot --headless --path . -s res://minigames/vanishing_ink/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(VanishingInkRules.judge(1, 3, 2, 1.0, 0.6) == Grade.Rank.CAUGHT, "성공 수 미달은 적발")
	_check(VanishingInkRules.judge(3, 3, 2, 1.0, 0.6) == Grade.Rank.PERFECT, "전부 여유 있게 성공은 완전범죄")
	_check(VanishingInkRules.judge(3, 3, 2, 0.2, 0.6) == Grade.Rank.SUCCESS, "전부 성공해도 아슬아슬하면 미션성공")
	_check(VanishingInkRules.judge(2, 3, 2, 1.0, 0.6) == Grade.Rank.SUCCESS, "한 번 놓치면 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
