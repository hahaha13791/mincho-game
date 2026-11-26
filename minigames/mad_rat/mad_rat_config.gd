class_name MadRatConfig
extends Resource
## 미친 쥐 수치. 플레이 테스트로 여기서만 조정한다. 웨이브 배열은 길이를 맞춘다(웨이브 수 = wave_counts 길이)

## 웨이브 1~4는 규칙 표지판이 하나씩 꽂히고, 5부터는 새 규칙 없이 4개 규칙을 다 섞어 익숙해지게 한다
## 웨이브 5는 웨이브 4와 같은 속도로 익히고, 6~7은 빨라지고 사람도 늘어난다
@export var wave_counts: Array[int] = [5, 6, 7, 8, 6, 8, 9] ## 웨이브마다 주민 수
@export var wave_speed: Array[float] = [2.6, 3.3, 4.0, 4.6, 4.6, 5.4, 6.0] ## 웨이브마다 걷는 속도
@export var wave_gap: Array[float] = [1.6, 1.35, 1.1, 0.95, 0.95, 0.8, 0.7] ## 웨이브마다 다음 주민이 나오는 간격(초)
@export var wave_pause: float = 2.5 ## 새 규칙 표지판이 꽂힌 뒤 첫 주민이 나오기까지(초)
@export var mincho_ratio: float = 0.5 ## 민초 주민 비율
@export var twist_ratio: float = 0.6 ## 웨이브 2부터 변칙(모자·코트·선글라스)이 붙는 주민 비율
@export var perfect_wrong: int = 0 ## 틀린 수가 이 이하면 완전범죄
@export var success_wrong: int = 8 ## 틀린 수가 이 이하면 미션성공, 넘으면 적발 (주민 49명 기준)
