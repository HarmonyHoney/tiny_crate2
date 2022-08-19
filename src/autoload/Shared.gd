extends Node


var actors := []
var solid_maps := []

var player

onready var current_scene : String = get_tree().current_scene.filename
var last_scene := ""
#var next_scene := ""

var door_in
#var door_out

func change_scene(_path := ""):
	if _path != "":
		if _path != current_scene:
			last_scene = current_scene
			current_scene = _path
		get_tree().change_scene(_path)
		Clouds.clear()

func reset():
	change_scene(current_scene)
