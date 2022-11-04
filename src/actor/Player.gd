tool
extends Actor
class_name Player

var walk_speed := 500.0
var floor_accel := 12.0
var air_accel := 7.0
var dir_x := 1

var is_input := true
var joy := Vector2.ZERO
var joy_last := Vector2.ZERO
var joy_clock := Vector2.ZERO
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
var term_vel := 2000.0
export var set_jump := false setget set_jump
export var jump_height := 240.0
export var jump_time := 0.6
export var fall_mult := 2.5
var jump_clock := 0.0
var jump_minimum := 0.05
var air_clock := 0.0
export var coyote_time := 0.125
var last_vel := Vector2.ZERO

var grab = null
var is_grab := false
var grab_ease := EaseMover.new(0.15)
export var grab_length := 200.0
export var throw_vel := -500.0
export var drop_vel := -100.0
export var drop_time := 0.1
var is_lift := false
onready var grab_arm := $Grab
onready var grab_hand := $Grab/Hand
export var lift_pos := Vector2(0, -120)
export var down_pos := Vector2(100, -20)
var lift_from := lift_pos
var lift_to := lift_pos
var lift_ease := EaseMover.new(0.22)
var lift_x := 1.0

onready var arm_l := $Image/ArmL
onready var arm_r := $Image/ArmR
onready var image := $Image
var walk_clock := 0.0
onready var hat := $Image/Head/Hat

var bullet_scene = preload("res://src/actor/Bullet.tscn")
var fire_clock := 0.0
export var fire_rate := 0.25

onready var squish_ease := EaseMover.new(0.4, Vector2.ZERO, Vector2.ONE)
export var jump_squish := Vector2.ONE
export var land_squish := Vector2.ONE
export var duck_squish := Vector2.ONE

export var lift_pre_a := Vector2(-200, 0)
export var lift_post_b := Vector2(0, 200)
export var lift_walk_offset := 25.0


func _enter_tree():
	if Engine.editor_hint: return
	Shared.player = self
	
	get_tree().connect("idle_frame", self, "idle_frame")
	Wipe.connect("start", self, "input_stop")
	Wipe.connect("open", self, "input_start")
	Shared.connect("scene_before", self, "scene_before")
	Shared.connect("scene_after", self, "scene_after")
	Shared.connect("door_open", self, "door_open")

func _exit_tree():
	if Engine.editor_hint: return
	Shared.player = null

func _ready():
	if Engine.editor_hint: return
	
	solve_jump()
	
	UI.debug.track(self, "velocity")
	UI.debug.track(self, "position")
	UI.debug.track(self, "remainder")
	UI.debug.track(self, "has_hit")
	UI.debug.track(self, "is_floor")
	UI.debug.track(self, "is_jump")
	UI.debug.track(self, "joy")
	UI.debug.track(self, "joy_last")
	#UI.debug.track(self, "joy_clock")
	UI.debug.track(self, "dir_x")
	
	Cam.follow(self)
	scene_after()

func _input(event):
	if Engine.editor_hint: return
	
	if event is InputEventKey and event.is_pressed() and !event.is_echo() and event.scancode == KEY_R:
		Wipe.start()

