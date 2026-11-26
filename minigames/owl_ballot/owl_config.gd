class_name OwlConfig
extends Resource
## 올빼미표 수치. 플레이 테스트로 여기서만 조정한다.

@export var cycles: int = 6 ## 불이 꺼지는 횟수. 이 안에 투표함을 다 처리해야 함
@export var first_light: float = 4.0 ## 처음 외우는 시간(초)
@export var light_time: float = 2.5 ## 이후 불이 켜져 있는 시간
@export var dark_time: float = 3.5 ## 불이 꺼져 있는(이동 가능한) 시간
@export var flicker: float = 0.8 ## 전환 직전 깜빡임 예고 시간
@export var watch_hold: float = 1.2 ## 불이 켜진 뒤 시야를 보여 주는 시간. 그 뒤 감시자가 다음 자리로 걸어간다
@export var step_time: float = 0.35 ## 한 칸 이동에 걸리는 시간
