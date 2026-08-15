extends Node2D

## Múspellsheimr, third gated world. Touching the altar grants Sorcery. An
## IceField blocks the return path -- unlike Smithcraft's gate or
## Wizardry's, there's no walking around or bridging it. It has to be
## melted, and once melted it stays melted; this is the one school with no
## way to undo its own effect.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _ready() -> void:
	LevelBuilder.make_platform(self, Vector2(0, 300), Vector2(600, 40), Color(0.2, 0.13, 0.13))

	LevelBuilder.make_trigger(
		self, Vector2(-120, 260), Vector2(32, 60), Color(0.82, 0.42, 0.24, 0.9),
		func(_body): PlayerState.unlock("sorcery")
	)

	var field := IceField.new()
	field.position = Vector2(100, 280 - 8 * 16.0)
	field.setup(6, 8)  # 96px wide, 128px tall -- clears the ~73px max jump
	add_child(field)

	LevelBuilder.make_trigger(
		self, Vector2(280, 272), Vector2(48, 16), Color(0.55, 0.42, 0.18, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Midgard.tscn")
	)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(-200, 260)
	add_child(player)
