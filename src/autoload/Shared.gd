extends Node


var actors := []
var solid_maps := []

var player

func change_scene(_path := ""):
	get_tree().change_scene(_path)
