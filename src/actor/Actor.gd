tool
extends Node2D
class_name Actor

export var size := Vector2.ONE * 50 setget set_size
export var is_draw_size := false setget set_draw

var velocity := Vector2.ZERO
var remainder := Vector2.ZERO

# movement and collision
export var is_moving := false
export var is_solid := false
export var is_colliding := false
var ignore = null

# has moved or hit solid
var has_moved := Vector2.ZERO
var last_move := Vector2.ZERO
var has_hit := Vector2.ZERO

# is on floor and air time
var is_floor := false
var air_frames := 0
var is_water := false
var water_frames := 0
var water_level := 0.0
var water_depth := 0.0
var water_pressure := 0.0
var water_limit := 400

func _enter_tree():
	if Engine.editor_hint: return
	
	Shared.actors.append(self)

func _exit_tree():
	if Engine.editor_hint: return
	
	Shared.actors.erase(self)

func _ready():
	if is_moving:
		UI.debug.track(self, "position")
		UI.debug.track(self, "water_depth")

func _draw():
	if is_draw_size:
		draw_rect(Rect2(-size, size * 2.0), Color(1, 0, 1, 0.5))

func set_draw(arg):
	is_draw_size = arg
	update()
	
func set_size(arg):
	size = arg
	update()

func get_rect() -> Rect2:
	return Rect2(position - size, size * 2.0)

func move(_vel := Vector2.ZERO):
	# setup checks
	has_hit = Vector2.ZERO
	has_moved = Vector2.ZERO
	last_move = position
	
	# move x
	remainder.x += _vel.x
	var dx = round(remainder.x)
	remainder.x -= dx
	if dx != 0:
		move_step(dx)
	
	# move y
	remainder.y += _vel.y
	var dy = round(remainder.y)
	remainder.y -= dy
	if dy != 0:
		move_step(dy, true)
	
	# set floor
	if has_moved.y: is_floor = has_hit.y == 1
	if is_floor:
		if air_frames > 0: hit_floor()
		air_frames = 0
	else: air_frames += 1
	
	# last pos
	last_move = position - last_move
	just_moved()
	
	# water
	is_water = false
	for i in Shared.water_maps:
		if i.get_cellv(i.world_to_map(position)) != -1:
			is_water = true
			if water_frames == 0:
				water_level = stepify(position.y, 100)
				hit_water()
			water_depth = position.y - water_level
			water_pressure = min(water_depth, water_limit)
			break
	water_frames = water_frames + 1 if is_water else 0

# move step by step and check for solids
func move_step(dist : int, is_y := false):
	has_moved += Vector2.DOWN if is_y else Vector2.RIGHT
	if is_colliding:
		var step = sign(dist)
		var vec = Vector2(0, step) if is_y else Vector2(step, 0)
		for i in range(abs(dist)):
			if check_solid(position + vec):
				if is_y:
					velocity.y = 0
					remainder.y = 0
					#print("hit ", "down" if step > 0 else "up")
				else:
					velocity.x = 0
					remainder.x = 0
					#print("hit ", "right" if step > 0 else "left")
				has_hit += vec
				return true
			else:
				position += vec
	else:
		position += Vector2(0, dist) if is_y else Vector2(dist, 0)
	return false

# call after moving
func just_moved():
	pass

# call when hitting floor
func hit_floor():
	print(name, ".air_frames: ", air_frames)

func hit_water():
	print(name, ".air_frames: ", air_frames)

# check area for solid tiles and actors
func check_solid(_pos = position, _size = size):
	if check_solid_tilemap(_pos, _size):
		return true
	return check_solid_actor(_pos, _size)

func check_solid_tilemap(_pos := position, _size = size):
	for i in Shared.solid_maps:
		var tl = i.world_to_map(_pos - (Vector2.ONE * _size))
		
		for y in 2:
			for x in 2:
				var v = Vector2(x, y)
				if i.get_cellv(tl + v) > -1 and Rect2(_pos - _size, _size * 2).intersects(Rect2(i.map_to_world(tl + v), Vector2.ONE * 100)):
					return true
	return false

# check for solid actors
func check_solid_actor(_pos = position, _size = size, _ignore = ignore):
	for a in Shared.actors:
		if a != self and a != _ignore and a.is_solid:
			if Rect2(_pos - _size, _size * 2.0).intersects(a.get_rect()):
				return true
	return false

func get_actor(_group = "", _pos = position, _size = size, _ignore = ignore):
	for a in Shared.actors:
		if a != self and a != _ignore and (_group != "" and a.is_in_group(_group)):
			if Rect2(_pos - _size, _size * 2.0).intersects(a.get_rect()):
				return a
	return null

func get_actors(_group = "", _pos = position, _size = size, _ignore = ignore):
	var act = []
	for a in Shared.actors:
		if a != self and a != _ignore and (_group != "" and a.is_in_group(_group)):
			if Rect2(_pos - _size, _size * 2.0).intersects(a.get_rect()):
				act.append(a)
	return act
