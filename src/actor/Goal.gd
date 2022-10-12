tool
extends Actor

onready var image := $Image
onready var player = Shared.player

var is_follow := false
var follow_speed := 5.0
var close_frac := 0.5

export var x_offset := 60.0
export var offset := Vector2(70, -10)

func _ready():
	if Engine.editor_hint: return
	
	Shared.connect("scene_before", self, "scene_before")
	
	if Shared.goals.has(Shared.current_scene + "/" + name):
		image.collect()
	elif !Shared.is_reset:
		Cutscene.goal_pan.act(self)

func _physics_process(delta):
	if Engine.editor_hint: return
	
	if is_instance_valid(player):
		if is_follow:
			var v = player.position + (Vector2(-player.dir_x, 1) * offset)
			var spd = follow_speed * (1.0 if position.distance_to(player.position) > x_offset else close_frac)
			position = position.linear_interpolate(v, spd * delta)
		elif get_rect().intersects(player.get_rect()):
			is_follow = true

func scene_before(is_reset):
	if !is_reset and is_follow:
		print(name, " collected")
		Shared.goal_grab(name)
