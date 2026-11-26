class_name PianoConfig
extends Resource
## 피아노표 수치. 플레이 테스트로 여기서만 조정한다. 박 = 4분음표, 마디 = 4박.
## 날 따라해봐요: 짝수 마디(0, 2, …)는 보여 주기(뒤 레일), 홀수 마디는 따라 하기(앞 레일에서 찍기). 마디 번호 설정은 홀수로 둔다.

@export var bpm: float = 100.0
@export var count_in: int = 4 ## 첫 보여 주기 마디 전 박자 수
@export var measures: int = 16 ## 마디 수(보여 주기 + 따라 하기). 따라 하기 마디는 절반
@export var mix_from: int = 5 ## 이 마디부터 민초 표가 섞임
@export var anti_ratio: float = 0.6 ## 섞인 구간에서 반민초 표 비율
@export var vary_from: int = 3 ## 이 마디부터 8분·엇박 패턴이 나옴
@export var fast_from: int = 9 ## 이 마디부터 16분 패턴도 나옴
@export var watch_from: int = 9 ## 이 마디부터 감시자가 나옴
@export var watch_every: int = 2 ## 감시자 간격(마디). 따라 하기 마디마다 한 명
@export var window: float = 0.17 ## 박자 판정 허용 오차(초, ±). 표 간격이 좁으면 간격의 절반으로 줄어든다
@export var perfect_mistakes: int = 1 ## 실수가 이 이하면 완전범죄
@export var success_mistakes: int = 5 ## 실수가 이 이하면 미션성공, 넘으면 적발
## 한 마디 안에서 표가 오는 박(0 ~ 4 미만)
@export var patterns_basic: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 2.0, 3.0]), # 정박
]
@export var patterns_vary: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 2.0, 2.5, 3.0]), # 8분 하나
	PackedFloat32Array([0.0, 0.5, 1.0, 2.0, 3.0]),
	PackedFloat32Array([0.0, 1.5, 2.0, 3.0]), # 당김음
	PackedFloat32Array([0.5, 1.5, 2.5, 3.5]), # 전부 엇박
	PackedFloat32Array([0.0, 1.0, 1.5, 2.5, 3.0]),
]
@export var patterns_fast: Array[PackedFloat32Array] = [
	PackedFloat32Array([0.0, 1.0, 1.25, 1.5, 2.0, 3.0]), # 16분 셋
	PackedFloat32Array([0.0, 0.75, 1.5, 2.0, 3.0]), # 점8분
	PackedFloat32Array([0.0, 1.0, 2.0, 2.25, 3.0]),
]
