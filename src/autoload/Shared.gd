extends Node

var actors := []
var solid_maps := []

var player

onready var current_scene : String = get_tree().current_scene.filename
var last_scene := ""

var door_in
#var door_out

signal scene_before
signal scene_after

var goals := []

func change_scene(_path := ""):
	if _path != "":
		emit_signal("scene_before")
		if _path != current_scene:
			last_scene = current_scene
			current_scene = _path
		get_tree().change_scene(_path)
		emit_signal("scene_after")

func reset():
	change_scene(current_scene)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		get_tree().quit()
		
		print("goals: ", goals)

func goal_grab(name := "Goal"):
	var n = current_scene + "/" + name
	if !goals.has(n):
		goals.append(n)
		print(name, " collected")
		
		yield(get_tree().create_timer(0.3), "timeout")
		UI.gems.is_hide = false
		yield(get_tree().create_timer(0.5), "timeout")
		UI.gems_label.text = str(goals.size())
		yield(get_tree().create_timer(1.0), "timeout")
		UI.gems.is_hide = true
		

