extends CanvasLayer

onready var debug := $Control/Debug

onready var gems := $Control/Gems
onready var gems_label := $Control/Gems/Label

func _ready():
	for i in $Control.get_children():
		i.visible = false
	
	gems.visible = true

func _input(event):
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and event.scancode == KEY_F11:
		debug.visible = !debug.visible
