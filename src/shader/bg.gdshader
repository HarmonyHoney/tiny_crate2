shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.2;
uniform vec2 size = vec2(1, 1);

uniform vec4 color_a : hint_color = vec4(1);
uniform vec4 color_b : hint_color = vec4(vec3(0.5), 1.0);
uniform bool is_color_c = false;
uniform vec4 color_c : hint_color = vec4(0.0);

uniform float time_scale : hint_range(0.0, 0.2) = 0.1;
uniform vec2 move = vec2(1.0);

void fragment(){
	vec2 m = (UV + (move * TIME * time_scale)) * size;
	vec2 uv = mod(m, 1);
	
	vec4 c = color_a;
	vec2 s = sign(uv - vec2(0.5));
	
	// checker
	if (int(ceil(m.x) + ceil(m.y)) % 2 > 0){
		c = color_b;
	}
	
	bool is_corner = distance(uv, round(uv)) < radius;
	bool is_circle = distance(uv, round(uv) - (vec2(radius) * s)) < radius;
	
	if (is_corner && !is_circle){
		c = is_color_c ? color_c : color_b;
	}
	
	COLOR = c;
}