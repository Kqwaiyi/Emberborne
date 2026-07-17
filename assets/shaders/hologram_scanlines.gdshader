shader_type canvas_item;

uniform float line_spacing : hint_range(1.0, 10.0) = 3.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.06;
uniform float scroll_speed : hint_range(0.0, 50.0) = 15.0;

void fragment() {
	float y = FRAGCOORD.y + TIME * scroll_speed;
	float line = step(fract(y / line_spacing), 0.5);
	COLOR = vec4(0.0, 0.0, 0.0, line * line_alpha);
}
