extends Node

var actors := []
var solid_maps := []
var water_maps := []
var player
var spike_map

onready var current_scene : String = get_tree().current_scene.filename
var last_scene := "spawn"

var doors := []
var door_in
var door_out
signal door_open

var is_reset := false
signal scene_before
signal scene_after

var goals := []
var debug_screen := 0
var debug_screen_limit := 4


func _ready():
	Wipe.connect("close", self, "change_scene")

func _input(event):
	if event.is_action_pressed("debug_borderless"):
		OS.window_borderless = !OS.window_borderless
	
	if event.is_action_pressed("debug_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if event.is_action_pressed("debug_screen"):
		debug_screen = posmod(debug_screen + 1, debug_screen_limit)
		var frac = float(debug_screen + 1) / debug_screen_limit
		var gss = OS.get_screen_size() * frac
		OS.window_size = gss + Vector2(2 if frac == 1.0 else 0, 0)
		OS.center_window()

func change_scene(_path := current_scene):
	if _path != "":
		is_reset = _path == current_scene
		emit_signal("scene_before")
		if _path != current_scene:
			last_scene = current_scene
			current_scene = _path
		get_tree().change_scene(_path)
		yield(get_tree(), "idle_frame")
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
		

