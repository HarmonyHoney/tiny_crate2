tool
extends Actor
class_name Door

export (String, FILE) var scene_path := ""

var player
var is_active := false

var delay_ease := EaseMover.new(0.4)
var fade_ease := EaseMover.new(0.3)
var open_ease := EaseMover.new(0.5)

onready var arrow := $Arrow

func _enter_tree():
	if scene_path != "" and scene_path == Shared.last_scene:
		Shared.door_in = self

func _ready():
	if Engine.editor_hint: return
	
	player = Shared.player
	UI.debug.track(self, "is_active")

func _physics_process(delta):
	if Engine.editor_hint: return
	
	if delay_ease.clock < delay_ease.time:
		delay_ease.count(delta)
	else:
		is_active = get_rect().intersects(player.get_rect()) and scene_path != ""
		open_ease.count(delta, is_active and player.joy.y == -1)
	
	arrow.modulate.a = fade_ease.count(delta, is_active)
	arrow.material.set_shader_param("fill_y", open_ease.smooth())
	
	if open_ease.is_complete:
		set_physics_process(false)
		open()

func open():
	if scene_path != "":
		Shared.change_scene(scene_path)
