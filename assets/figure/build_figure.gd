extends SceneTree
## 얼굴 없는 하얀 인형(body)과 입힐 파츠(셔츠, 모자, 정장, 선글라스, 완장)의 모양을 OBJ로 src/에 내보낸다.
## 그다음 src/rig_figure.py(블렌더)가 뼈대·걷기 애니메이션을 붙여 figure.glb를 만든다. 모양을 고치면 둘 다 다시 실행한다.
## 실행: godot --headless --path . -s res://assets/figure/build_figure.gd
## 방식: 부위(구·캡슐)를 거리장(SDF)으로 부드럽게 이어 붙이고 surface nets로 메시화. 원점은 발바닥, +z가 앞.

const H: float = 0.01 # 격자 간격(m). 작을수록 매끈하지만 느림
const LO: Vector3 = Vector3(-0.45, -0.03, -0.38) # 뒤통수(-0.27)·머리띠 매듭(-0.35)까지 담는다
const HI: Vector3 = Vector3(0.45, 1.95, 0.46)
const EDGES: Array = [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]


## 환경 변수 ONLY=coat,badge 처럼 주면 그 파츠만 다시 만든다(전부는 약 4분)
func _init() -> void:
	var parts: Dictionary = {
		"body": _body, "shirt": _shirt, "hat": _hat, "jacket": _jacket, "pants": _pants, "tie": _tie,
		"sunglasses": _sunglasses, "armband": _armband,
		"headband": _headband, "fedora": _fedora, "coat": _coat, "badge": _badge,
	}
	var only: PackedStringArray = OS.get_environment("ONLY").split(",", false)
	for part_name in parts:
		if only.is_empty() or only.has(part_name):
			_build(parts[part_name], "res://assets/figure/src/%s.obj" % part_name)
	quit()


## 머리띠: 이마를 두르는 띠(앞이 살짝 낮다) + 뒤통수 매듭 꼬리 두 가닥
func _headband(p: Vector3) -> float:
	var shell: float = absf(p.distance_to(Vector3(0, 1.42, 0)) - 0.283) - 0.016
	var band: float = _smax(shell, absf(p.y - 1.52 + p.z * 0.15) - 0.04, 0.01)
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var tail: float = _capsule(q, Vector3(0.03, 1.55, -0.29), Vector3(0.09, 1.38, -0.33), 0.022)
	return _smin(band, tail, 0.02)


## 중절모: 윗면이 움푹한 몸체 + 양옆이 살짝 올라간 챙. 앞으로 살짝 눌러쓴다(비밀요원)
func _fedora(world: Vector3) -> float:
	var a: float = 0.14 # 앞이 내려가게 기울임
	var v: Vector3 = world - Vector3(0, 1.6, 0)
	var p: Vector3 = Vector3(0, 1.6, 0) + Vector3(v.x, v.y * cos(a) + v.z * sin(a), -v.y * sin(a) + v.z * cos(a))
	var r: float = Vector2(p.x, p.z * 0.92).length()
	var crown: float = Vector2(maxf(r - 0.22, 0.0), maxf(absf(p.y - 1.72) - 0.11, 0.0)).length() - 0.03
	crown = _smax(crown, -_ellipsoid(p - Vector3(0, 1.88, 0), Vector3(0.05, 0.06, 0.18)), 0.02) # 윗면 주름
	var brim_y: float = 1.6 + p.x * p.x * 0.7
	var brim: float = Vector2(maxf(r - 0.4, 0.0), absf(p.y - brim_y)).length() - 0.022
	return _smin(crown, brim, 0.02)


