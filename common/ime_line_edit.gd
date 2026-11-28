class_name ImeLineEdit
extends LineEdit
## 한글 입력이 되는 LineEdit. Godot 4.7.2(Windows)는 다음 자모를 쳐서 확정된 음절을 LineEdit에 넣지 않는다
## (조합 글자만 바뀌어 앞 글자를 덮어쓴 것처럼 보임. Space·Enter로 확정할 때는 정상).
## 조합이 비었다가(확정) 새 조합이 시작됐는데 글자가 안 들어왔으면 직전 조합 음절을 대신 넣는다.
## shortcut: 완성 음절만 살린다(홀자모 확정은 백스페이스로 지운 것과 구분이 안 됨). 엔진에서 고쳐지면 지운다

const DOUBLE_FINAL_FIRST: Dictionary = {3: 1, 5: 4, 6: 4, 9: 8, 10: 8, 11: 8, 12: 8, 13: 8, 14: 8, 15: 8, 18: 17} # 겹받침 → 앞 받침(유니코드 종성 번호)

var _last: String = "" # 직전 조합 글자
var _pending: String = "" # 확정됐는데 아직 안 들어왔을 수 있는 음절
var _text_at_pending: String = ""


func _notification(what: int) -> void:
	if what != NOTIFICATION_OS_IME_UPDATE or not has_focus():
		return
	var ime: String = DisplayServer.ime_get_text()
	if ime.is_empty():
		if is_syllable(_last):
			_pending = _last
			_text_at_pending = text
	elif not _pending.is_empty():
		if text == _text_at_pending: # Space·Enter 확정처럼 엔진이 넣었으면 text가 이미 바뀌어 있다
			# 새 조합이 바로 음절이면 받침이 넘어간 것(핫 + ㅔ → 하 + 세)
			insert_text_at_caret(drop_final(_pending) if is_syllable(ime) else _pending)
		_pending = ""
	_last = ime


# 받침을 뗀다. 겹받침은 뒤 자음만 넘어가므로 앞 자음을 남긴다(닭 → 달)
static func drop_final(s: String) -> String:
	var code: int = s.unicode_at(0) - 0xAC00
	var final_index: int = code % 28
	var keep: int = DOUBLE_FINAL_FIRST.get(final_index, 0)
	return String.chr(0xAC00 + code - final_index + keep)


static func is_syllable(s: String) -> bool:
	return s.length() == 1 and s.unicode_at(0) >= 0xAC00 and s.unicode_at(0) <= 0xD7A3
