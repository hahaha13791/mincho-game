class_name BallotBoxRules
extends RefCounted


## margin = 참관인 도착까지 남은 초 (뚜껑을 닫은 순간)
static func judge(fill: int, target: int, margin: float, safe_margin: float) -> Grade.Rank:
	if fill < target:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if margin >= safe_margin else Grade.Rank.SUCCESS
