tool
extends Actor
class_name Player

var walk_speed := 500.0
var floor_accel := 12.0
var air_accel := 7.0
var dir_x := 1

var joy := Vector2.ZERO
var joy_last := Vector2.ZERO
var btnp_jump := false
var btn_jump := false
var btnp_shoot := false
var btn_shoot := false
var btnp_grab := false
var btn_grab := false

var is_jump := false
var jump_count := 0
var holding_jump := 0.0
var holding_limit := 0.3
var jump_speed := 500.0
var jump_gravity := 500.0
var fall_gravity := 1000.0
export var set_jump := false setget set_jump
export var jump_height := 240.0
export var jump_time := 0.6
export var fall_mult := 2.5
var jump_clock := 0.0
var jump_minimum := 0.05
var air_clock := 0.0
export var coyote_time := 0.125

var is_push := false
var push_ease := EaseMover.new(0.08)
var wall_clock := 0.0
var push_timeout := 0.2

var grab = null
var is_grab := false
var grab_ease := EaseMover.new(0.15)
export var grab_length := 200.0
export var throw_vel := Vector2(350, -500)
export var drop_vel := Vector2(0, -100)

onready var arm_l := $Image/ArmL
onready var arm_r := $Image/ArmR
onready var image := $Image
var walk_clock := 0.0

var bullet_scene = preload("res://src/actor/Bullet.tscn")
var fire_clock := 0.0
export var fire_rate := 0.25

func _ready():
	if Engine.editor_hint: return
	
	solve_jump()
	
	UI.debug.track(self, "position")
	UI.debug.track(self, "remainder")
	UI.debug.track(self, "has_hit")
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "is_jump")
	UI.debug.track(self, "is_push")
	
	get_tree().connect("idle_frame", self, "idle_frame")

func _input(event):
	if Engine.editor_hint: return
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and event.scancode == KEY_R:
		get_tree().reload_current_scene()

func _physics_process(delta):
	if Engine.editor_hint: return
	
	# input
	joy_last = joy
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
	
	# start jump
	if btn_jump and jump_count == 0 and air_clock < coyote_time and holding_jump < holding_limit:
		velocity.y = -jump_speed
		is_jump = true
		jump_clock = 0.0
		jump_count += 1
	# in air
	elif !is_floor:
		
		# during jump
		if is_jump:
			jump_clock += delta
			
			if btn_jump:
				if velocity.y > 0:
					is_jump = false
			elif jump_clock > jump_minimum:
				is_jump = false
	
	# walking
	velocity.x = lerp(velocity.x, joy.x * walk_speed , (floor_accel if is_floor else air_accel) * delta)
	
	# gravity
	velocity.y += (jump_gravity if is_jump else fall_gravity) * delta
	
	# movement
	move(velocity * delta)
	
	# air clock
	air_clock = 0.0 if is_floor else air_clock + delta
	# wall clock
	wall_clock = 0.0 if has_hit.x != 0 else wall_clock + delta
	
	# shoot
	fire_clock = min(fire_clock + delta, fire_rate)
	if btn_shoot:
		if fire_clock == fire_rate:
			fire_clock = 0.0
			shoot()
	
	# grab
	if btnp_grab:
		if grab == null:
			grab()
		else:
			drop(joy.y != 1)
	
	# push
	if is_push:
		if joy.x == 0 or wall_clock > push_timeout:
			is_push = false
			push_ease.reset()
		elif has_hit.x != 0:
			var pb = get_actor("box", position + Vector2(dir_x * 10, 0))
			if is_instance_valid(pb) and pb.is_floor:
				pb.push(dir_x)
	else:
		push_ease.count(delta, is_floor and !is_grab and has_hit.x != 0)
		if push_ease.is_complete:
			push_ease.reset()
			is_push = true
	
	# open door
	if joy.y == -1 and joy_last.y != -1:
		var d = get_actor("door")
		if is_instance_valid(d):
			if d.scene_path != "":
				get_tree().change_scene(d.scene_path)
	
	# arms
	if is_grab:
		grab_ease.count(delta)
		
		var d = position.distance_to(grab.position)
		if d > grab_length:
			drop()
	else:
		arm_l.set_point_position(1, arm_l.get_point_position(1).linear_interpolate(Vector2(-30, 0), 20 * delta))
		arm_r.set_point_position(1, arm_r.get_point_position(1).linear_interpolate(Vector2(30, 0), 20 * delta))
	
	# body
	walk_clock = walk_clock + (delta * dir_x) if joy.x == joy_last.x else 0.0
	
	if is_floor:
		if joy.x == 0:
			image.rotation_degrees = sin(walk_clock * 4.0) * 5
			image.position.y = -abs(cos(walk_clock * 4.0) * 5)
		else:
			image.rotation_degrees = sin(walk_clock * 10.0) * 20
			image.position.y = -abs(sin(walk_clock * 10.0) * 20)
	else:
		image.rotation_degrees = (dir_x * 7) + sin(walk_clock * 9.0) * 3
		image.position.y = lerp(image.position.y, 0, 10 * delta)

func idle_frame():
	# grab
	if is_grab and is_instance_valid(grab):
		arm_l.set_point_position(1, arm_l.get_point_position(1).linear_interpolate(arm_l.to_local(grab.global_position + Vector2(-50, 50)), grab_ease.frac()))
		arm_r.set_point_position(1, arm_r.get_point_position(1).linear_interpolate(arm_r.to_local(grab.global_position + Vector2(50, 50)), grab_ease.frac()))

func hit_floor():
	jump_count = 0

func set_jump(arg := false):
	set_jump = arg
	solve_jump()

# Sebastian Lague's formula
func solve_jump():
	jump_gravity = (2 * jump_height) / pow(jump_time, 2)
	jump_speed = jump_gravity * jump_time
	fall_gravity = jump_gravity * fall_mult

func shoot():
	var b = bullet_scene.instance()
	get_parent().add_child(b)
	b.position = position# + Vector2(100 * dir_x, 0)
	b.rotation_degrees = 90 * dir_x
	b.speed = 1000

func grab():
	var a = []
	if joy.y == 1:
		a = get_actors("box", position + Vector2(0, size.y))
	else:
		var add = Vector2(50, 10)
		a = get_actors("box", position + Vector2(dir_x * add.x, -add.y), Vector2(add.x, size.y + add.y), null)
	
	# sort by nearest distance
	var d = 1000.0
	for i in a:
		var dt = position.distance_to(i.position)
		if dt < d:
			grab = i
			d = dt
	
	# grab
	if is_instance_valid(grab):
		grab.grab(self, joy.x)
		is_grab = true
		grab_ease.reset()

# drop / throw
func drop(is_throw := false):
	var tv = Vector2(max(throw_vel.x, abs(velocity.x)) * dir_x, min(throw_vel.y, velocity.y))
	grab.drop(tv if is_throw else drop_vel)
	
	grab = null
	is_grab = false
