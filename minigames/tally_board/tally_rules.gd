class_name TallyRules
extends RefCounted

enum Failure { NONE, ROW, TOTAL, VOTERS }


## 한 칸에서 바꿀 수 있는 최대 폭
static func cap(original: int, ratio: float) -> int:
	return maxi(1, floori(original * ratio))


## 반별 민초(m)·반민초(a) 득표를 뽑는다
static func make_board(cfg: TallyConfig, rng: RandomNumberGenerator) -> Dictionary:
	var m: Array[int] = []
	var a: Array[int] = []
	for i in cfg.classes:
		m.append(rng.randi_range(cfg.m_min, cfg.m_max))
		a.append(rng.randi_range(cfg.a_min, cfg.a_max))
	return {"m": m, "a": a}


## 참관인 검산. s = 반별 합(고정), v = 투표자 수(고정), tm/ta = 맨 아랫줄 민초 합/반민초 합
static func check(s: Array[int], v: int, m: Array[int], a: Array[int], tm: int, ta: int) -> Failure:
	for i in s.size():
		if m[i] + a[i] != s[i]:
			return Failure.ROW
	if tm != _sum(m) or ta != _sum(a):
		return Failure.TOTAL
	if tm + ta != v:
		return Failure.VOTERS
	return Failure.NONE


## 이론상 최대 이득. 맨 아랫줄 두 칸에 2칸을 쓰고, 남은 칸으로 (민초+, 반민초-)를 한 반씩 고친다
static func best_gain(m: Array[int], a: Array[int], ratio: float, budget: int) -> int:
	var k: int = (budget - 2) / 2
	var d: Array[int] = []
	for i in m.size():
		d.append(mini(cap(m[i], ratio), cap(a[i], ratio)))
	d.sort()
	d.reverse()
	var best: int = 0
	for i in mini(k, d.size()):
		best += d[i]
	return mini(best, mini(cap(_sum(m), ratio), cap(_sum(a), ratio)))


## gain = 맨 아랫줄 민초 합의 증가량
static func judge(failure: Failure, gain: int, best: int, perfect_ratio: float, success_ratio: float) -> Grade.Rank:
	if failure != Failure.NONE or gain < ceili(best * success_ratio):
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if gain >= ceili(best * perfect_ratio) else Grade.Rank.SUCCESS


static func _sum(arr: Array[int]) -> int:
	var t: int = 0
	for x in arr:
		t += x
	return t
