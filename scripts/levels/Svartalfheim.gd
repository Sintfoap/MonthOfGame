extends Node2D

## Svartalfheim, first gated world. Touching the altar grants Smithcraft;
## the trigger on the far side sends the player back up to Midgard to put
## it to use on the gap they couldn't cross before.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _ready() -> void:
	LevelBuilder.make_platform(self, Vector2(0, 300), Vector2(500, 40), Color(0.12, 0.19, 0.18))

	LevelBuilder.make_trigger(
		self, Vector2(200, 260), Vector2(32, 60), Color(0.37, 0.63, 0.58, 0.9),
		func(_body): PlayerState.unlock("smithcraft")
	)

	LevelBuilder.make_trigger(
		self, Vector2(-220, 272), Vector2(48, 16), Color(0.55, 0.42, 0.18, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Midgard.tscn")
	)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(0, 260)
	add_child(player)
