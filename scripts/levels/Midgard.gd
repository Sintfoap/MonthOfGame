extends Node2D

## Hub world. The player starts here with Galdur only. A 300px gap blocks
## the rest of Midgard — too wide to jump (max jump carries ~155px), and
## a single Galdur ward isn't wide enough alone. It's meant to send the
## player down into Svartalfheim first to learn Smithcraft, then back here
## to grow a permanent crystal bridge across. Once across, a trigger on the
## far platform leads to Alfheim to learn Wizardry — but a patrolling enemy
## sits between the bridge landing and that trigger. It's solid on the same
## World layer as a Galdur ward, so casting one in its path blocks it like
## any wall.
##
## Past the Alfheim trigger, a third platform holds a gate only Wizardry
## can open (same gate-plus-switch pattern as Alfheim itself) leading to
## Muspelheim. World-entry triggers are one-shot: without that, walking
## back past the Alfheim trigger to reach this third platform would just
## pull the player into Alfheim again every time.
##
## Reaching Muspelheim requires a round trip through Alfheim first (to get
## Wizardry), and every scene change tears down and rebuilds the level from
## scratch -- without restoring it, a Smithcraft bridge built before that
## trip would already be gone by the time the player got back. Restored
## from WorldState instead of being rebuilt from scratch.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func _ready() -> void:
	LevelBuilder.make_platform(self, Vector2(0, 300), Vector2(300, 40), Color(0.18, 0.16, 0.24))
	LevelBuilder.make_platform(self, Vector2(600, 300), Vector2(300, 40), Color(0.18, 0.16, 0.24))
	LevelBuilder.make_platform(self, Vector2(1050, 300), Vector2(600, 40), Color(0.18, 0.16, 0.24))

	for cell in WorldState.get_crystals("Midgard"):
		CrystalCell.spawn_at(self, cell, 16.0)

	var svartalfheim_entered := false
	LevelBuilder.make_trigger(
		self, Vector2(-100, 272), Vector2(48, 16), Color(0.55, 0.42, 0.18, 0.6),
		func(_body):
			if svartalfheim_entered:
				return
			svartalfheim_entered = true
			get_tree().change_scene_to_file.call_deferred("res://scenes/Svartalfheim.tscn")
	)

	var alfheim_entered := false
	LevelBuilder.make_trigger(
		self, Vector2(700, 272), Vector2(48, 16), Color(0.55, 0.42, 0.78, 0.6),
		func(_body):
			if alfheim_entered:
				return
			alfheim_entered = true
			get_tree().change_scene_to_file.call_deferred("res://scenes/Alfheim.tscn")
	)

	var patroller := Enemy.new()
	patroller.position = Vector2(560, 280)
	patroller.setup(480.0, 650.0)
	add_child(patroller)

	var gate := LevelBuilder.make_platform(self, Vector2(820, 190), Vector2(16, 180), Color(0.3, 0.27, 0.4))
	LevelBuilder.make_switch(
		self, Vector2(950, 288), Color(0.82, 0.42, 0.24),
		func(): gate.queue_free()
	)
	LevelBuilder.make_trigger(
		self, Vector2(1200, 272), Vector2(48, 16), Color(0.82, 0.42, 0.24, 0.6),
		func(_body): get_tree().change_scene_to_file.call_deferred("res://scenes/Muspelheim.tscn")
	)

	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(0, 260)
	add_child(player)
