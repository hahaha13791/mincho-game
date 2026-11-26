extends SceneTree
## 얼굴 없는 하얀 인형(body), 반팔 셔츠(shirt), 야구 모자(hat)의 모양을 OBJ로 src/에 내보낸다.
## 그다음 src/rig_figure.py(블렌더)가 뼈대·걷기 애니메이션을 붙여 figure.glb를 만든다. 모양을 고치면 둘 다 다시 실행한다.
## 실행: godot --headless --path . -s res://assets/figure/build_figure.gd
## 방식: 부위(구·캡슐)를 거리장(SDF)으로 부드럽게 이어 붙이고 surface nets로 메시화. 원점은 발바닥, +z가 앞.

const H: float = 0.01 # 격자 간격(m). 작을수록 매끈하지만 느림
const LO: Vector3 = Vector3(-0.45, -0.03, -0.25)
const HI: Vector3 = Vector3(0.45, 1.85, 0.46)
const EDGES: Array = [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]


func _init() -> void:
	_build(_body, "res://assets/figure/src/body.obj")
	_build(_shirt, "res://assets/figure/src/shirt.obj")
	_build(_hat, "res://assets/figure/src/hat.obj")
	quit()


func _body(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z) # 좌우 대칭
	var d: float = _torso(p)
	d = _smin(d, _capsule(p, Vector3(0, 1.08, 0), Vector3(0, 1.22, 0), 0.07), 0.05) # 목
	d = _smin(d, _sphere(p, Vector3(0, 1.42, 0), 0.27), 0.03) # 머리
	d = _smin(d, _upper_arm(q), 0.04)
	var fore: float = _capsule(q, Vector3(0.265, 0.8, 0.0), Vector3(0.285, 0.6, 0.03), 0.052)
	fore = _smin(fore, _ellipsoid(q - Vector3(0.29, 0.54, 0.04), Vector3(0.055, 0.07, 0.06)), 0.03) # 손
	d = _smin(d, fore, 0.02)
	var leg: float = _capsule(q, Vector3(0.095, 0.68, 0.0), Vector3(0.095, 0.4, 0.01), 0.085)
	leg = _smin(leg, _capsule(q, Vector3(0.095, 0.4, 0.01), Vector3(0.095, 0.1, 0.0), 0.068), 0.04)
	leg = _smin(leg, _ellipsoid(q - Vector3(0.1, 0.055, 0.05), Vector3(0.075, 0.055, 0.13)), 0.04) # 발
	return _smin(d, leg, 0.03)


## 몸통과 윗팔을 감싸고 허리·목·소매에서 자른 반팔 셔츠
func _shirt(p: Vector3) -> float:
	var q: Vector3 = Vector3(absf(p.x), p.y, p.z)
	var d: float = _smin(_torso(p), _upper_arm(q), 0.04) - 0.018
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


func _torso(p: Vector3) -> float:
	var f: Vector3 = Vector3(p.x, p.y, p.z * 1.3) # 앞뒤로 납작하게
	var chest: float = _capsule(f, Vector3(0, 0.92, 0), Vector3(0, 1.06, 0), 0.165)
	return _smin(chest, _capsule(f, Vector3(0, 0.7, 0), Vector3(0, 0.92, 0), 0.145), 0.08)


func _upper_arm(q: Vector3) -> float:
	return _capsule(q, Vector3(0.2, 1.05, 0.0), Vector3(0.265, 0.8, 0.0), 0.06)


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
