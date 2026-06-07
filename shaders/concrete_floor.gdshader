shader_type canvas_item;

// Procedural industrial concrete floor with tile grout lines, mottling,
// stains, and a yellow-black hazard stripe band on the server-room side.

uniform vec2 room_size = vec2(1280.0, 720.0);
uniform float tile_size = 64.0;
uniform vec3 base_color : source_color = vec3(0.17, 0.18, 0.21);
uniform vec3 grout_color : source_color = vec3(0.09, 0.10, 0.12);
uniform float hazard_x = 880.0;
uniform float hazard_width = 26.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 pixel = UV * room_size;

	// Base concrete with broad mottling
	vec3 col = base_color;
	float mottle = fbm(pixel * 0.018);
	col += (mottle - 0.5) * 0.10;

	// Fine grain
	float grain = hash(pixel) * 0.05;
	col += grain - 0.025;

	// Large dirt stains
	float stain = fbm(pixel * 0.004 + vec2(11.3, 7.1));
	col *= 0.82 + stain * 0.34;

	// Tile grout grid
	vec2 tile_uv = fract(pixel / tile_size);
	float lw = 0.03;
	float grout = 0.0;
	grout = max(grout, 1.0 - smoothstep(0.0, lw, tile_uv.x));
	grout = max(grout, smoothstep(1.0 - lw, 1.0, tile_uv.x));
	grout = max(grout, 1.0 - smoothstep(0.0, lw, tile_uv.y));
	grout = max(grout, smoothstep(1.0 - lw, 1.0, tile_uv.y));
	col = mix(col, grout_color, grout * 0.7);

	// Slight per-tile shade variance so the grid does not look uniform
	vec2 tile_id = floor(pixel / tile_size);
	float tile_shade = (hash(tile_id) - 0.5) * 0.05;
	col += tile_shade;

	// Yellow-black hazard stripe band at the server-room threshold
	float dx = abs(pixel.x - hazard_x);
	if (dx < hazard_width) {
		float diag = fract((pixel.x + pixel.y) / 24.0);
		vec3 hazard = diag < 0.5 ? vec3(0.85, 0.66, 0.12) : vec3(0.08, 0.08, 0.09);
		float edge = smoothstep(hazard_width, hazard_width - 4.0, dx);
		col = mix(col, hazard, edge * 0.9);
	}

	COLOR = vec4(col, 1.0);
}
