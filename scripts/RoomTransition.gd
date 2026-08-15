extends Node

## Autoload. Carries "which door did the player just walk through" across a
## change_scene_to_file call, since that call frees the entire previous
## scene tree -- there's no other channel for the destination room to learn
## where in itself the player should land.
##
## Consumed once: LevelLoader clears pending_door_id the instant it reads
## it, so a later reload_current_scene() (player death, for instance) falls
## back to the room's default player_spawn instead of replaying a stale
## door id from whatever the player last walked through before dying.

var pending_door_id: String = ""


func go_to(target_scene: String, target_door_id: String) -> void:
	pending_door_id = target_door_id
	get_tree().change_scene_to_file.call_deferred("res://scenes/%s.tscn" % target_scene)
