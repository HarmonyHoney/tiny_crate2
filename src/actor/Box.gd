tool
extends Actor
class_name Box

onready var sprite := $Sprite

export var rise_gravity := 1000.0
export var fall_gravity := 1000.0

var grab = null
var grab_x := 1
var is_grab := false
var is_grab_squish := false
var grab_ease := EaseMover.new(0.2)
export var grab_speed := Vector2(16, 20)
export var grab_squish := Vector2.ONE * 0.8

var is_snap := false
var snap_ease := EaseMover.new(0.2)
var snap_from := Vector2.ZERO
export var snap_squish := Vector2.ONE * 0.9

var is_push := false
var push_ease := EaseMover.new(0.1)

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
	if is_grab_squish:
		grab_ease.count(delta)
		
		sprite.scale = grab_squish.linear_interpolate(Vector2.ONE, grab_ease.smooth())
		
		if grab_ease.is_complete:
			is_grab_squish = false
	
	# snap or push
	if is_snap or is_push:
		var e = snap_ease if is_snap else push_ease
		e.count(delta)
		
		sprite.position = snap_from.linear_interpolate(Vector2.ZERO, e.smooth() if is_snap else e.frac())
		if is_snap:
			sprite.scale = snap_squish.linear_interpolate(Vector2.ONE, e.smooth())
		
		if e.is_complete:
			is_snap = false
			is_push = false
			is_floor = check_solid(position + Vector2(0, 1))
	# grab
	elif is_grab:
		if is_instance_valid(grab) and grab.grab_ease.is_complete and (grab.position.y > position.y - size.y or (grab.is_floor and grab.get_actor("box", grab.position + Vector2(0, 1)) != self)):
			#var p = grab.position + Vector2(0, -120)
			var p = grab.grab_node.global_position
			var li = Vector2(lerp(position.x, p.x, grab_speed.x * delta), lerp(position.y, p.y, grab_speed.y * delta))
			move(li - position)
	# sticky
	elif is_stuck:
		pass
	# move
	else:
		# gravity
		velocity.y += (fall_gravity if velocity.y > 0.0 else rise_gravity) * delta
		
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

func grab(other, dir_x):
	grab_x = dir_x
	is_grab = true
	is_grab_squish = true
	grab_ease.reset()
	grab = other
	is_stuck = false
	print("grab: ", name)

func drop(_vel := Vector2.ZERO):
	is_grab = false
	is_floor = false
	is_grab_squish = true
	grab_ease.reset()
	
	if grab.position.y > position.y + size.y:
		velocity = _vel
	
	grab = null
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
		snap_from = sprite.position
		
		velocity = Vector2.ZERO
		is_snap = true
		snap_ease.reset()
		print(name, " snapped ", sprite.position, " to ", position)

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
			is_snap = false
			is_push = true
			push_ease.reset()
