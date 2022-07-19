extends CanvasLayer

onready var pause_menu := $Control/PauseMenu

onready var debug := $Control/Debug

func _ready():
	pause_menu.visible = false
