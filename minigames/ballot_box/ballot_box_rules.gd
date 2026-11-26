class_name BallotBoxRules
extends RefCounted


## 마지막 방문 때 호출. overflow = 표가 선을 넘음, margin = 모든 방문 중 가장 빠듯했던 "닫은 시점 → 도착" 간격(초)
## perfect_count 이상 + 여유 있게 닫음 = 완전범죄, success_count 이상 = 미션성공
static func judge(count: int, perfect_count: int, success_count: int, overflow: bool, margin: float, safe_margin: float) -> Grade.Rank:
	if overflow or count < success_count:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if count >= perfect_count and margin >= safe_margin else Grade.Rank.SUCCESS
