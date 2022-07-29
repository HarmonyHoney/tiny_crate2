extends TileMap


func _enter_tree():
	Shared.solid_maps.append(self)

func _exit_tree():
	Shared.solid_maps.erase(self)
