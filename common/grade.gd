class_name Grade
extends RefCounted

# 순서가 VoteConfig 배열의 인덱스와 같다
enum Rank { PERFECT, SUCCESS, CAUGHT }

# 표시 이름. 인덱스 = Rank
const NAMES: Array[String] = ["완전범죄", "미션성공", "적발"]
