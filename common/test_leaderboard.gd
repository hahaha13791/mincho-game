extends SceneTree
## 실행: godot --headless --path . -s res://common/test_leaderboard.gd

var _fails: int = 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: " + msg)


func _init() -> void:
	var path: String = "user://test_leaderboard.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_check(Leaderboard.load_all(path).is_empty(), "파일이 없으면 빈 목록")

	var entries: Array[Dictionary] = []
	var a: Dictionary = Leaderboard.add(entries, 10, 50.0, "가", [0, 1], 100)
	var b: Dictionary = Leaderboard.add(entries, 21, 79.0, "나", [0, 0], 200)
	var c: Dictionary = Leaderboard.add(entries, 10, 60.0, "다", [1, 1], 300)
	var d: Dictionary = Leaderboard.add(entries, 10, 60.0, "라", [1, 1], 400)
	_check(a["id"] == 1 and d["id"] == 4 and a["name"] == "민초단원 1호", "id와 이름은 순서대로 자동 부여")
	var s: Array[Dictionary] = Leaderboard.sorted_entries(entries)
	_check(s[0]["id"] == 2, "점수가 높은 쪽이 1위")
	_check(s[1]["id"] == 3 and s[2]["id"] == 4, "동점이면 득표가 높은 쪽, 그것도 같으면 먼저 등록한 쪽")
	_check(s[3]["id"] == 1, "득표가 낮은 동점자는 뒤")
	_check(Leaderboard.rank_of(s, 4) == 3 and Leaderboard.rank_of(s, 99) == 0, "순위 조회")

	_check(Leaderboard.save(entries, path), "저장 성공")
	var loaded: Array[Dictionary] = Leaderboard.load_all(path)
	_check(loaded.size() == 4 and int(loaded[1]["score"]) == 21, "저장 후 다시 읽으면 같다")
	var e5: Dictionary = Leaderboard.add(loaded, 5, 40.0, "마", [2], 500)
	_check(e5["id"] == 5, "읽은 뒤에도 id가 이어진다")
	_check(Leaderboard.glyphs([0, 1, 2]) == "★○✕", "등급 기호")
	var named: Dictionary = Leaderboard.add(loaded, 5, 40.0, "바", [2], 600, "  민트맨 ")
	_check(named["name"] == "민트맨", "서명란 이름은 앞뒤 공백을 떼고 쓴다")
	var blank: Dictionary = Leaderboard.add(loaded, 5, 40.0, "사", [2], 700, "   ")
	_check(blank["name"] == "민초단원 %d호" % blank["id"], "빈 이름은 자동 이름")

	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{깨진 파일")
	f.close()
	_check(Leaderboard.load_all(path).is_empty() and FileAccess.file_exists(path + ".bak"), "깨진 파일은 빈 목록, 원본은 .bak으로 보존")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))

	print("TEST OK" if _fails == 0 else "TEST FAILED: %d" % _fails)
	quit(_fails)
