extends SceneTree
## 실행: godot --headless --path . -s res://minigames/vanishing_ink/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	_check(VanishingInkRules.judge(2, 0, 4, 3, 1.0, 0.35) == Grade.Rank.CAUGHT, "지운 장 수 미달은 적발")
	_check(VanishingInkRules.judge(4, 0, 4, 3, 0.5, 0.35) == Grade.Rank.PERFECT, "전부 여유 있게 지우면 완전범죄")
	_check(VanishingInkRules.judge(4, 0, 4, 3, 0.2, 0.35) == Grade.Rank.SUCCESS, "전부 지워도 아슬아슬하면 미션성공")
	_check(VanishingInkRules.judge(3, 0, 4, 3, 1.0, 0.35) == Grade.Rank.SUCCESS, "한 장 놓치면 미션성공")
	_check(VanishingInkRules.judge(2, 1, 4, 3, 1.0, 0.35) == Grade.Rank.SUCCESS, "옅게 남은 장도 지운 장으로 친다")
	_check(VanishingInkRules.judge(3, 1, 4, 3, 1.0, 0.35) == Grade.Rank.SUCCESS, "옅게 남은 장이 있으면 완전범죄는 아님")
	_check(is_equal_approx(VanishingInkRules.faint_alpha(0.3, 0.6), 1.0), "너무 일찍 떼면 기표 그대로")
	_check(VanishingInkRules.faint_alpha(0.6, 0.6) < 1.0, "기준 이상 댔으면 옅어짐")
	_check(VanishingInkRules.faint_alpha(0.95, 0.6) < VanishingInkRules.faint_alpha(0.7, 0.6), "오래 댈수록 더 옅음")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
