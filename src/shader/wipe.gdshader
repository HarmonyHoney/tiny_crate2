shader_type canvas_item;

uniform float dist : hint_range(0.0, 2.0) = 0.5;

void fragment(){
	COLOR = vec4(mix(0, 1, float(distance(vec2(0.5), UV) > dist)));
}