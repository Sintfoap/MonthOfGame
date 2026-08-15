extends CharacterBody2D

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 1200.0
const MAX_HEALTH := 3
const INVULNERABLE_TIME := 1.0
const WALK_FRAME_TIME := 0.2

const IDLE_TEXTURE := preload("res://assets/placeholder/player_idle.png")
const WALK_TEXTURE := preload("res://assets/placeholder/player_walk.png")
const NORMAL_TINT := Color(1, 1, 1)
const HURT_TINT := Color(1, 0.5, 0.5)

signal died

@onready var sprite: Sprite2D = $Sprite
@onready var galdur: Node2D = $GaldurAbility
@onready var smithcraft: Node = $SmithcraftAbility
@onready var wizardry: Node = $WizardryAbility
@onready var sorcery: Node = $SorceryAbility

var health := MAX_HEALTH
var _invulnerable_timer := 0.0
var _facing := 1.0
var _walk_timer := 0.0
var _walk_frame := false


func _ready() -> void:
	collision_layer = LevelBuilder.LAYER_PLAYER
	collision_mask = LevelBuilder.LAYER_WORLD | LevelBuilder.LAYER_ENEMY

	sprite.texture = IDLE_TEXTURE
	sprite.position = Vector2(0, -20)


## Called by LevelLoader right after add_child(), when the player arrives
## through a specific door rather than a room's default player_spawn --
## faces them the way that door's JSON says they should land.
func set_initial_facing(f: float) -> void:
	_facing = f
	sprite.flip_h = _facing < 0.0


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
		_facing = 1.0 if direction > 0.0 else -1.0
		sprite.flip_h = _facing < 0.0
		_walk_timer += delta
		if _walk_timer >= WALK_FRAME_TIME:
			_walk_timer = 0.0
			_walk_frame = not _walk_frame
			sprite.texture = WALK_TEXTURE if _walk_frame else IDLE_TEXTURE
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		_walk_timer = 0.0
		_walk_frame = false
		sprite.texture = IDLE_TEXTURE

	move_and_slide()

	if _invulnerable_timer > 0.0:
		_invulnerable_timer -= delta
		if _invulnerable_timer <= 0.0:
			sprite.modulate = NORMAL_TINT


func take_damage(amount: int) -> void:
	if _invulnerable_timer > 0.0:
		return
	health -= amount
	_invulnerable_timer = INVULNERABLE_TIME
	sprite.modulate = HURT_TINT
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
		galdur.cast(_facing)
	elif event.keycode == KEY_K and PlayerState.has_smithcraft:
		# Offset ahead of and below the player's feet so the seed cell
		# doesn't spawn on top of the player's own collision shape.
		var origin := global_position + Vector2(_facing * 24.0, 8.0)
		smithcraft.cast(origin, Vector2(_facing, 0.0))
	elif event.keycode == KEY_L and PlayerState.has_wizardry:
		wizardry.cast(global_position + Vector2(_facing * 24.0, 8.0), Vector2(_facing, 0.0))
	elif event.keycode == KEY_M and PlayerState.has_sorcery:
		sorcery.cast(global_position + Vector2(_facing * 24.0, 8.0), Vector2(_facing, 0.0))
