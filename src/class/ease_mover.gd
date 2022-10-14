class_name EaseMover

var clock := 0.0
var time := 0.5
var from := Vector2.ZERO
var to := Vector2.ZERO

var is_complete setget , get_complete
var is_less setget , get_less

func _init(_time := time, _from := from, _to := to):
	time = _time
	from = _from
	to = _to

func frac():
	return clock / time

func smooth():
	return smoothstep(0, 1, clock / time)

func count(delta, is_show := true, is_smooth := true):
	clock = clamp(clock + (delta if is_show else -delta), 0, time)
	return smooth() if is_smooth else frac()

func reset(_time := time):
	clock = 0.0
	time = _time

func end():
	clock = time

func get_less():
	return clock < time

func get_complete():
	return clock == time

func elerp(is_smooth := true, _from := from, _to := to):
	return _from.linear_interpolate(_to, smoothstep(0, 1, clock / time) if is_smooth else (clock / time))

func move(delta, is_show := true, is_smooth := true):
	count(delta, is_show)
	return elerp(is_smooth)
