extends Node


func act(goal):
	Cutscene.is_playing = true
	Shared.player.input_stop()
	Cam.is_follow = false
	Cam.pan(goal.position)
	
	yield(Cam, "pan_complete")
	yield(get_tree().create_timer(0.5), "timeout")
	
	Cam.pan(Shared.player.position)
	yield(Cam, "pan_complete")
	
	Cam.is_follow = true
	Shared.player.input_start()
	Cutscene.is_playing = false
