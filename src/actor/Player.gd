tool
extends Actor
class_name Player

var walk_speed := 500.0
var floor_accel := 12.0
var air_accel := 7.0
var dir_x := 1

var joy := Vector2.ZERO
var btnp_jump := false
var btn_jump := false
var btnp_shoot := false
var btn_shoot := false
var btnp_grab := false
var btn_grab := false

var is_jump := false
var holding_jump := 0.0
var holding_limit := 0.3
var jump_speed := 500.0
var jump_gravity := 500.0
var fall_gravity := 1000.0
var jump_height := 240.0
var jump_time := 0.7
var jump_clock := 0.0
var jump_minimum := 0.03

var bullet_scene = preload("res://src/actor/Bullet.tscn")

var fire_clock := 0.0
export var fire_rate := 1.0

var pickup = null
export var throw_vel := Vector2(500, -500)
var is_ignore_end := false

func _ready():
	if Engine.editor_hint: return
	
	solve_jump()
	
	UI.debug.track(self, "position")
	UI.debug.track(self, "remainder")
	UI.debug.track(self, "has_hit")
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "is_jump")

func _input(event):
	if Engine.editor_hint: return
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and event.scancode == KEY_R:
		get_tree().reload_current_scene()

func _physics_process(delta):
	if Engine.editor_hint: return
	
	# input
	joy = Input.get_vector("left", "right", "up", "down").round()
	btnp_jump = Input.is_action_just_pressed("jump")
	btn_jump = Input.is_action_pressed("jump")
	holding_jump = holding_jump + delta if btn_jump else 0.0
	btnp_shoot = Input.is_action_just_pressed("shoot")
	btn_shoot = Input.is_action_pressed("shoot")
	btnp_grab = Input.is_action_just_pressed("grab")
	btn_grab = Input.is_action_pressed("grab")
	
	# dir x
	if joy.x != 0:
		dir_x = joy.x
		#sprite.flip_v = dir_x < 0
	
	# on floor
	if is_floor:
		
		# start jump
		if btn_jump and holding_jump < holding_limit:
			velocity.y = -jump_speed
			is_jump = true
			jump_clock = 0.0
	
	# in air
	else:
		
		# during jump
		if is_jump:
			jump_clock += delta
			
			if btn_jump:
				if velocity.y > 0:
					is_jump = false
			else:
				is_jump = false
	
	# walking
	velocity.x = lerp(velocity.x, joy.x * walk_speed , (floor_accel if is_floor else air_accel) * delta)
	
	# gravity
	velocity.y += (jump_gravity if is_jump else fall_gravity) * delta
	
	# movement
	move(velocity * delta)
	
	# shoot
	fire_clock = min(fire_clock + delta, fire_rate)
	
	if btn_shoot:
		if fire_clock == fire_rate:
			fire_clock = 0.0
			shoot()
	
	# grab
	if btnp_grab:
		if pickup == null:
			grab()
		else:
			drop()

func shoot():
	var b = bullet_scene.instance()
	get_parent().add_child(b)
	b.position = position# + Vector2(100 * dir_x, 0)
	b.rotation_degrees = 90 * dir_x
	b.speed = 1000

# Sebastian Lague's formula
func solve_jump():
	jump_gravity = (2 * jump_height) / pow(jump_time, 2)
	jump_speed = jump_gravity * jump_time
	fall_gravity = jump_gravity * 2.0

func grab():
	# find clostest box
	var d = 1000.0
	
	var a = get_actors("box", position, Vector2.ONE * 75, null)
	
	print(a)
	
	for i in a:
		var dt = position.distance_to(i.position)
		if dt < d:
			pickup = i
			d = dt
	
	
	# pickup
	if is_instance_valid(pickup):
		set_ignore(pickup)
		pickup.pickup(self)
		print(pickup.name)

func drop():
	print("drop")
	
	is_ignore_end = true
	
	var tv = Vector2(max(throw_vel.x, abs(velocity.x)) * dir_x, min(throw_vel.y, velocity.y))
	
	# drop / throw
	pickup.drop(Vector2.ZERO if joy.y == 1 else tv)
	
	pickup = null

func set_ignore(body):
	ignore = body
	ignore.ignore = self
	is_ignore_end = false

func just_moved():
	if is_ignore_end and is_instance_valid(ignore):
		if !get_rect().intersects(ignore.get_rect()):
			ignore.ignore = null
			ignore = null
