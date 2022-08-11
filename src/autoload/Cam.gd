extends Camera2D

var target_node

export var is_follow := true

func _ready():
	UI.debug.track(self, "position")

func _physics_process(delta):
	if is_follow and is_instance_valid(target_node):
		position = target_node.global_position

func follow(_target):
	target_node = _target
