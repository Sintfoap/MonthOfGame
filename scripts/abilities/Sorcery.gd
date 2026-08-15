extends Node

## Sorcery: point a catalyst at any IceField in the scene and it ignites --
## no growth animation on this end, unlike the other three schools. The
## spreading *is* the automaton (see IceField.gd), and once lit it runs on
## its own with no further input, matching the design's "self-propagating,
## no upkeep once it catches." There's no un-ignite: this is the one school
## whose effect can't be taken back once cast.


func cast(world_pos: Vector2, _direction: Vector2) -> void:
	for field in get_tree().get_nodes_in_group("ice_field"):
		field.ignite(world_pos)
