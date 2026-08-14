class_name WizardryBeam
extends Node2D

## Visual trail for a Wizardry cast. Lives at the world root (not on the
## player) so it stays put in world space as the mote travels, instead of
## dragging along with whatever the caster does next.

const CELL_SIZE := 16.0

var trail: Array = []


func _draw() -> void:
	for cell in trail:
		var p: Vector2 = Vector2(cell.x, cell.y) * CELL_SIZE
		draw_circle(p, 2.5, Color(0.55, 0.42, 0.78, 0.85))
