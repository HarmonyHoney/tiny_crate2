extends Node2D

onready var c := Cam
onready var py : float = position.y
onready var ry : float = $ColorRect.get_rect().size.y
var frac := 0.0

export var from := 0
export var to := 1

func _ready():
	visible = false

func _physics_process(delta):
	var last = frac
	frac = clamp((c.position.y - py) / ry, 0, 1)
	if frac != last:
		BG.color_lerp(from, to, frac)
	
	
