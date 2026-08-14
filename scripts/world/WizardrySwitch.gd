class_name WizardrySwitch
extends Node2D

## A rune-node that only the Wizardry mote can reach — placed past a gate
## or across a span the player can't walk or jump across. Fires once.

signal triggered

var _fired := false


func setup(pos: Vector2, color: Color) -> void:
	position = pos
	add_to_group("wizardry_switch")

	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	add_child(visual)


func fire() -> void:
	if _fired:
		return
	_fired = true
	triggered.emit()
