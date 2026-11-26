class_name FinalRules
extends RefCounted
## 최종 개표 판정. ranks = 미니게임별 Grade.Rank 목록

const WIN_LINE: float = 50.0


static func is_win(percent: float) -> bool:
	return percent > WIN_LINE


## 모든 미니게임이 완전범죄일 때만 추가 이벤트
static func is_special(ranks: Array) -> bool:
	return not ranks.is_empty() and ranks.count(Grade.Rank.PERFECT) == ranks.size()


## 위에서부터 먼저 맞는 칭호
static func title(ranks: Array, percent: float) -> String:
	var perfect: int = ranks.count(Grade.Rank.PERFECT)
	var caught: int = ranks.count(Grade.Rank.CAUGHT)
	var win: bool = is_win(percent)
	if is_special(ranks):
		return "그림자 민초단장"
	if not ranks.is_empty() and caught == ranks.size():
		return "민초의 수치, 즉시 제명"
	if win and caught >= 2:
		return "운 좋은 행동대장"
	if win and caught == 0 and perfect >= 4:
		return "소리 없는 민초 참모"
	if win:
		return "동네 민초 대장"
	if caught <= 1:
		return "얼빵한 민초단원"
	return "평범한 민초 애호가"
