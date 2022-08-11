extends CanvasLayer


onready var image := $ColorRect
export var parallax_scale := 1.0

func _ready():
	get_tree().connect("idle_frame", self, "idle_frame")

func idle_frame():
	var v : Vector2 = Cam.global_position / (Vector2(1600, 900) * parallax_scale)
	image.material.set_shader_param("offset", v)
