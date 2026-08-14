extends Node2D

## Hub world. The player starts here with Galdur only. A 300px gap blocks
## the rest of Midgard — too wide to jump (max jump carries ~155px), and
## a single Galdur ward isn't wide enough alone. It's meant to send the
## player down into Svartalfheim first to learn Smithcraft, then back here
## to grow a permanent crystal bridge across. Once across, a second trigger
## on the far platform leads to Alfheim to learn Wizardry — but a patrolling
## enemy sits between the bridge landing and that trigger. It's solid on
## the same World layer as a Galdur ward, so casting one in its path blocks
## it like any wall.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _ready() -> void:
	LevelBuilder.make_platform(self, Vector2(0, 300), Vector2(300, 40), Color(0.18, 0.16, 0.24))
	LevelBuilder.make_platform(self, Vector2(600, 300), Vector2(300, 40), Color(0.18, 0.16, 0.24))

	LevelBuilder.make_trigger(
		self, Vector2(-100, 272), Vector2(48, 16), Color(0.55, 0.42, 0.18, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Svartalfheim.tscn")
	)

	LevelBuilder.make_trigger(
		self, Vector2(700, 272), Vector2(48, 16), Color(0.55, 0.42, 0.78, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Alfheim.tscn")
	)

	var patroller := Enemy.new()
	patroller.position = Vector2(560, 280)
	patroller.setup(480.0, 650.0)
	add_child(patroller)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(0, 260)
	add_child(player)
