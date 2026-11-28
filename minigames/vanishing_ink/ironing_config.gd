class_name IroningConfig
extends Resource
## 사라지는 잉크 수치. 플레이 테스트로 여기서만 조정한다.

@export var rounds: int = 10
@export var need_success: int = 7 ## 지운 장(옅게 남은 장 포함)이 이 이상이면 미션성공 이상
@export var need_perfect: int = 9 ## 깨끗이 지운 장이 이 이상이고 모두 여유 있게 지웠으면 완전범죄(10장 전부는 너무 빡빡해서 한 장 실수는 봐준다)
## 종이 속도 단계: 김이 나는(기표가 지워지는) 시점(초). 단계 차이를 크게 둬 누레지는 속도로 구분되게 한다. 라운드마다 섞어 겹치지 않게 낸다
@export var steam_tiers: PackedFloat32Array = PackedFloat32Array([0.5, 0.9, 1.5])
@export var burn_ratio: float = 1.6 ## 타는 시점 = 김 나는 시점 × 이 값. 빨리 지워지는 종이는 누레지는 것도 빠르다
@export var faint_from: float = 0.6 ## 김 나기 전에 떼도 김 시점의 이 비율 이상 댔으면 기표가 옅게 남는다(미션성공까지만)
@export var safe_margin: float = 0.35 ## 김 남 → 탐 사이 시간 중 이 비율 이상 남기고 떼야 '여유'. 전부 여유 있게 지우면 완전범죄


## steam_tiers 복사본. const CONFIG에서 CONFIG.steam_tiers.duplicate()를 바로 쓰면 분석기가 가져오기 중
## 아직 빈 리소스로 미리 계산하다 파싱 에러를 낸다(메서드 호출은 미리 계산하지 않는다)
func tiers_copy() -> PackedFloat32Array:
	return steam_tiers.duplicate()
