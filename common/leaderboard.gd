class_name Leaderboard
extends RefCounted
## 리더보드 저장·순위. 종합점수 순, 동점이면 최종 득표 높은 쪽, 그다음은 먼저 등록한 쪽.
## 항목 = { id, name, score, percent, title, ranks(플레이한 순서대로 Grade.Rank), time }

const PATH: String = "user://leaderboard.json"
const GLYPHS: Array[String] = ["★", "○", "✕"] # 인덱스 = Grade.Rank (완전범죄, 미션성공, 적발)

## 방금 등록한 항목 id (리더보드 화면에서 강조). 화면을 떠나면 -1로 되돌린다
static var highlight_id: int = -1


static func load_all(path: String = PATH) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return out
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Array:
		# 깨진 파일은 덮어쓰기 전에 보존한다
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path) + ".bak")
		push_warning("리더보드 파일이 깨져 .bak으로 옮김: " + path)
		return out
	for e in parsed:
		if e is Dictionary:
			out.append(e)
	return out


static func save(entries: Array[Dictionary], path: String = PATH) -> bool:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(entries))
	return true


## 새 항목을 entries에 붙이고 돌려준다. 이름(타이틀 서명란)이 비면 id로 '민초단원 N호'를 붙인다
static func add(entries: Array[Dictionary], score: int, percent: float, title: String, ranks: Array, now: int, player_name: String = "") -> Dictionary:
	var next_id: int = 1
	for e in entries:
		next_id = maxi(next_id, int(e["id"]) + 1)
	var shown: String = player_name.strip_edges()
	if shown.is_empty():
		shown = "민초단원 %d호" % next_id
	var entry: Dictionary = {"id": next_id, "name": shown, "score": score, "percent": percent, "title": title, "ranks": ranks, "time": now}
	entries.append(entry)
	return entry


static func sorted_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = entries.duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["score"]) != int(b["score"]):
			return int(a["score"]) > int(b["score"])
		if not is_equal_approx(float(a["percent"]), float(b["percent"])):
			return float(a["percent"]) > float(b["percent"])
		return int(a["id"]) < int(b["id"]))
	return out


## 정렬된 목록에서 id의 순위(1부터). 없으면 0
static func rank_of(sorted: Array[Dictionary], id: int) -> int:
	for i in sorted.size():
		if int(sorted[i]["id"]) == id:
			return i + 1
	return 0


## 미니게임별 등급 기호 (예: ★★○✕)
static func glyphs(ranks: Array) -> String:
	var s: String = ""
	for r in ranks:
		s += GLYPHS[int(r)]
	return s
