extends TileMap

func _enter_tree():
	if Engine.editor_hint: return
	Shared.spike_map = self

func _ready():
	for i in get_used_cells():
		set_cellv(i + Vector2(0, 1), 1)
