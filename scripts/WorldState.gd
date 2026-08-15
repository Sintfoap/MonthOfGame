extends Node

## Autoload singleton. Persists player-built structures across scene
## reloads within a single play session (in memory only -- there's still
## no save-to-disk system). Without this, `change_scene_to_file` tearing
## down the previous scene on every transition meant a Smithcraft bridge
## in Midgard vanished the instant the player stepped into any side world
## and came back, forcing it to be rebuilt from scratch every time.

var crystal_cells: Dictionary = {}  # level_name (String) -> Array[Vector2i]


func record_crystal(level_name: String, cell: Vector2i) -> void:
	if not crystal_cells.has(level_name):
		crystal_cells[level_name] = []
	if not crystal_cells[level_name].has(cell):
		crystal_cells[level_name].append(cell)


func get_crystals(level_name: String) -> Array:
	return crystal_cells.get(level_name, [])
