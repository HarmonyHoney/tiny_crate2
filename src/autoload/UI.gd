extends CanvasLayer

onready var debug := $Control/Debug

onready var gems := $Control/Gems
onready var gems_label := $Control/Gems/Label

func _ready():
	for i in $Control.get_children():
		i.visible = false
	
	gems.visible = true
