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

func _ready():
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "position")
	
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
			position = position.linear_interpolate(p, 15.0 * delta).round()
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
	pickup_ease.clock = 0.0
	grab_node = other

func drop(_vel := Vector2.ZERO):
	is_grab = false
	is_move = true
	is_pickup_squish = true
	pickup_ease.clock = 0.0
	floor_clock = 0.0
	
	velocity = _vel
	if _vel == Vector2.ZERO:
		#position = position.snapped(Vector2.ONE * 50)
		position = grab_node.position.snapped(Vector2.ONE * 50)
	
	grab_node = null

func hit_floor():
	snap()

func snap():
	var p = position
	position = position.snapped(Vector2.ONE * 50)
	sprite.position = p - position
	print(name, " snapped ", sprite.position, " to ", position)
	
	snap_from = sprite.position
	
	velocity = Vector2.ZERO
	is_snap = true
	snap_ease.clock = 0.0
