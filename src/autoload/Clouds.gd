extends Node2D

export var wind_speed := 1.0
export var wind_dir := 1.0
export var puff_range := Vector2(0.5, 1.5)
export var clouds_per_thousand := 25

export var parallax_scale := 1.0

var puff
onready var list_node := $List

func _ready():
	puff = $Puff.duplicate()
	$Puff.visible = false
	fill()
	get_tree().connect("idle_frame", self, "idle_frame")

func _input(event):
	if event is InputEventKey and event.scancode == KEY_P and event.is_pressed() and !event.is_echo():
		#create_cloud(Shared.player.position - list_node.position, 2 + (randi() % 3))
		clear()

func _physics_process(delta):
	#list_node.offset += Vector2(wind_speed * wind_dir * delta, 0)
	pass

func idle_frame():
	list_node.offset = Cam.position * parallax_scale

func clear():
	list_node.offset = Vector2.ZERO
	for i in list_node.get_children():
		i.queue_free()
	fill()

func fill():
	randomize()
	
	if Shared.solid_maps.size() == 0: return
	
	var rect : Rect2 = Shared.solid_maps[0].get_used_rect()
	rect = rect.grow(10.0)
	var count = (rect.get_area() / 1000.0) * clouds_per_thousand
	
	for i in count:
		var v = Vector2(rect.position.x + rand_range(0, rect.size.x), rect.position.y + rand_range(0, rect.size.y)) 
		create_cloud(v * 100, 2 + (randi() % 3))

func create_cloud(_pos := Vector2.ZERO, _puffs := 3):
	var last = null
	var ang = randf() * TAU
	var s = 1.0 if randf() > 0.5 else -1.0
	
	for i in _puffs:
		var p = puff.duplicate()
		var check = (_puffs > 2 or randf() > 0.5) and i % (_puffs - 1) == 0
		var mid = lerp(puff_range.x, puff_range.y, 0.5)
		var r = lerp(mid, puff_range.x if check else puff_range.y, randf())
		
		p.scale = Vector2.ONE * r
		
		if is_instance_valid(last):
			p.position = last.position
			
			if randf() > 0.75: s = -s
			
			ang += deg2rad(rand_range(15, 90)) * s
			p.position += Vector2(max(last.scale.x, p.scale.x) * 50.0, 0).rotated(ang)
		else:
			p.position = _pos
		
		list_node.add_child(p)
		last = p
