extends SceneTree
## 실행: godot --headless --path . -s res://common/test_final_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _ranks(p: int, s: int, c: int) -> Array:
	var out: Array = []
	for i in p:
		out.append(Grade.Rank.PERFECT)
	for i in s:
		out.append(Grade.Rank.SUCCESS)
	for i in c:
		out.append(Grade.Rank.CAUGHT)
	return out


func _init() -> void:
	_check(FinalRules.is_win(50.1) and not FinalRules.is_win(50.0), "50% 동률은 민초 승리가 아님")
	_check(FinalRules.is_special(_ranks(7, 0, 0)) and not FinalRules.is_special(_ranks(6, 1, 0)), "전부 완전범죄만 추가 이벤트")
	_check(not FinalRules.is_special([]), "빈 목록은 추가 이벤트 아님")
	_check(FinalRules.title(_ranks(7, 0, 0), 79.0) == "그림자 민초단장", "전부 완전범죄")
	_check(FinalRules.title(_ranks(0, 0, 7), 9.0) == "민초의 수치, 즉시 제명", "전부 적발")
	_check(FinalRules.title(_ranks(5, 0, 2), 59.0) == "운 좋은 행동대장", "적발 많은데 이김")
	_check(FinalRules.title(_ranks(5, 2, 0), 67.0) == "소리 없는 민초 참모", "적발 없고 완전범죄 다수")
	_check(FinalRules.title(_ranks(0, 7, 0), 54.5) == "동네 민초 대장", "무난하게 이김")
	_check(FinalRules.title(_ranks(0, 6, 1), 48.0) == "얼빵한 민초단원", "아깝게 짐")
	_check(FinalRules.title(_ranks(0, 2, 5), 21.0) == "평범한 민초 애호가", "크게 짐")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
