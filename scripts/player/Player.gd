extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 1200.0
const MAX_HEALTH := 3
const INVULNERABLE_TIME := 1.0

signal died

@onready var sprite: Polygon2D = $Sprite
@onready var galdur: Node2D = $GaldurAbility
@onready var smithcraft: Node = $SmithcraftAbility
@onready var wizardry: Node = $WizardryAbility

var health := MAX_HEALTH
var _invulnerable_timer := 0.0


func _ready() -> void:
	collision_layer = LevelBuilder.LAYER_PLAYER
	collision_mask = LevelBuilder.LAYER_WORLD | LevelBuilder.LAYER_ENEMY

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

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0:
			sprite.color = Color(0.86, 0.8, 0.62)


func take_damage(amount: int) -> void:
	if _invulnerable_timer > 0.0:
		return
	health -= amount
	_invulnerable_timer = INVULNERABLE_TIME
	sprite.color = Color(0.9, 0.35, 0.35)
	if health <= 0:
		died.emit()
		# Deferred: this can be called from an Area2D's body_entered, which
		# fires during the physics step -- reloading the scene there would
		# free collision objects mid-physics-callback.
		get_tree().reload_current_scene.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_J:
		var facing := 1.0 if sprite.scale.x >= 0.0 else -1.0
		galdur.cast(facing)
	elif event.keycode == KEY_K and PlayerState.has_smithcraft:
		var facing := 1.0 if sprite.scale.x >= 0.0 else -1.0
		# Offset ahead of and below the player's feet so the seed cell
		# doesn't spawn on top of the player's own collision shape.
		var origin := global_position + Vector2(facing * 24.0, 8.0)
		smithcraft.cast(origin, Vector2(facing, 0.0))
	elif event.keycode == KEY_L and PlayerState.has_wizardry:
		var facing := 1.0 if sprite.scale.x >= 0.0 else -1.0
		wizardry.cast(global_position + Vector2(facing * 24.0, 8.0), Vector2(facing, 0.0))
