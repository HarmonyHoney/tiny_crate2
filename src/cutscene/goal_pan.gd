extends Node


func act(goal):
	Shared.player.is_input = false
	yield(get_tree().create_timer(0.5), "timeout")
	Cam.is_follow = false
	
	Cam.pan(goal.position)
	yield(Cam, "pan_complete")
	yield(get_tree().create_timer(0.5), "timeout")
	
	Cam.pan(Shared.player.position)
	yield(Cam, "pan_complete")
	Cam.is_follow = true
	Shared.player.is_input = true
