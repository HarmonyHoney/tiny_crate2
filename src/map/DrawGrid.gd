extends Node2D

export var lines := Vector2(8, 8)

export var width := 5.0

func _ready():
	position = position.snapped(Vector2.ONE * 100)

func _draw():
	# offset
	var o = (lines * 100.0) / 2.0
	
	# vertical
	for x in lines.y + 1:
		var p = Vector2(x * 100, 0) - o
		draw_line(p, p + Vector2(0, lines.y * 100), Color(1.0, 1.0, 1.0, 0.7), width)
	
	# horizontal
	for y in lines.x + 1:
		var p = Vector2(0, y * 100) - o
		draw_line(p, p + Vector2(lines.x * 100, 0), Color(1.0, 1.0, 1.0, 0.7), width)
