extends SceneTree
## 실행: godot --headless --path . -s res://minigames/ballot_box/test_rules.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var g: PackingGrid = PackingGrid.new(6, 4)
	var dom: Array = [Vector2i(0, 0), Vector2i(1, 0)]
	_check(g.can_place(dom, Vector2i(0, 0)), "빈 격자에 놓을 수 있다")
	g.place(dom, Vector2i(0, 0), 1)
	_check(g.filled() == 2, "2칸 채움")
	_check(not g.can_place(dom, Vector2i(1, 0)), "겹치면 안 된다")
	_check(not g.can_place(dom, Vector2i(5, 0)), "오른쪽 밖")
	_check(not g.can_place(dom, Vector2i(0, -1)), "아래쪽 밖")
	_check(g.can_place(dom, Vector2i(0, 3)), "맨 윗줄은 가능")
	g.remove(1)
	_check(g.filled() == 0, "제거 후 0칸")

	_check(PackingGrid.rotated(dom) == [Vector2i(0, 0), Vector2i(0, 1)], "2칸 회전")
	var l3: Array = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
	var r: Array = l3
	for i in 4:
		r = PackingGrid.rotated(r)
	_check(r.size() == 3 and l3.all(func(c: Vector2i) -> bool: return r.has(c)), "4번 회전하면 원래대로")

	_check(BallotBoxRules.judge(17, 18, 5.0, 1.0) == Grade.Rank.CAUGHT, "미달은 적발")
	_check(BallotBoxRules.judge(18, 18, 1.0, 1.0) == Grade.Rank.PERFECT, "여유 충분은 완전범죄")
	_check(BallotBoxRules.judge(24, 18, 0.5, 1.0) == Grade.Rank.SUCCESS, "아슬아슬은 미션성공")

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
