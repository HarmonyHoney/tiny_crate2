tool
extends Actor
class_name Box

onready var sprite := $Sprite

export var rise_gravity := 1000.0
export var fall_gravity := 2000.0
var term_vel := 2000.0

var grab = null
var is_grab := false
export var grab_speed := Vector2(20, 20)
export var grab_squish := Vector2.ONE * 0.8
var grab_ease := EaseMover.new(0.2, grab_squish, Vector2.ONE)

export var snap_squish := Vector2.ONE * 0.9
var snap_ease := EaseMover.new(0.2)
export var snap_time := 0.2
export var push_time := 0.1
var is_push := false

export var is_sticky := false
var is_stuck := false

func _ready():
	if Engine.editor_hint: return
	
	UI.debug.track(self, "position")
	
	if is_sticky:
		sprite.modulate = Color(0,1.45,0,1)

func _physics_process(delta):
	if Engine.editor_hint: return
	
	# grab squish
	if grab_ease.is_less:
		sprite.scale = grab_ease.move(delta)
	
	# snap or push
	if snap_ease.is_less:
		sprite.position = snap_ease.move(delta, true, !is_push)
		sprite.scale = snap_ease.elerp(true, snap_squish, Vector2.ONE) if !is_push else Vector2.ONE
		
		if snap_ease.is_complete:
			is_push = false
			is_floor = check_solid(position + Vector2(0, 1))
	# grab
	elif is_grab:
		if is_instance_valid(grab) and grab.grab_ease.is_complete and (grab.position.y > position.y - size.y or (grab.is_floor and grab.get_actor("box", grab.position + Vector2(0, 1)) != self)):
			var p = grab.grab_node.global_position
			var li = Vector2(lerp(position.x, p.x, grab_speed.x * delta), lerp(position.y, p.y, grab_speed.y * delta))
			move(li - position)
	# sticky
	elif is_stuck:
		pass
	# move
	else:
		# gravity
		velocity.y = clamp(velocity.y + (fall_gravity if velocity.y > 0.0 else rise_gravity) * delta, -term_vel, term_vel)
		
		# move
		move(velocity * delta)

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

func grab(other):
	grab = other
	is_grab = true
	is_stuck = false
	grab_ease.reset()
	print("grab: ", name)

func drop(_vel := Vector2.ZERO):
	velocity = _vel
	grab = null
	is_grab = false
	is_floor = false
	grab_ease.reset()
	print("drop: ", name, " pos: ", position)

func snap(_pos := position, is_y := false):
	var last_pos = position
	var p = Vector2(_pos.x if is_y else stepify(_pos.x, 25), stepify(_pos.y, 25) if is_y else _pos.y)
	
	if check_solid(p):
		_pos += position - last_pos
		p = Vector2(_pos.x if is_y else stepify(_pos.x, 25), stepify(_pos.y, 25) if is_y else _pos.y)
	
	if !check_solid(p):
		position = p
		sprite.position = last_pos - position
		snap_ease.from = sprite.position
		print(name, " snapped ", sprite.position, " to ", position)
		
		velocity = Vector2.ZERO
		snap_ease.reset(snap_time)
		is_push = false

func push(dir_x := 1.0):
	if !is_push and is_floor:
		var v = Vector2(dir_x * 25, 0)
		
		var pb = get_actor("box", position + Vector2(dir_x, 0))
		if is_instance_valid(pb):
			pb.push(dir_x)
		
		var cs = check_solid(position + v)
		if !cs:
			# bring above
			for a in get_actors("box", position + Vector2(0, -1)):
				a.push(dir_x)
			
			snap(position + v)
			snap_ease.reset(push_time)
			is_push = true
