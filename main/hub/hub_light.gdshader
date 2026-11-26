shader_type canvas_item;
// 작전본부실 조명 덮개: 화면 전체를 어둡게 깔고 빛이 닿는 곳만 남긴다(실제 조명이 아닌 그림).
// 빛 둘: 위에서 퍼지는 천장 조명(타원), 책상 스탠드(갓 둘레 + 책상 위 웅덩이, 가끔 깜빡임).
// 좌표는 모두 화면 픽셀(1920x1080). 색은 hub.gd가 팔레트에서 넣는다.

uniform vec4 dark : source_color;
uniform vec4 warm : source_color;
uniform vec2 screen_size = vec2(1920.0, 1080.0);
uniform float max_dark = 0.75; // 빛이 하나도 없는 곳을 덮는 정도
uniform float warm_alpha = 0.14; // 빛 안쪽에 얹는 따뜻한 색 세기
uniform vec2 ceiling = vec2(960.0, -260.0); // 천장 조명 중심
uniform vec2 ceiling_radius = vec2(950.0, 1300.0);
uniform vec2 lamp_shade; // 스탠드 갓
uniform vec2 lamp_pool; // 갓이 비추는 책상 위
uniform float lamp_radius = 90.0;
uniform float lamp_warm = 0.16; // 스탠드 빛에만 더 얹는 따뜻한 색
uniform vec2 pool_radius = vec2(210.0, 60.0);

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// 스탠드 밝기: 잔잔히 떨리다가 가끔(1/8초 칸 중 약 6%) 뚝 떨어진다
float flicker(float t) {
	float hum = 0.95 + 0.05 * sin(t * 23.0) * sin(t * 7.3);
	float dip = step(0.94, hash(floor(t * 8.0))) * 0.45;
	return hum - dip;
}

float spot(vec2 p, vec2 c, vec2 r, float inner) {
	return 1.0 - smoothstep(inner, 1.0, length((p - c) / r));
}

void fragment() {
	vec2 p = UV * screen_size;
	float light = spot(p, ceiling, ceiling_radius, 0.15);
	float lamp = max(spot(p, lamp_shade, vec2(lamp_radius), 0.0), spot(p, lamp_pool, pool_radius, 0.3)) * flicker(TIME);
	light = max(light, lamp);
	light = clamp(light, 0.0, 1.0);
	COLOR = vec4(mix(dark.rgb, warm.rgb, light), mix(max_dark, warm_alpha + lamp * lamp_warm, light));
}
