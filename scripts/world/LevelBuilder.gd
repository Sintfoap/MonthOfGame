class_name LevelBuilder
extends RefCounted

## Greybox helpers shared by every level script. World geometry (see
## make_platform) is rendered with placeholder pixel-art tiles, tinted per
## call site by the same `color` every caller already passed for the old
## flat-rectangle look -- a ward stays brass, a gate stays purple, ground
## stays dark, no call site needed to change. Trigger markers stay flat
## color rectangles; they're gameplay indicators, not environment art.

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_HAZARD := 8

const TILE_SIZE := 16.0
const BLOCK_TEXTURE := preload("res://assets/placeholder/block.png")


static func make_platform(parent: Node, pos: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	tile_sprites(body, size, color)

	parent.add_child(body)
	return body


## Covers a `size`-shaped area centered on the parent's origin with tiled
## copies of the placeholder block texture, clipping the edge tiles so
## non-16px-multiple sizes (most platforms) get exact pixel coverage
## instead of overhanging past their own collision box.
static func tile_sprites(parent: Node2D, size: Vector2, color: Color) -> void:
	var cols := int(ceil(size.x / TILE_SIZE))
	var rows := int(ceil(size.y / TILE_SIZE))
	var hw := size.x / 2.0
	var hh := size.y / 2.0
	for ry in range(rows):
		for rx in range(cols):
			var tile_w := minf(TILE_SIZE, size.x - rx * TILE_SIZE)
			var tile_h := minf(TILE_SIZE, size.y - ry * TILE_SIZE)
			var sprite := Sprite2D.new()
			sprite.texture = BLOCK_TEXTURE
			sprite.centered = false
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, tile_w, tile_h)
			sprite.position = Vector2(-hw + rx * TILE_SIZE, -hh + ry * TILE_SIZE)
			sprite.modulate = color
			parent.add_child(sprite)


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
	area.collision_layer = 0
	area.collision_mask = LAYER_PLAYER
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	# Belt and suspenders: the mask above already keeps this from seeing
	# anything but the Player layer (the ground platforms this trigger
	# sits on top of included), but the body-type check is what actually
	# caught the original self-firing-on-load bug, so it stays.
	area.body_entered.connect(func(body):
		if body is CharacterBody2D:
			on_enter.call(body)
	)
	parent.add_child(area)
	return area


static func make_switch(parent: Node, pos: Vector2, color: Color, on_trigger: Callable) -> WizardrySwitch:
	var sw := WizardrySwitch.new()
	sw.setup(pos, color)
	sw.triggered.connect(on_trigger)
	parent.add_child(sw)
	return sw
