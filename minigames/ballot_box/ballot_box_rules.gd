class_name BallotBoxRules
extends RefCounted


## overflow = 표가 선을 넘어 뚜껑이 안 닫힘, margin = 참관인 도착까지 남은 초 (뚜껑을 닫은 순간)
static func judge(count: int, target: int, overflow: bool, margin: float, safe_margin: float) -> Grade.Rank:
	if overflow or count < target:
		return Grade.Rank.CAUGHT
	return Grade.Rank.PERFECT if margin >= safe_margin else Grade.Rank.SUCCESS
