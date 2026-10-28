shader_type canvas_item;
// Final screen pass. The game is drawn in grey (plus pure red for the accent);
// here each grey is mapped onto a 10-step town palette. Blending between two
// palettes is how a new town's colours fade in. Then glow, scanlines, vignette.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 from_ramp[10];
uniform vec3 to_ramp[10];
uniform vec3 from_accent = vec3(1.0, 0.36, 0.56);
uniform vec3 to_accent = vec3(1.0, 0.36, 0.56);
uniform float blend = 1.0;
uniform float desaturate = 0.0;
uniform float glow_strength = 1.0;
uniform float scanline_strength = 0.08;
uniform float vignette_strength = 0.9;

vec3 ramp(float g) {
	float f = clamp(g, 0.0, 1.0) * 9.0;
	int i = min(int(floor(f)), 9);
	int j = min(i + 1, 9);
	float w = f - float(i);
	vec3 a = mix(from_ramp[i], to_ramp[i], blend);
	vec3 b = mix(from_ramp[j], to_ramp[j], blend);
	return mix(a, b, w);
}

vec3 colorize(vec3 src) {
	float acc = clamp(src.r - src.b, 0.0, 1.0);
	float g = src.b / max(1.0 - acc, 0.001);
	return mix(ramp(g), mix(from_accent, to_accent, blend), acc);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	vec3 src = texture(screen_tex, uv).rgb;
	vec3 col = colorize(src);

	// Glow only from bright source pixels; cheap 3x3 tap.
	vec3 glow = vec3(0.0);
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec3 s = texture(screen_tex, uv + vec2(float(x), float(y)) * px * 1.5).rgb;
			float bright = max(max(s.r, s.b) - 0.7, 0.0);
			glow += colorize(s) * bright;
		}
	}
	col += glow * 0.22 * glow_strength;

	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(lum), desaturate);

	float odd = step(1.0, mod(FRAGCOORD.y, 2.0));
	col *= 1.0 - scanline_strength * odd;

	vec2 d = uv - 0.5;
	col *= 1.0 - vignette_strength * dot(d, d);

	COLOR = vec4(col, 1.0);
}