## 비밀요원 코트: 긴소매, V자 앞섶, 목을 감싸며 위로 선 깃, 무릎까지 오는 자락
func _coat(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var d: float = _smin(_smin(_torso(p), _upper_arm(q), 0.04), _forearm(q), 0.02) - 0.042
	var skirt: float = _capsule(Vector3(p.x, p.y, p.z * 1.05), Vector3(0, 0.78, 0), Vector3(0, 0.36, 0), 0.215) # 곧게 떨어지는 자락
	d = _smin(d, skirt, 0.05)
	d = _smax(d, p.y - 1.15, 0.02) # 목둘레
	d = _smax(d, 0.3 - p.y, 0.02) # 밑단(무릎 위)
	d = _smax(d, minf(0.63 - p.y, q.x - 0.2), 0.02) # 소맷부리
	d = _smax(d, minf(p.z - 0.04, (p.y - 0.85) * 0.6 - q.x), 0.01) # V자 앞섶
	# 세운 깃: 목 둘레를 감싸며 위로 벌어진다(머리보다 넓게). 앞은 트여 있다
	var r: float = Vector2(p.x, p.z * 1.1).length()
	var collar: float = absf(r - (0.17 + (p.y - 1.08) * 0.4)) - 0.022
	collar = _smax(collar, absf(p.y - 1.2) - 0.12, 0.01)
	collar = _smax(collar, minf(p.z - 0.05, 0.09 - q.x), 0.01)
	return _smin(d, collar, 0.015)


## 코트 왼쪽 가슴 배지
func _badge(p: Vector3) -> float:
	return _ellipsoid(p - Vector3(0.12, 1.0, 0.147), Vector3(0.045, 0.045, 0.014))


func _body(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z) # 좌우 대칭
	var d: float = _torso(p)
	d = _smin(d, _capsule(p, Vector3(0, 1.08, 0), Vector3(0, 1.22, 0), 0.07), 0.05) # 목
	d = _smin(d, _sphere(p, Vector3(0, 1.42, 0), 0.27), 0.03) # 머리
	d = _smin(d, _upper_arm(q), 0.04)
	var fore: float = _smin(_forearm(q), _ellipsoid(q - Vector3(0.29, 0.54, 0.04), Vector3(0.055, 0.07, 0.06)), 0.03) # 손
	d = _smin(d, fore, 0.02)
	var leg: float = _smin(_legs(q), _ellipsoid(q - Vector3(0.1, 0.055, 0.05), Vector3(0.075, 0.055, 0.13)), 0.04) # 발
	return _smin(d, leg, 0.03)


## 몸통과 윗팔을 감싸고 허리·목·소매에서 자른 반팔 셔츠
func _shirt(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	# 허리를 따라 조이지 않고 가슴에서 곧게 떨어지게(몸에 칠한 것처럼 보이지 않게) + 두께
	var f: Vector3 = Vector3(p.x, p.y, p.z * 1.3)
	var drape: float = _capsule(f, Vector3(0, 0.7, 0), Vector3(0, 1.0, 0), 0.165)
	var d: float = _smin(_smin(_torso(p), drape, 0.05), _upper_arm(q) - 0.01, 0.04) - 0.03
	# 자른 면을 둥글게(_smax) 해야 가장자리가 톱니처럼 깨지지 않는다
	d = _smax(d, 0.66 - p.y, 0.02) # 밑단
	d = _smax(d, p.y - 1.13, 0.02) # 목둘레
	return _smax(d, minf(0.9 - p.y, q.x - 0.19), 0.02) # 소매 끝: 바깥쪽(x>0.19)이면서 아래(y<0.9)인 곳만 자름


## 야구 모자: 머리를 감싸는 둥근 몸체 + 앞(+z)으로 살짝 숙인 챙
func _hat(p: Vector3) -> float:
	var crown: float = _smax(_sphere(p, Vector3(0, 1.44, 0), 0.29), 1.52 - p.y, 0.02)
	var vy: float = 1.53 - (p.z - 0.26) * 0.2
	var e: float = (Vector2(p.x / 0.2, (p.z - 0.26) / 0.17).length() - 1.0) * 0.17
	var visor: float = Vector2(maxf(e, 0.0), absf(p.y - vy)).length() - 0.02
	visor = _smax(visor, 0.15 - p.z, 0.02) # 앞쪽 반만
	return _smin(crown, visor, 0.02)


## 감시자 재킷: 긴소매, 앞은 V자로 파이고 깃(라펠)이 선다. V 안으로 흰 몸이 셔츠처럼 보인다
func _jacket(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var d: float = _smin(_smin(_torso(p), _upper_arm(q), 0.04), _forearm(q), 0.02) - 0.037
	d = _smax(d, p.y - 1.13, 0.02) # 목둘레
	d = _smax(d, 0.55 - p.y, 0.02) # 밑단: 바지 윗부분을 덮는다
	d = _smax(d, minf(0.63 - p.y, q.x - 0.2), 0.02) # 소맷부리: 손목 위에서 자름
	# V자 앞섶: 앞쪽(z>0.04)이면서 |x| < (y-0.8)*0.55 인 곳을 파낸다
	var v: float = minf(p.z - 0.04, (p.y - 0.8) * 0.55 - q.x)
	d = _smax(d, v, 0.01)
	var lapel: float = _capsule(q, Vector3(0.15, 1.11, 0.11), Vector3(0.012, 0.81, 0.167), 0.022)
	return _smin(d, lapel, 0.01)


## 감시자 바지: 다리 사이가 붙지 않게 다리는 조금만 부풀린다(다리 사이 틈 0.02). 허리는 재킷 안쪽
func _pants(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var straight: float = _capsule(q, Vector3(0.1, 0.68, 0.0), Vector3(0.1, 0.13, 0.0), 0.09) # 바깥쪽은 종아리까지 곧게 떨어지는 통
	var d: float = _smin(minf(_legs(q) - 0.008, straight), _torso(p) - 0.015, 0.03)
	d = _smax(d, p.y - 0.8, 0.02) # 허리
	return _smax(d, 0.15 - p.y, 0.02) # 발목


## 넥타이: 매듭 + 아래로 넓어지는 몸통. 가슴(V 안쪽)에 붙고 끝은 재킷 안으로 들어간다
func _tie(p: Vector3) -> float:
	var knot: float = _ellipsoid(p - Vector3(0, 1.075, 0.14), Vector3(0.034, 0.03, 0.024))
	var blade: float = _ellipsoid(p - Vector3(0, 0.93, 0.14), Vector3(0.05, 0.15, 0.017))
	return _smin(knot, blade, 0.015)


## 선글라스: 얼굴에서 살짝 띄운 렌즈 둘 + 위 테 + 귀까지 가는 다리
func _sunglasses(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var lens: float = _ellipsoid(q - Vector3(0.09, 1.45, 0.287), Vector3(0.083, 0.057, 0.019))
	var brow: float = _capsule(p, Vector3(-0.17, 1.49, 0.285), Vector3(0.17, 1.49, 0.285), 0.017) # 위 테 겸 코다리
	var temple: float = _capsule(q, Vector3(0.17, 1.475, 0.27), Vector3(0.27, 1.475, 0.03), 0.017)
	return _smin(_smin(lens, brow, 0.012), temple, 0.012)


## 완장: 왼팔(+x) 윗팔에 두르는 띠. 셔츠·정장 소매보다 두껍게
func _armband(p: Vector3) -> float:
	var a: Vector3 = Vector3(0.2, 1.05, 0.0)
	var b: Vector3 = Vector3(0.265, 0.8, 0.0)
	var band: float = _capsule(p, a, b, 0.06 + 0.055) # 코트 소매(+0.042) 위로도 보이게
	return _smax(band, absf((p - a.lerp(b, 0.45)).dot((b - a).normalized())) - 0.045, 0.01)


func _torso(p: Vector3) -> float:
	var f: Vector3 = Vector3(p.x, p.y, p.z * 1.3) # 앞뒤로 납작하게
	var chest: float = _capsule(f, Vector3(0, 0.92, 0), Vector3(0, 1.06, 0), 0.165)
	return _smin(chest, _capsule(f, Vector3(0, 0.7, 0), Vector3(0, 0.92, 0), 0.145), 0.08)


func _upper_arm(q: Vector3) -> float:
	return _capsule(q, Vector3(0.2, 1.05, 0.0), Vector3(0.265, 0.8, 0.0), 0.06)


func _forearm(q: Vector3) -> float:
	return _capsule(q, Vector3(0.265, 0.8, 0.0), Vector3(0.285, 0.6, 0.03), 0.052)


## 허벅지 + 정강이 (발 제외)
func _legs(q: Vector3) -> float:
	var thigh: float = _capsule(q, Vector3(0.095, 0.68, 0.0), Vector3(0.095, 0.4, 0.01), 0.085)
	return _smin(thigh, _capsule(q, Vector3(0.095, 0.4, 0.01), Vector3(0.095, 0.1, 0.0), 0.068), 0.04)


func _sphere(p: Vector3, c: Vector3, r: float) -> float:
	return p.distance_to(c) - r


func _capsule(p: Vector3, a: Vector3, b: Vector3, r: float) -> float:
	var pa: Vector3 = p - a
	var ba: Vector3 = b - a
	var h: float = clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * h).length() - r


func _ellipsoid(p: Vector3, r: Vector3) -> float:
	var k0: float = (p / r).length()
	var k1: float = (p / (r * r)).length()
	return k0 * (k0 - 1.0) / k1


func _smin(a: float, b: float, k: float) -> float:
	var h: float = maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


func _smax(a: float, b: float, k: float) -> float:
	return -_smin(-a, -b, k)


func _grad(sdf: Callable, p: Vector3) -> Vector3:
	var e: float = 0.002
	return Vector3(
		sdf.call(p + Vector3(e, 0, 0)) - sdf.call(p - Vector3(e, 0, 0)),
		sdf.call(p + Vector3(0, e, 0)) - sdf.call(p - Vector3(0, e, 0)),
		sdf.call(p + Vector3(0, 0, e)) - sdf.call(p - Vector3(0, 0, e))).normalized()


func _build(sdf: Callable, path: String) -> void:
	var n: Vector3i = Vector3i(((HI - LO) / H).ceil()) + Vector3i.ONE
	var count: int = n.x * n.y * n.z
	var vals: PackedFloat32Array = PackedFloat32Array()
	vals.resize(count)
	for k in n.z:
		for j in n.y:
			for i in n.x:
				vals[i + n.x * (j + n.y * k)] = sdf.call(LO + Vector3(i, j, k) * H)

	# 표면이 지나가는 칸마다 꼭짓점 하나(칸 모서리 교차점의 평균)
	var vid: PackedInt32Array = PackedInt32Array()
	vid.resize(count)
	vid.fill(-1)
	var verts: PackedVector3Array = PackedVector3Array()
	for k in n.z - 1:
		for j in n.y - 1:
			for i in n.x - 1:
				var d: Array[float] = []
				var inside: int = 0
				for c in 8:
					var v: float = vals[(i + (c & 1)) + n.x * ((j + ((c >> 1) & 1)) + n.y * (k + ((c >> 2) & 1)))]
					d.append(v)
					inside += int(v < 0.0)
				if inside == 0 or inside == 8:
					continue
				var sum: Vector3 = Vector3.ZERO
				var hits: int = 0
				for e in EDGES:
					var d0: float = d[e[0]]
					var d1: float = d[e[1]]
					if (d0 < 0.0) == (d1 < 0.0):
						continue
					var c0: Vector3 = Vector3(e[0] & 1, (e[0] >> 1) & 1, (e[0] >> 2) & 1)
					var c1: Vector3 = Vector3(e[1] & 1, (e[1] >> 1) & 1, (e[1] >> 2) & 1)
					sum += c0.lerp(c1, d0 / (d0 - d1))
					hits += 1
				vid[i + n.x * (j + n.y * k)] = verts.size()
				verts.append(LO + (Vector3(i, j, k) + sum / hits) * H)

	var tris: PackedInt32Array = PackedInt32Array()
	# 부호가 바뀌는 격자 모서리마다 그 모서리를 둘러싼 4칸의 꼭짓점으로 사각형
	var axes: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)]
	for k in n.z:
		for j in n.y:
			for i in n.x:
				var p: Vector3i = Vector3i(i, j, k)
				var dp: float = vals[i + n.x * (j + n.y * k)]
				for a in 3:
					var q: Vector3i = p + axes[a]
					if q.x >= n.x or q.y >= n.y or q.z >= n.z:
						continue
					if (dp < 0.0) == (vals[q.x + n.x * (q.y + n.y * q.z)] < 0.0):
						continue
					var u: Vector3i = axes[(a + 1) % 3]
					var w: Vector3i = axes[(a + 2) % 3]
					var cells: Array[Vector3i] = [p - u - w, p - u, p, p - w]
					var ids: Array[int] = []
					for c in cells:
						if c.x < 0 or c.y < 0 or c.z < 0:
							break
						var id: int = vid[c.x + n.x * (c.y + n.y * c.z)]
						if id < 0:
							break
						ids.append(id)
					if ids.size() < 4:
						continue
					_tri(tris, sdf, verts, ids[0], ids[1], ids[2])
					_tri(tris, sdf, verts, ids[0], ids[2], ids[3])
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		printerr("%s: open failed %s" % [path, error_string(FileAccess.get_open_error())])
		return
	for v in verts:
		f.store_line("v %f %f %f" % [v.x, v.y, v.z])
	for t in range(0, tris.size(), 3):
		f.store_line("f %d %d %d" % [tris[t] + 1, tris[t + 1] + 1, tris[t + 2] + 1])
	print("%s: %d verts, %d tris" % [path, verts.size(), tris.size() / 3])


## OBJ는 바깥에서 볼 때 반시계 방향이 앞면이라, 바깥 방향(SDF 기울기)과 맞춰 순서를 정한다
func _tri(tris: PackedInt32Array, sdf: Callable, verts: PackedVector3Array, a: int, b: int, c: int) -> void:
	var out: Vector3 = _grad(sdf, (verts[a] + verts[b] + verts[c]) / 3.0)
	if (verts[b] - verts[a]).cross(verts[c] - verts[a]).dot(out) < 0.0:
		var t: int = b
		b = c
		c = t
	tris.append_array([a, b, c])
