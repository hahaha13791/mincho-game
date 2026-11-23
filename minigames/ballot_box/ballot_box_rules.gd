class_name BallotBoxRules
extends RefCounted


## 마지막 방문 때 호출. overflow = 표가 선을 넘음, margin = 모든 방문 중 가장 빠듯했던 "닫은 시점 → 도착" 간격(초)
static func judge(count: int, target: int, overflow: bool, margin: float, safe_margin: float) -> Grade.Rank:
	if overflow or count < target:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if margin >= safe_margin else Grade.Rank.SUCCESS
