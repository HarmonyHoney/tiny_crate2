extends TileMap

func _enter_tree():
	if Engine.editor_hint: return
	Shared.spike_map = self
