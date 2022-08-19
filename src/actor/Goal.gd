tool
extends Actor

onready var dir = 1 if randf() > 0.5 else -1
var turn_speed := 60.0

onready var image := $Image
onready var player = Shared.player

var is_follow := false
var follow_speed := 5.0
var close_frac := 0.5

export var x_offset := 60.0
export var offset := Vector2(70, -10)

func _physics_process(delta):
	if Engine.editor_hint: return
	
	image.rotate(deg2rad(turn_speed * dir * delta))
	
	if is_instance_valid(player):
		if is_follow:
			var v = player.position + (Vector2(-player.dir_x, 1) * offset)
			var spd = follow_speed * (1.0 if position.distance_to(player.position) > x_offset else close_frac)
			position = position.linear_interpolate(v, spd * delta)
		elif get_rect().intersects(player.get_rect()):
			is_follow = true
