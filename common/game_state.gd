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
var player_name: String = "" # 타이틀 원서 서명란에 쓴 이름. 비면 리더보드가 '민초단원 N호'로 붙인다


func _ready() -> void:
	reset()


func reset() -> void:
	grades.clear()
	player_name = ""
	mincho_percent = config.start_mincho_percent
	vote_changed.emit(mincho_percent)


func is_done(id: StringName) -> bool:
	return grades.has(id)


## 다시 하면 마지막 등급으로 바꾸고 득표를 등급 전체에서 다시 계산한다. 처음 끝낸 미니게임이면 true.
func submit_result(id: StringName, rank: Grade.Rank) -> bool:
	var first: bool = not is_done(id)
	grades[id] = rank
	var sum: float = config.start_mincho_percent
	for r: Grade.Rank in grades.values():
		sum += config.vote_delta[r]
	mincho_percent = clampf(sum, 0.0, 100.0)
	vote_changed.emit(mincho_percent)
	minigame_finished.emit(id, rank)
	if first and grades.size() >= MINIGAME_COUNT:
		all_finished.emit()
	return first


func total_score() -> int:
	var sum: int = 0
	for rank: Grade.Rank in grades.values():
		sum += config.score[rank]
	return sum
