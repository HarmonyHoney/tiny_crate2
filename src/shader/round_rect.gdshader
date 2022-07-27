shader_type canvas_item;

uniform float radius : hint_range(0.0, 0.5) = 0.2;

void fragment(){
	vec4 c = texture(TEXTURE, UV);
	vec2 s = sign(UV - vec2(0.5));
	
	bool is_corner = distance(UV, round(UV)) < radius;
	bool is_circle = distance(UV, round(UV) - (vec2(radius) * s)) < radius;
	
	if (is_corner && !is_circle){
		c.a = 0.0;
	}
	
	COLOR = c;
}