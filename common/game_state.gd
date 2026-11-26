extends Node
## 오토로드 `GameState`. 득표와 미니게임별 등급을 관리한다. 미니게임은 submit_result()만 호출한다.

signal vote_changed(mincho_percent: float)
signal minigame_finished(id: StringName, rank: Grade.Rank)
signal all_finished

## 미니게임 7개
const MINIGAME_COUNT: int = 6

var config: VoteConfig = preload("res://common/vote_config.tres")
var mincho_percent: float
var grades: Dictionary = {} # StringName -> Grade.Rank


func _ready() -> void:
	reset()


func reset() -> void:
	grades.clear()
	mincho_percent = config.start_mincho_percent
	vote_changed.emit(mincho_percent)


func is_done(id: StringName) -> bool:
	return grades.has(id)


## 미니게임당 1회만 반영한다. 이미 끝낸 id는 무시하고 false를 반환한다.
func submit_result(id: StringName, rank: Grade.Rank) -> bool:
	if is_done(id):
		return false
	grades[id] = rank
	mincho_percent = clampf(mincho_percent + config.vote_delta[rank], 0.0, 100.0)
	vote_changed.emit(mincho_percent)
	minigame_finished.emit(id, rank)
	if grades.size() >= MINIGAME_COUNT:
		all_finished.emit()
	return true


func total_score() -> int:
	var sum: int = 0
	for rank: Grade.Rank in grades.values():
		sum += config.score[rank]
	return sum
