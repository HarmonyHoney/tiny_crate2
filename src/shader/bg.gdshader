shader_type canvas_item;

uniform bool flip = false;
uniform vec4 c0 : hint_color = vec4(1.0);
uniform vec4 c1 : hint_color = vec4(0, 0, 0, 1.0);

void fragment(){
	COLOR = mix(c0, c1, smoothstep(0.0, 1.0, flip ? (1.0 - UV.y) : UV.y));
}