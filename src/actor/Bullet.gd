extends KinematicBody2D

export var speed := 1.0

var is_hit := false

var ease_fade := EaseMover.new()
var ease_blink := EaseMover.new(0.2)

func _physics_process(delta):
	# movement
	if is_hit:
		modulate.a = 1.0 - ease_fade.count(delta)
		
		if ease_fade.is_complete:
			set_physics_process(false)
	else:
		var mc = move_and_collide(Vector2.UP.rotated(rotation) * speed * delta)
		if mc:
			is_hit = true
			#modulate = Color.white
		else:
			# blink
			ease_blink.count(delta)
			if ease_blink.is_complete:
				ease_blink.clock = 0.0
				modulate = Color.red if (modulate == Color.white) else Color.white
	
	
