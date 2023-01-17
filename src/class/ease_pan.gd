extends Control

onready var start_pos := rect_position

export var hide_offset := Vector2(0, -200)
export var is_hide := false

var hide_last := 0.0
var hide_clock := 0.0
export var hide_time := 0.5
export var is_smoothstep := false
export(float, EASE) var hide_curve := -1.6521

export(Array, NodePath) var scale_path := []
var scale_node := []
var scale_prop := []
export var scale_range := Vector2(0.0, 1.0)

func _ready():
	scale_node = []
	scale_prop = []
	for i in scale_path:
		var n = get_node_or_null(i)
		if n != null:
			var s = "scale" if n.get("scale") else "rect_scale" if n.get("rect_scale") else ""
			if s != "":
				scale_node.append(n)
				scale_prop.append(s)

func _physics_process(delta):
	hide_last = hide_clock
	hide_clock = clamp(hide_clock + (delta if is_hide else -delta), 0.0, hide_time)
	if hide_clock != hide_last:
		var h = hide_clock / hide_time
		var l = smoothstep(0, 1, h) if is_smoothstep else ease(h, hide_curve)
		rect_position = start_pos.linear_interpolate(start_pos + hide_offset, l)
		
		for i in scale_node.size():
			scale_node[i].set(scale_prop[i], Vector2.ONE * lerp(scale_range.x, scale_range.y, l))

