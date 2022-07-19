extends Camera2D

export var target_path : NodePath
onready var target_node := get_node_or_null(target_path)

export var is_follow_x := false
export var is_follow_y := false

func _physics_process(delta):
	if is_instance_valid(target_node):
		
		if is_follow_x:
			position.x = target_node.global_position.x
		
