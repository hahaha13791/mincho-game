class_name PianoConfig
extends Resource
## 피아노표 수치. 플레이 테스트로 여기서만 조정한다.

@export var bpm: float = 100.0
@export var count_in: int = 4 ## 첫 표가 오기 전 박자 수
@export var beats: int = 48 ## 표 장수 = 박자 수
@export var mix_from: int = 12 ## 이 박자부터 민초 표가 섞임
@export var anti_ratio: float = 0.6 ## 섞인 구간에서 반민초 표 비율
@export var watch_from: int = 28 ## 이 박자부터 감시자가 나옴
@export var watch_gap: int = 6 ## 감시자 간격(박자)
@export var window: float = 0.17 ## 박자 판정 허용 오차(초, ±)
@export var perfect_mistakes: int = 1 ## 실수가 이 이하면 완전범죄
@export var success_mistakes: int = 5 ## 실수가 이 이하면 미션성공, 넘으면 적발
