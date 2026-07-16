shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	if (intensity <= 0.001) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		float y = FRAGCOORD.y;
		float time_seed = floor(TIME * 20.0);

		// Generate pseudo-random horizontal bands that flicker per-frame
		float line_hash = fract(sin(floor(y / 4.0) * 12.9898 + time_seed * 78.233) * 43758.5453);

		// Only show bands when they pass the intensity-driven threshold
		float band = step(1.0 - intensity * 0.35, line_hash);

		// Alternate between cyan and white for a holographic feel
		vec3 glitch_color = mix(vec3(0.0, 0.9, 1.0), vec3(1.0, 1.0, 1.0), step(0.7, line_hash));

		COLOR = vec4(glitch_color, band * intensity * 0.4);
	}
}
