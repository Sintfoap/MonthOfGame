extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 1200.0

@onready var sprite: Polygon2D = $Sprite
@onready var galdur: Node2D = $GaldurAbility
@onready var smithcraft: Node = $SmithcraftAbility


func _ready() -> void:
	sprite.color = Color(0.86, 0.8, 0.62)
	sprite.polygon = PackedVector2Array([
		Vector2(-12, -40), Vector2(12, -40), Vector2(12, 0), Vector2(-12, 0)
	])


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		sprite.scale.x = 1.0 if direction > 0.0 else -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_J:
		galdur.cast()
	elif event.keycode == KEY_K and PlayerState.has_smithcraft:
		var facing := 1.0 if sprite.scale.x >= 0.0 else -1.0
		smithcraft.cast(global_position, Vector2(facing, 0.0))
