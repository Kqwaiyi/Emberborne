shader_type canvas_item;

uniform vec4 border_color : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float border_width = 1.0;
uniform vec2 rect_size = vec2(160.0, 140.0);
uniform float corner_radius = 2.0;
uniform float speed = 1.0;
uniform float tail_length = 0.5;
uniform float hover_intensity : hint_range(0.0, 1.0) = 0.0;

float sd_round_box(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
    vec2 half_size = rect_size / 2.0;
    // p is the coordinate relative to the center
    vec2 p = (UV * rect_size) - half_size;
    
    // Distance field for the outer boundary
    float d = sd_round_box(p, half_size, corner_radius);
    
    // We want the border to go inward from the boundary
    // d is 0 at the boundary, and negative inside.
    // The stroke is from d = -border_width to d = 0.
    float inner_d = d + border_width / 2.0;
    float dist_from_center_of_stroke = abs(inner_d);
    
    // 1.0 when exactly on the center of the stroke, falls off to 0 outside
    float border_mask = 1.0 - smoothstep(border_width / 2.0 - 0.5, border_width / 2.0 + 0.5, dist_from_center_of_stroke);
    
    if (border_mask <= 0.01) {
        COLOR = vec4(0.0);
    } else {
        float angle = atan(p.y, p.x); 
        float t = (angle / 6.283185307) + 0.5; 
        
        float head = fract(TIME * speed);
        float dist = head - t;
        if (dist < 0.0) dist += 1.0;
        
        float snake = 0.0;
        if (dist < tail_length) {
            snake = 1.0 - (dist / tail_length);
        }
        
        // Base alpha is 0.3. During hover, it brightens up to 1.0 using the snake gradient
        float final_alpha = 0.3 + (snake * 0.7 * hover_intensity);
        COLOR = vec4(border_color.rgb, border_color.a * final_alpha * border_mask);
    }
}
