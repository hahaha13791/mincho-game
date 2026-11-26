shader_type canvas_item;
// 작전본부실 조명 덮개: 화면 전체를 어둡게 깔고 빛이 닿는 곳만 남긴다(실제 조명이 아닌 그림).
// 빛 둘: 위에서 퍼지는 천장 조명(타원), 책상 스탠드(갓 입구에서 넓어지는 빛줄기 + 책상 위 웅덩이, 가끔 깜빡임).
// 좌표는 모두 화면 픽셀(1920x1080). 색은 hub.gd가 팔레트에서 넣는다.

uniform vec4 dark : source_color;
uniform vec4 warm : source_color;
uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform float max_dark = 0.75; // 빛이 하나도 없는 곳을 덮는 정도
uniform float warm_alpha = 0.14; // 빛 안쪽에 얹는 따뜻한 색 세기
uniform vec2 ceiling = vec2(960.0, -260.0); // 천장 조명 중심
uniform vec2 ceiling_radius = vec2(950.0, 1300.0);
uniform vec2 lamp_shade; // 스탠드 갓 입구
uniform vec2 lamp_pool; // 갓이 비추는 책상 위
uniform float mouth_half = 45.0; // 빛줄기가 시작하는 갓 입구 반폭
uniform float beam_strength = 0.4; // 공기 중 빛줄기는 웅덩이보다 옅게
uniform float lamp_warm = 0.16; // 스탠드 빛에만 더 얹는 따뜻한 색
uniform vec2 pool_radius = vec2(210.0, 32.0); // 책상 윗면이 화면에서 얇아 납작하게(넘치면 책상 밑까지 밝아짐)

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// 스탠드 밝기: 잔잔히 떨리다가 가끔(1/8초 칸 중 약 6%) 뚝 떨어진다
float flicker(float t) {
	float hum = 0.95 + 0.05 * sin(t * 23.0) * sin(t * 7.3);
	float dip = step(0.94, hash(floor(t * 8.0))) * 0.45;
	return hum - dip;
}

// 갓 입구(a)에서 웅덩이(b)까지 넓어지는 빛줄기. 입구 뒤(갓 안쪽)는 비추지 않는다
float beam(vec2 p, vec2 a, vec2 b, float w0, float w1) {
	vec2 ab = b - a;
	float len = length(ab);
	vec2 dir = ab / len;
	vec2 v = p - a;
	float t = dot(v, dir) / len;
	float d = abs(v.x * dir.y - v.y * dir.x);
	float w = mix(w0, w1, clamp(t, 0.0, 1.0));
	float along = smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.85, 1.0, t)); // 웅덩이에서 끝(책상을 뚫고 내려가지 않게)
	return (1.0 - smoothstep(0.4, 1.0, d / w)) * along * mix(1.0, 0.6, t);
}

float spot(vec2 p, vec2 c, vec2 r, float inner) {
	return 1.0 - smoothstep(inner, 1.0, length((p - c) / r));
}

void fragment() {
	vec2 p = UV * screen_size;
	float light = spot(p, ceiling, ceiling_radius, 0.15);
	float ray = beam(p, lamp_shade, lamp_pool, mouth_half, pool_radius.x * 0.8) * beam_strength;
	ray *= 1.0 - smoothstep(lamp_pool.y - 10.0, lamp_pool.y + 10.0, p.y); // 빛줄기가 비스듬해 아래 가장자리가 책상 밑으로 새지 않게
	float lamp = max(ray, spot(p, lamp_pool, pool_radius, 0.3)) * flicker(TIME);
	light = max(light, lamp);
	light = clamp(light, 0.0, 1.0);
	COLOR = vec4(mix(dark.rgb, warm.rgb, light), mix(max_dark, warm_alpha + lamp * lamp_warm, light));
}
