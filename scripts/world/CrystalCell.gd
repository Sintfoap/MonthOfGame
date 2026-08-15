class_name CrystalCell
extends StaticBody2D

## One cell of a Smithcraft vein. Spawned at runtime by the diffusion-limited
## aggregation in Smithcraft.gd — never placed by hand.


static func spawn_at(parent: Node, cell: Vector2i, cell_size: float) -> CrystalCell:
	var body := CrystalCell.new()
	body.position = Vector2(cell.x * cell_size, cell.y * cell_size)
	body.setup(cell_size)
	parent.add_child(body)
	return body


func setup(cell_size: float) -> void:
	collision_layer = LevelBuilder.LAYER_WORLD
	collision_mask = 0

	var shape := RectangleShape2D.new()
	shape.size = Vector2(cell_size, cell_size)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	LevelBuilder.tile_sprites(self, Vector2(cell_size, cell_size), Color(0.24, 0.52, 0.47))
