extends KinematicBody2D

var is_move := true
var velocity := Vector2.ZERO
export var rise_gravity := 1000.0
export var fall_gravity := 1000.0

var is_floor := false
var last_floor := false
export var floor_accel := 12.0
var floor_clock := 0.0
export var snap_time := 0.3

var is_grab := false
var grab_node : KinematicBody2D = null
var is_pickup_squish := false
var pickup_ease := EaseMover.new(0.2)
export var pickup_squish := Vector2.ONE * 0.8

onready var sprite := $Sprite

var is_snap := false
var snap_ease := EaseMover.new(0.2)
var snap_from := Vector2.ZERO

onready var col_shape := $CollisionShape2D

func _ready():
	UI.debug.track(self, "is_floor")
	
	position = position.snapped(Vector2.ONE * 50)

func _physics_process(delta):
	
	# pickup squish
	if is_pickup_squish:
		pickup_ease.count(delta)
		
		sprite.scale = pickup_squish.linear_interpolate(Vector2.ONE, pickup_ease.frac())
		
		if pickup_ease.is_complete:
			is_pickup_squish = false
	
	if is_snap:
		snap_ease.count(delta)
		
		sprite.position = snap_from.linear_interpolate(Vector2.ZERO, snap_ease.smooth())
		
		if snap_ease.is_complete:
			is_snap = false
	elif is_grab:
		if is_instance_valid(grab_node):
			var p = grab_node.position.snapped(Vector2.ONE * 50)
			position = position.linear_interpolate(p, 15.0 * delta)
	elif is_move:
		# on floor
		if is_floor:
			floor_clock += delta
			
			# slow down
			velocity.x = lerp(velocity.x, 0.0, floor_accel * delta)
		
		# gravity
		velocity.y += (fall_gravity if velocity.y > 0.0 else rise_gravity) * delta
		
		# move
		move(velocity * delta)
		
		# snap
		if floor_clock > snap_time and abs(velocity.x) < 20.0:
			snap()
			is_move = false
	else:
		if !test_move(transform, Vector2.DOWN * 5.0):
			is_move = true

func move(_vel := Vector2.ZERO):
	var move_x = Vector2(_vel.x, 0)
	var is_x = test_move(transform, move_x)
	move_and_collide(move_x, false)
	
	# hit x
	if is_x:
		velocity.x = 0.0
	
	var move_y = Vector2(0, _vel.y)
	var is_y = test_move(transform, move_y)
	move_and_collide(move_y, false)
	
	# hit y
	if is_y:
		velocity.y = 0.0
	
	last_floor = is_floor
	is_floor = is_y and _vel.y > 0.0
	
	if !last_floor and is_floor:
		print(name, " hit floor")
	
	if !is_floor:
		floor_clock = 0.0

func pickup(other):
	is_grab = true
	is_pickup_squish = true
	pickup_ease.clock = 0.0
	grab_node = other

func drop():
	is_grab = false
	is_move = true
	is_pickup_squish = true
	pickup_ease.clock = 0.0
	floor_clock = 0.0
	
	#position = grab_node.position.snapped(Vector2.ONE * 50)
	grab_node = null

func snap():
	var p = position
	position = position.snapped(Vector2.ONE * 50)
	sprite.position = p - position
	print(name, " snapped ", sprite.position)
	
	snap_from = sprite.position
	
	velocity = Vector2.ZERO
	is_snap = true
	snap_ease.clock = 0.0
