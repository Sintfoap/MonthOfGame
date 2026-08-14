extends Node2D

## Álfheimr, second gated world. Touching the altar grants Wizardry. A gate
## taller than the max jump blocks the return path; the only way past it is
## reaching the switch on the far side with the mote, which isn't slowed by
## solid geometry the way the player is.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _ready() -> void:
	LevelBuilder.make_platform(self, Vector2(0, 300), Vector2(550, 40), Color(0.16, 0.16, 0.22))

	var gate := LevelBuilder.make_platform(self, Vector2(20, 190), Vector2(16, 180), Color(0.3, 0.27, 0.4))
	LevelBuilder.make_switch(
		self, Vector2(150, 288), Color(0.55, 0.42, 0.78),
		func(): gate.queue_free()
	)

	LevelBuilder.make_trigger(
		self, Vector2(-100, 260), Vector2(32, 60), Color(0.55, 0.42, 0.78, 0.9),
		func(_body): PlayerState.unlock("wizardry")
	)

	LevelBuilder.make_trigger(
		self, Vector2(250, 272), Vector2(48, 16), Color(0.55, 0.42, 0.18, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Midgard.tscn")
	)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(-150, 260)
	add_child(player)
