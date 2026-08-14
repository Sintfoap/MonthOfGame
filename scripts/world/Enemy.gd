class_name Enemy
extends CharacterBody2D

## A simple ground patroller. Deals contact damage through a Hazard-layer
## hitbox, and is physically solid on the World layer — which means a
## Galdur ward (also World-layer) blocks its patrol like any other wall.
## That's the ward's combat use: cast one in an enemy's path and it has to
## stop or turn around, same as hitting the edge of a platform.

const SPEED := 60.0
const GRAVITY := 1200.0
const DAMAGE := 1
const HIT_COOLDOWN := 0.6

var _dir := -1.0
var _patrol_min := 0.0
var _patrol_max := 0.0
var _hit_timer := 0.0


func setup(patrol_min: float, patrol_max: float) -> void:
	_patrol_min = patrol_min
	_patrol_max = patrol_max
	collision_layer = LevelBuilder.LAYER_ENEMY
	collision_mask = LevelBuilder.LAYER_WORLD

	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 28)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -14)
	add_child(collision)

	var visual := Polygon2D.new()
	visual.color = Color(0.62, 0.22, 0.24)
	visual.polygon = PackedVector2Array([
		Vector2(-10, -28), Vector2(10, -28), Vector2(10, 0), Vector2(-10, 0)
	])
	add_child(visual)

	var hitbox := Area2D.new()
	hitbox.collision_layer = LevelBuilder.LAYER_HAZARD
	hitbox.collision_mask = LevelBuilder.LAYER_PLAYER
	var hshape := RectangleShape2D.new()
	hshape.size = Vector2(24, 32)
	var hcollision := CollisionShape2D.new()
	hcollision.shape = hshape
	hcollision.position = Vector2(0, -14)
	hitbox.add_child(hcollision)
	hitbox.body_entered.connect(_on_hitbox_entered)
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = _dir * SPEED

	if global_position.x <= _patrol_min:
		_dir = 1.0
	elif global_position.x >= _patrol_max:
		_dir = -1.0

	move_and_slide()

	# A ward or wall stopped forward motion -- turn around instead of
	# pressing uselessly against it.
	if is_on_wall():
		_dir = -_dir

	if _hit_timer > 0.0:
		_hit_timer -= delta


func _on_hitbox_entered(body: Node) -> void:
	if _hit_timer > 0.0:
		return
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		_hit_timer = HIT_COOLDOWN
