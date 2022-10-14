extends Camera2D

var target_node

export var is_follow := true
var is_pan := false
var pan_ease := EaseMover.new(1.0)
signal pan_complete

func _ready():
	UI.debug.track(self, "position")

func _physics_process(delta):
	if is_pan:
		position = pan_ease.move(delta)
		if pan_ease.is_complete:
			emit_signal("pan_complete")
			print("pan_complete")
			is_pan = false
	elif is_follow and is_instance_valid(target_node):
		position = target_node.global_position

func follow(_target):
	target_node = _target

func pan(pos : Vector2):
	pan_ease.reset()
	is_pan = true
	pan_ease.from = position
	pan_ease.to = pos
	pan_ease.time = lerp(0.3, 1.0, clamp(pan_ease.from.distance_to(pan_ease.to) / 100.0, 0, 20) / 20)
