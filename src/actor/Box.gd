tool
extends Actor
class_name Box

onready var sprite := $Sprite

export var rise_gravity := 1000.0
export var fall_gravity := 2000.0
var term_vel := 2000.0

var grab = null
var is_grab := false
export var grab_squish := Vector2.ONE * 0.8
export var grab_speed := 20.0
export var below_speed := 8.0
var grab_ease := EaseMover.new(0.2, grab_squish, Vector2.ONE)

export var snap_squish := Vector2.ONE * 0.9
var snap_ease := EaseMover.new(0.2)
export var snap_time := 0.2

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
	# grab
	if is_grab:
		if is_instance_valid(grab) and grab.grab_ease.is_complete and (grab.position.y > position.y - size.y or (grab.is_floor and grab.get_actor("box", grab.position + Vector2(0, 1)) != self)):
			var li = position.linear_interpolate(grab.grab_hand.global_position.round(), (grab_speed if grab.position.y > position.y - size.y else below_speed) * delta)
			move(li - position)
	# snap
	elif snap_ease.is_less:
		sprite.position = snap_ease.move(delta, true)
		sprite.scale = snap_ease.elerp(true, snap_squish, Vector2.ONE)
		
		if snap_ease.is_complete:
			is_floor = check_solid(position + Vector2(0, 1))
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
	print(name, " grab")

func drop(_vel := Vector2.ZERO):
	velocity = _vel
	grab = null
	is_grab = false
	is_floor = false
	grab_ease.reset()
	print(name, " drop / pos: ", position)

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

