class_name CrystalCell
extends StaticBody2D

## One cell of a Smithcraft vein. Spawned at runtime by the diffusion-limited
## aggregation in Smithcraft.gd — never placed by hand.


func setup(cell_size: float) -> void:
	collision_layer = LevelBuilder.LAYER_WORLD
	collision_mask = 0

	var shape := RectangleShape2D.new()
	shape.size = Vector2(cell_size, cell_size)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var visual := Polygon2D.new()
	visual.color = Color(0.24, 0.52, 0.47)
	var h := cell_size / 2.0
	visual.polygon = PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)
	])
	add_child(visual)
