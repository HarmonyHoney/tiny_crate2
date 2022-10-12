tool
extends Actor
class_name Door

export (String, FILE) var scene_path := ""

var player
var is_active_last := true
var is_active := false

var delay_ease := EaseMover.new(0.4)
var fade_ease := EaseMover.new(0.3)
var open_ease := EaseMover.new(0.5)

onready var arrow := $Arrow
onready var window := $Window
onready var knob := $Knob

func _enter_tree():
	if Engine.editor_hint: return
	
	if scene_path != "" and scene_path == Shared.last_scene:
		Shared.door_in = self

func _ready():
	if Engine.editor_hint: return
	
	player = Shared.player
	UI.debug.track(self, "is_active")
	
	if scene_path == "":
		knob.modulate = Color.from_hsv(0.0, 0.3, 0.6, 1.0)
		window.modulate = knob.modulate
	elif "hub" in scene_path:
		window.visible = false
	elif Shared.goals.has(scene_path + "/Goal"):
		window.modulate = Color("FFFF33")

func _physics_process(delta):
	if Engine.editor_hint: return
	
	if delay_ease.clock < delay_ease.time:
		delay_ease.count(delta)
	else:
		is_active = get_rect().intersects(player.get_rect()) and scene_path != ""
		if is_active != is_active_last:
			pass#UI.gems.is_hide = !is_active
			
		is_active_last = is_active
		
		open_ease.count(delta, is_active and player.joy.y == -1)
	
	arrow.modulate.a = fade_ease.count(delta, is_active)
	arrow.material.set_shader_param("fill_y", open_ease.smooth())
	
	if open_ease.is_complete:
		set_physics_process(false)
		open()

func open():
	if scene_path != "":
		Wipe.start(scene_path)
