tool
extends Actor

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

export var is_sticky := false
var is_stuck := false

func _ready():
	if Engine.editor_hint: return
	#position = position.snapped(Vector2.ONE * 25)
	
	#UI.debug.track(self, "is_floor")
	UI.debug.track(self, "position")
	
	if is_sticky:
		sprite.modulate = Color(0,1.45,0,1)

func _physics_process(delta):
	if Engine.editor_hint: return
	
	# pickup squish
	if is_pickup_squish:
		pickup_ease.count(delta)
		
		sprite.scale = pickup_squish.linear_interpolate(Vector2.ONE, pickup_ease.frac())
		
		if pickup_ease.is_complete:
			is_pickup_squish = false
	# snap
	if is_snap:
		snap_ease.count(delta)
		
		sprite.position = snap_from.linear_interpolate(Vector2.ZERO, snap_ease.smooth())
		sprite.scale = snap_squish.linear_interpolate(Vector2.ONE, snap_ease.smooth())
		
		if snap_ease.is_complete:
			is_snap = false
	# grab
	elif is_grab:
		if is_instance_valid(grab_node) and grab_node.grab_ease.is_complete and (grab_node.position.y > position.y - size.y or (grab_node.is_floor and grab_node.get_actor("box", grab_node.position + Vector2(0, 1)) != self)):
			var p = grab_node.position + Vector2(0, -125)
			var li = position.linear_interpolate(p, 15 * delta).round()
			var diff = li - position
			move(diff)
	# sticky
	elif is_stuck:
		pass
	# move
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
	is_stuck = false

func drop(_vel := Vector2.ZERO):
	is_grab = false
	is_floor = false
	is_pickup_squish = true
	pickup_ease.reset()
	floor_clock = 0.0
	
	velocity = _vel
	grab_node = null

func just_moved():
	if is_sticky and !is_grab and has_hit != Vector2.ZERO:
		if has_hit.x != 0:
			snap(position, true)
			is_stuck = true
		elif has_hit.y < 0:
			snap()
			is_stuck = true

func hit_floor():
	if !is_grab:
		snap()

func snap(_pos := position, is_y := false):
	var last_pos = position
	if is_y:
		position = Vector2(_pos.x, stepify(_pos.y, 25))
	else:
		position = Vector2(stepify(_pos.x, 25), _pos.y)
	sprite.position = last_pos - position
	snap_from = sprite.position
	
	velocity = Vector2.ZERO
	is_snap = true
	snap_ease.reset()
	print(name, " snapped ", sprite.position, " to ", position)

func push(dir_x := 1.0):
	var v = Vector2(dir_x * 25, 0)
	if !check_solid(position + v):
		snap(position + v)
