tool
extends Actor

onready var image := $Image
onready var player = Shared.player

var is_collect := false
var is_follow := false
var follow_speed := 5.0
var close_frac := 0.5

var is_door := false
var door_ease := EaseMover.new(0.45)

export var x_offset := 60.0
export var offset := Vector2(70, -10)

func _enter_tree():
	if Engine.editor_hint: return
	
	Wipe.connect("open", self, "wipe_open")
	Shared.connect("door_open", self, "door_open")
	Shared.connect("scene_before", self, "scene_before")

func _ready():
	if Engine.editor_hint: return
	
	if Shared.goals.has(Shared.current_scene + "/" + name):
		is_collect = true
		image.collect()

func _physics_process(delta):
	if Engine.editor_hint: return
	
	if is_door:
		position = door_ease.move(delta)
		scale = Vector2.ONE.linear_interpolate(Vector2.ZERO, door_ease.smooth())
	elif is_instance_valid(player):
		if is_follow:
			var v = player.position + (Vector2(-player.dir_x, 1) * offset)
			var spd = follow_speed * (1.0 if position.distance_to(player.position) > x_offset else close_frac)
			position = position.linear_interpolate(v, spd * delta)
		elif get_rect().intersects(player.get_rect()):
			is_follow = true

func wipe_open():
	if !is_collect and !Shared.is_reset:
		Cutscene.goal_pan.act(self)

func door_open():
	if is_follow and is_instance_valid(Shared.door_out):
		is_door = true
		door_ease.from = position
		door_ease.to = Shared.door_out.position + Vector2(0, 5)

func scene_before():
	if !Shared.is_reset and is_follow:
		print(name, " collected")
		Shared.goal_grab(name)
