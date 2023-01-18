extends Control

onready var label := $Label

var targets := []
var vars := []


func track(_self, _meta):
	targets.append(_self)
	vars.append(_meta)

func _input(event):
	if event.is_action_pressed("ui_debug"):
		visible = !visible

func _physics_process(delta):
	label.text = ""
	for i in targets.size():
		if is_instance_valid(targets[i]):
			label.text += targets[i].name + "." + vars[i] + ": " + str(targets[i].get(vars[i])) + "\n"
