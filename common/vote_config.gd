class_name VoteConfig
extends Resource

## 시작 득표 (민초 %, 나머지는 반민초)
@export var start_mincho_percent: float = 30.0
## 등급별 민초 득표 변화(%p). 인덱스 = Grade.Rank
@export var vote_delta: Array[float] = [5.0, 2.0, -3.0]
## 등급별 종합점수. 인덱스 = Grade.Rank (임시값, 플레이 테스트로 조정)
@export var score: Array[int] = [3, 2, 0]