func _physics_process(delta):
	if Engine.editor_hint: return
	
	# input
	joy_last = joy
	if is_input:
		joy = Input.get_vector("left", "right", "up", "down").round()
		btnp_jump = Input.is_action_just_pressed("jump")
		btn_jump = Input.is_action_pressed("jump")
		btnp_shoot = Input.is_action_just_pressed("shoot")
		btn_shoot = Input.is_action_pressed("shoot")
		btnp_grab = Input.is_action_just_pressed("grab")
		btn_grab = Input.is_action_pressed("grab")
	holding_jump = holding_jump + delta if btn_jump else 0.0
	joy_clock.x = joy_clock.x + delta if joy.x == 0 else 0
	joy_clock.y = joy_clock.y + delta if joy.y == 0 else 0
	
	# dir x
	if joy.x != 0:
		dir_x = joy.x
		hat.scale.x = dir_x
	
	# start jump
	if btn_jump and jump_count == 0 and air_clock < coyote_time and holding_jump < holding_limit:
		velocity.y = -jump_speed
		is_jump = true
		jump_clock = 0.0
		jump_count += 1
		squish(jump_squish)
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
	velocity.y = clamp(velocity.y + (jump_gravity if is_jump else fall_gravity) * delta, -term_vel, term_vel)
	
	# movement
	last_vel = velocity
	move(velocity * delta)
	
	# air clock
	air_clock = 0.0 if is_floor else air_clock + delta
	
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
			throw()
	
	if is_grab:
		if position.distance_to(grab.position) > grab_length:
			drop()
		else:
			# arms
			grab_ease.count(delta)
			
			# lift
			#print(abs(grab.position.x - position.x))
			if abs(grab.position.x - position.x) > 50:
				lift_x = -1.0 if grab.position.x < position.x else 1.0
			
			if joy.y == 0:
				var f = lift_ease.frac()
				if f < 0.35 or f > 0.75:
					lift_ease.count(delta * (0.1 if f > 0.5 else 0.15), f > 0.5)
			else:
				if lift_ease.frac() < 0.35 and joy.y == 1:
					lift_x = dir_x
				lift_ease.count(delta, joy.y == 1)
				
				var b = clamp(rad2deg(grab_arm.global_position.angle_to_point(grab.global_position)) - 90, -90, 90)
				var d = lift_ease.time * (abs(b) / 90.0)
				lift_ease.clock = clamp(lift_ease.clock, d - 0.03, d + 0.03)
			
			grab_arm.rotation_degrees = -90 + (lift_ease.frac() * 90.0 * lift_x)
	else:
		var y = 12 * joy.y
		
		arm_l.set_point_position(1, arm_l.get_point_position(1).linear_interpolate(Vector2(-30, y), 20 * delta))
		arm_r.set_point_position(1, arm_r.get_point_position(1).linear_interpolate(Vector2(30, y), 20 * delta))
	
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
	
	# squash n stretch
	if squish_ease.is_less:
		image.scale = squish_ease.move(delta, true, false)
	# spikes
	if is_instance_valid(Shared.spike_map):
		if Shared.spike_map.get_cellv(Shared.spike_map.world_to_map(position - Vector2(0, 30))) > -1:
			die()

func idle_frame():
	# grab
	if is_grab and is_instance_valid(grab):
		arm_l.set_point_position(1, arm_l.get_point_position(1).linear_interpolate(arm_l.to_local(grab.global_position + Vector2(-47, 47)), grab_ease.frac()))
		arm_r.set_point_position(1, arm_r.get_point_position(1).linear_interpolate(arm_r.to_local(grab.global_position + Vector2(47, 47)), grab_ease.frac()))

func squish(_from := Vector2.ONE, _to := Vector2.ONE, _time := squish_ease.time):
	squish_ease.reset(_time)
	squish_ease.from = _from
	squish_ease.to = _to

func hit_floor():
	jump_count = 0
	squish(land_squish)

func set_jump(arg := false):
	set_jump = arg
	solve_jump()

# Sebastian Lague's formula
func solve_jump():
	jump_gravity = (2 * jump_height) / pow(jump_time, 2)
	jump_speed = jump_gravity * jump_time
	fall_gravity = jump_gravity * fall_mult
	print("jump_gravity: ", jump_gravity, " jump_speed: ", jump_speed, " fall_gravity: ", fall_gravity)

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
		grab.grab(self)
		is_grab = true
		grab_ease.reset()
		lift_ease.end()
		lift_x = -1.0 if grab.position.x < position.x else 1.0
		var b = clamp(rad2deg(grab_arm.global_position.angle_to_point(grab.global_position)) - 90, -90, 90)
		lift_ease.clock = lift_ease.time * abs(b / 90.0)

func drop(_vel := Vector2(0, drop_vel)):
	if is_instance_valid(grab):
		grab.drop(_vel)
	grab = null
	is_grab = false

func throw():
	drop(Vector2(velocity.x, lerp(drop_vel, min(throw_vel, velocity.y + drop_vel), abs(velocity.x / walk_speed))) if position.y > grab.position.y + grab.size.y else Vector2(0, drop_vel))

func die():
	drop()
	Wipe.start()

func door_open():
	squish(Vector2.ONE, Vector2.ZERO)

func input_stop():
	is_input = false
	joy = Vector2.ZERO
	btnp_jump = false
	btn_jump = false
	btnp_shoot = false
	btn_shoot = false
	btnp_grab = false
	btn_grab = false

func input_start(arg := null):
	is_input = true

func scene_before():
	drop()

func scene_after():
	position = Shared.door_in.position if is_instance_valid(Shared.door_in) else Shared.doors[0].position if Shared.doors.size() > 0 else position

	# snap to floor
	if check_solid(position + Vector2(0, 50)):
		move(Vector2(0, 50))
	
	squish(Vector2.ZERO, Vector2.ONE)
