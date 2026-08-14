class_name LevelBuilder
extends RefCounted

## Greybox helpers shared by every level script. No art assets yet —
## platforms and triggers are plain colored rectangles until a pixel-art
## pass replaces them.


static func make_platform(parent: Node, pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	var visual := Polygon2D.new()
	visual.color = color
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	visual.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	body.add_child(visual)

	parent.add_child(body)
	return body


static func make_trigger(parent: Node, pos: Vector2, size: Vector2, color: Color, on_enter: Callable) -> Area2D:
	var marker := Polygon2D.new()
	marker.color = color
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	marker.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])
	marker.position = pos
	parent.add_child(marker)

	var area := Area2D.new()
	area.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	# Area2D.body_entered fires for any PhysicsBody2D that overlaps it,
	# including the ground platforms this trigger sits on top of — filter
	# to the player so the trigger doesn't fire itself the instant the
	# level loads.
	area.body_entered.connect(func(body):
		if body is CharacterBody2D:
			on_enter.call(body)
	)
	parent.add_child(area)
	return area
