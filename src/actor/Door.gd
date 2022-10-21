tool
extends Actor
class_name Door

export (String, FILE) var scene_path := ""

var player
var is_active := false

var fade_ease := EaseMover.new(0.3)
var arrow_ease := EaseMover.new(0.5)
var is_open := false
var open_ease := EaseMover.new(0.4)

onready var arrow := $Arrow
onready var back := $Back
onready var image := $Image
onready var window := $Image/Window
onready var knob := $Image/Knob

func _enter_tree():
	if Engine.editor_hint: return
	
	Shared.doors.append(self)
	
	if scene_path != "" and scene_path == Shared.last_scene:
		Shared.door_in = self
	else:
		open_ease.end()

func _exit_tree():
	if Engine.editor_hint: return
	
	Shared.doors.erase(self)

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
	
	image.scale.x = open_ease.count(delta, !is_open)
	back.visible = open_ease.is_less
	
	is_active = !player.is_grab and get_rect().intersects(player.get_rect()) and scene_path != "" and !Wipe.is_wipe and !Cutscene.is_playing
	
	arrow.modulate.a = fade_ease.count(delta, is_active and !is_open)
	
	if arrow_ease.is_less:
		arrow.material.set_shader_param("fill_y", arrow_ease.count(delta, is_active and player.joy.y == -1))
		if arrow_ease.is_complete:
			open()

func open():
	if scene_path != "" and scene_path != "spawn":
		is_open = true
		Wipe.start(scene_path)
		Shared.door_out = self
		Shared.emit_signal("door_open")
