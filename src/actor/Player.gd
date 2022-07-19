extends KinematicBody2D


var velocity := Vector2.ZERO
var walk_speed := 500.0
var floor_accel := 12.0
var air_accel := 7.0
var dir_x := 1


var is_floor := false
var joy := Vector2.ZERO
var btnp_jump := false
var btn_jump := false
var btnp_action := false
var btn_action := false

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

onready var sprite := $Sprite

var bullet_scene = preload("res://src/actor/Bullet.tscn")

var fire_clock := 0.0
export var fire_rate := 1.0

func _ready():
	solve_jump()
	
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "is_jump")

func _input(event):
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and event.scancode == KEY_R:
		get_tree().reload_current_scene()

func _physics_process(delta):
	
	# input
	joy = Input.get_vector("left", "right", "up", "down").round()
	btnp_jump = Input.is_action_just_pressed("jump")
	btn_jump = Input.is_action_pressed("jump")
	holding_jump = holding_jump + delta if btn_jump else 0.0
	btnp_action = Input.is_action_just_pressed("action")
	btn_action = Input.is_action_pressed("action")
	
	# dir x
	if joy.x != 0:
		dir_x = joy.x
		sprite.flip_v = dir_x < 0
	
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
	
	if btn_action:
		if fire_clock == fire_rate:
			fire_clock = 0.0
			shoot()

func shoot():
	var b = bullet_scene.instance()
	get_parent().add_child(b)
	b.position = position# + Vector2(100 * dir_x, 0)
	b.rotation_degrees = 90 * dir_x
	b.speed = 1000

func move(_vel := Vector2.ZERO):
	var move_x = Vector2(_vel.x, 0)
	var is_x = test_move(transform, move_x)
	move_and_collide(move_x)
	
	# hit x
	if is_x:
		velocity.x = 0.0
	
	var move_y = Vector2(0, _vel.y)
	var is_y = test_move(transform, move_y)
	move_and_collide(move_y)
	
	# hit y
	if is_y:
		velocity.y = 0.0
	
	is_floor = is_y and _vel.y > 0.0

# Sebastian Lague's formula
func solve_jump():
	jump_gravity = (2 * jump_height) / pow(jump_time, 2)
	jump_speed = jump_gravity * jump_time
	fall_gravity = jump_gravity * 2.0
