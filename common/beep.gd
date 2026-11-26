class_name Beep
extends RefCounted
## 에셋 없이 코드로 만든 짧은 사인파 소리. 정식 효과음이 생기면 교체한다.


## player로 freq Hz 소리를 length초 낸다(끝으로 갈수록 작아짐)
static func play(player: AudioStreamPlayer, freq: float, length: float = 0.07) -> void:
	var rate: int = 22050
	var n: int = int(rate * length)
	var data: PackedByteArray = PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(sin(TAU * freq * i / rate) * 12000.0 * (1.0 - float(i) / n)))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	player.stream = w
	player.play()
