extends CanvasLayer

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("ui_pause"):
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused
		UI.gems.is_hide = !visible
