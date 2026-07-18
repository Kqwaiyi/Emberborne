shader_type canvas_item;

uniform float scanline_count : hint_range(0, 1800) = 150.0;
uniform float velocity : hint_range(-5.0, 5.0) = 1.0;
uniform vec4 color : source_color = vec4(0.2, 0.7, 0.9, 0.15);

void fragment() {
	vec2 uv = UV;
	
	// Create moving scanlines
	float s = sin(uv.y * scanline_count * 3.14159 - TIME * velocity * 10.0);
	s = (s * 0.5) + 0.5;
	
	COLOR = color;
	COLOR.a *= s;
}
