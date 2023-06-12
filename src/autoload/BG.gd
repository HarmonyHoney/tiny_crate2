extends CanvasLayer

export var pc : PoolColorArray

onready var mat : ShaderMaterial = $ColorRect.material

func custom(col1, col2):
	mat.set_shader_param("c0", col1)
	mat.set_shader_param("c1", col2)

func color(arg := 0):
	var t = arg * 2
	if t + 1 < pc.size():
		mat.set_shader_param("c0", pc[t])
		mat.set_shader_param("c1", pc[t + 1])

func color_lerp(from := 0, to := 1, value := 0.5):
	var f = from * 2
	var t = to * 2
	
	if max(f, t) + 1 < pc.size():
		mat.set_shader_param("c0", pc[f].linear_interpolate(pc[t], value))
		mat.set_shader_param("c1", pc[f + 1].linear_interpolate(pc[t + 1], value))
	
