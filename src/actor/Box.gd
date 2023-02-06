tool
extends Actor
class_name Box

onready var sprite := $Sprite

export var rise_gravity := 1000.0
export var fall_mult := 2.0
var term_vel := 2000.0

var grab = null
var is_grab := false
var is_drop := false
export var grab_squish := Vector2.ONE * 0.8
export var grab_speed := 20.0
export var below_speed := 8.0
var grab_ease := EaseMover.new(0.2, grab_squish, Vector2.ONE)

export var snap_squish := Vector2.ONE * 0.9
var snap_ease := EaseMover.new(0.2)
export var snap_time := 0.2

export var is_sticky := false
var is_stuck := false

var carrying := 0

func _ready():
	if Engine.editor_hint: return
	
	if is_sticky:
		sprite.modulate = Color(0,1.45,0,1)

func _physics_process(delta):
	if Engine.editor_hint: return
	
	var a = get_actor("box", position + Vector2(0, 5))
	#if !is_grab and a and a.velocity.y < 1 : return
	
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
		var c = connected()
		var above = 0
		var below = 0
		
		var p = []
		var my = stepify(position.y, 50)
		for i in c:
			var y = stepify(i.position.y, 50)
			if !p.has(y):
				p.append(y)
				if y < my: above += 1
				elif y > my: below += 1
		carrying = above - below
		
		var w = false
		for i in c:
			if i.is_water:
				w = true
				break
		
		if is_water or (w and velocity.y == 0.0):
			velocity.x = lerp(velocity.x, 0.0, delta * 4.0)
			if velocity.y > 1.0:
				velocity.y = lerp(velocity.y, 0.0, delta * 10.0)
				if velocity.y < 1.0:
					snap()
			else:
				move(Vector2(0, clamp((water_level + (carrying * 50.0)) - position.y, -5, 5)))
				#velocity.y = water_level - position.y
			
		else:
			velocity.y = clamp(velocity.y + rise_gravity * (fall_mult if velocity.y > 0.0 else 1.0) * delta, -term_vel, term_vel)
		
		$Debug/Label.text = str(velocity.x) + "\n" + str(round(velocity.y)) + "\nab:" + str(above) + ", " + str(below) + "\nc:" + str(carrying)
		
		# move
		if velocity != Vector2.ZERO:
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
	snap()
#	velocity.x = 0
#	if is_drop:
#		is_drop = false
#		snap()

func hit_water():
	pass#snap()

func grab(other):
	print(name, " grab")
	grab = other
	is_grab = true
	is_stuck = false
	grab_ease.reset()
	snap_ease.end()
	sprite.position = Vector2.ZERO

func drop(_vel := Vector2.ZERO):
	velocity = _vel
	is_drop = true
	grab = null
	is_grab = false
	is_floor = false
	grab_ease.reset()
	snap_ease.end()
	print(name, " drop / pos: ", position)

func snap(_pos := position, is_y := false):
	var last_pos = position
	var p = Vector2(_pos.x if is_y else stepify(_pos.x, 25), stepify(_pos.y, 0) if is_y else _pos.y)
	
	if check_solid(p):
		_pos += position - last_pos
		p = Vector2(_pos.x if is_y else stepify(_pos.x, 25), stepify(_pos.y, 0) if is_y else _pos.y)
	
	if !check_solid(p):
		position = p
		sprite.position = last_pos - position
		snap_ease.from = sprite.position
		print(name, " snapped ", sprite.position, " to ", position)
		
		velocity = Vector2.ZERO
		snap_ease.reset(snap_time)

func connected(a := [self], vec = Vector2(0, 40), step = 0):
	for i in get_actors("box", position, size + vec):
		if !a.has(i) and !i.is_grab:
			a.append(i)
			i.connected(a, vec, step + 1)
	return a

