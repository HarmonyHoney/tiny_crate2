extends CanvasLayer

var is_wipe := false
var is_in := false
var wipe_ease := EaseMover.new(0.5)
var scene := ""

export var limit := 0.58

onready var mat : ShaderMaterial = $ColorRect.material

signal complete

func _ready():
	visible = false

func _physics_process(delta):
	if is_wipe:
		wipe_ease.count(delta, !is_in)
		mat.set_shader_param("dist", lerp(-0.01, limit, wipe_ease.smooth()))
		
		if is_in and wipe_ease.clock == 0.0:
			is_in = false
			emit_signal("complete", scene)
			yield(Shared, "scene_after")
		elif wipe_ease.is_complete:
			is_wipe = false
			visible = false

func start(_scene := ""):
	Shared.player.is_input = false
	Shared.player.joy = Vector2.ZERO
	visible = true
	is_wipe = true
	is_in = true
	wipe_ease.clock = wipe_ease.time
	scene = _scene
