tool
extends Actor

var is_move := true
export var rise_gravity := 1000.0
export var fall_gravity := 1000.0

var last_floor := false
export var floor_accel := 12.0
var floor_clock := 0.0
export var snap_time := 0.3

var is_grab := false
var grab_node = null
var is_pickup_squish := false
var pickup_ease := EaseMover.new(0.2)
export var pickup_squish := Vector2.ONE * 0.8

onready var sprite := $Sprite

var is_snap := false
var snap_ease := EaseMover.new(0.2)
var snap_from := Vector2.ZERO
var grab_to := Vector2.ZERO
export var snap_squish := Vector2.ONE * 0.7


var is_line := false
onready var lines_node := $Lines
onready var lines := lines_node.get_children()
var line_ease := EaseMover.new(0.3)
var line_step := 0
onready var line_start_alpha : float = $Lines.modulate.a

var is_toss := false
var toss_dir := 1
var toss_ease := EaseMover.new(0.5)

func _ready():
	if Engine.editor_hint: return
	
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "position")
	
	position = position.snapped(Vector2.ONE * 50)

func _physics_process(delta):
	if Engine.editor_hint: return
	
#	if is_toss:
#		position = toss_ease.move(delta)
#
#		if toss_ease.is_complete:
#			is_toss = false
#			velocity = Vector2.ZERO
#
#		return
#
#	if is_line:
#		line_ease.count(delta)
#
#		if line_step == 0:
#			for i in lines:
#				i.scale = Vector2.ONE * line_ease.smooth()
#		elif line_step == 1:
#			lines_node.modulate.a = (1.0 - line_ease.smooth()) * line_start_alpha
#		else:
#			lines_node.visible = false
#			is_line = false
#
#		if line_ease.is_complete:
#			line_step += 1
#			line_ease.reset()
	
	
	# pickup squish
	if is_pickup_squish:
		pickup_ease.count(delta)
		
		sprite.scale = pickup_squish.linear_interpolate(Vector2.ONE, pickup_ease.frac())
		
		if pickup_ease.is_complete:
			is_pickup_squish = false
	
	if is_snap:
		snap_ease.count(delta)

		sprite.position = snap_from.linear_interpolate(Vector2.ZERO, snap_ease.smooth())
		sprite.scale = snap_squish.linear_interpolate(Vector2.ONE, snap_ease.smooth())

		if snap_ease.is_complete:
			is_snap = false
	elif is_grab:
		if is_instance_valid(grab_node):
			var p = (grab_node.position + Vector2(0, -100)).snapped(Vector2.ONE * 25)
			if !check_solid(p):
				grab_to = p
		
		position = position.linear_interpolate(grab_to, 15.0 * delta).round()
	else:
		# on floor
		if is_floor:
			# slow down
			velocity.x = lerp(velocity.x, 0.0, floor_accel * delta)
		
		# gravity
		velocity.y += (fall_gravity if velocity.y > 0.0 else rise_gravity) * delta
		
		# move
		move(velocity * delta)

func pickup(other):
	is_grab = true
	is_pickup_squish = true
	pickup_ease.reset()
	grab_node = other
	grab_to = position

func drop(_vel := Vector2.ZERO):
	is_grab = false
	is_move = true
	is_pickup_squish = true
	pickup_ease.reset()
	floor_clock = 0.0
	
	velocity = _vel
	grab_node = null

func hit_floor():
	snap()

func snap():
	var p = position
	#position = position.snapped(Vector2.ONE * 50)
	position = Vector2(stepify(position.x, 25), position.y)
	sprite.position = p - position
	print(name, " snapped ", sprite.position, " to ", position)
	
	snap_from = sprite.position
	
	velocity = Vector2.ZERO
	is_snap = true
	snap_ease.reset()
	
#	is_line = true
#	line_step = 0
#	lines_node.modulate.a = line_start_alpha
#	lines_node.visible = true
#
#	for i in lines:
#		i.scale = Vector2.ZERO
#
#	lines_node.rotation_degrees = 90 * (randi() % 4)
	
