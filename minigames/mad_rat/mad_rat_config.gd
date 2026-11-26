class_name MadRatConfig
extends Resource
## 미친 쥐 수치. 플레이 테스트로 여기서만 조정한다. 웨이브 배열은 길이를 맞춘다(웨이브 수 = wave_counts 길이)

@export var wave_counts: Array[int] = [5, 6, 7, 8] ## 웨이브마다 주민 수
@export var wave_speed: Array[float] = [3.0, 4.0, 5.0, 6.0] ## 웨이브마다 걷는 속도
@export var wave_gap: Array[float] = [1.5, 1.2, 0.95, 0.75] ## 웨이브마다 다음 주민이 나오는 간격(초)
@export var wave_pause: float = 2.5 ## 새 규칙 표지판이 꽂힌 뒤 첫 주민이 나오기까지(초)
@export var mincho_ratio: float = 0.5 ## 민초 주민 비율
@export var twist_ratio: float = 0.6 ## 웨이브 2부터 변칙(모자·코트·선글라스)이 붙는 주민 비율
@export var perfect_wrong: int = 0 ## 틀린 수가 이 이하면 완전범죄
@export var success_wrong: int = 3 ## 틀린 수가 이 이하면 미션성공, 넘으면 적발
