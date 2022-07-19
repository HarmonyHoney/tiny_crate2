extends Control

onready var label := $Label

#var target
#var meta := ""

var targets := []
var vars := []


func track(_self, _meta):
	#print("track(", _self.name, ", ", _meta, ")")
	targets.append(_self)
	vars.append(_meta)

func _physics_process(delta):
	label.text = ""
	for i in targets.size():
		if is_instance_valid(targets[i]):
			label.text += targets[i].name + "." + vars[i] + ": " + str(targets[i].get(vars[i])) + "\n"
