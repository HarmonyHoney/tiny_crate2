extends Node2D

export var collected_color := Color(0, 0, 0, 0.2)

onready var dir = 1 if randf() > 0.5 else -1
var turn_speed := 60.0

func _physics_process(delta):
	if Engine.editor_hint: return
	
	rotate(deg2rad(turn_speed * dir * delta))

func collect():
	$Polygon2D.color = collected_color
