extends Node2D

## One script for every level. Reads a JSON file (data/levels/*.json) and
## builds the scene from it via the same LevelBuilder/Enemy/IceField
## primitives each level used to call directly, hardcoded, in its own
## _ready(). What used to distinguish Midgard.gd from Svartalfheim.gd now
## just lives in which JSON file this instance points at.
##
## The companion piece is the web-based World Loom designer (see the
## artifact linked from the design conversation) -- it edits this exact
## JSON shape, including loading the game's actual current levels to start
## from rather than a blank canvas.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

@export_file("*.json") var level_path: String = ""

var _gates: Dictionary = {}


func _ready() -> void:
	var text := FileAccess.get_file_as_string(level_path)
	var data = JSON.parse_string(text)
	if data == null:
		push_error("LevelLoader: failed to parse %s" % level_path)
		return

	var level_name: String = data.get("name", name)

	for p in data.get("platforms", []):
		LevelBuilder.make_platform(
			self, Vector2(p["x"], p["y"]), Vector2(p["w"], p["h"]), Color.html(p["color"])
		)

	for cell in WorldState.get_crystals(data.get("crystal_persist_key", level_name)):
		CrystalCell.spawn_at(self, cell, 16.0)

	for g in data.get("gates", []):
		var gate := LevelBuilder.make_platform(
			self, Vector2(g["x"], g["y"]), Vector2(g["w"], g["h"]), Color.html(g["color"])
		)
		_gates[g["id"]] = gate

	for s in data.get("switches", []):
		var gate_id: String = s["opens_gate"]
		LevelBuilder.make_switch(
			self, Vector2(s["x"], s["y"]), Color.html(s["color"]),
			func():
				if _gates.has(gate_id) and is_instance_valid(_gates[gate_id]):
					_gates[gate_id].queue_free()
		)

	for t in data.get("triggers", []):
		_build_trigger(t)

	for e in data.get("enemies", []):
		var enemy := Enemy.new()
		enemy.position = Vector2(e["x"], e["y"])
		enemy.setup(e["patrol_min"], e["patrol_max"])
		add_child(enemy)

	for f in data.get("ice_fields", []):
		var field := IceField.new()
		field.position = Vector2(f["x"], f["y"])
		field.setup(f["cols"], f["rows"])
		add_child(field)

	var spawn: Dictionary = data.get("player_spawn", {"x": 0, "y": 0})
	var player := PLAYER_SCENE.instantiate()
	player.position = Vector2(spawn["x"], spawn["y"])
	add_child(player)


func _build_trigger(t: Dictionary) -> void:
	var pos := Vector2(t["x"], t["y"])
	var size := Vector2(t["w"], t["h"])
	var color := Color.html(t["color"])
	var action: String = t.get("action", "")

	if action == "change_scene":
		var scene_name: String = t["scene"]
		var one_shot: bool = t.get("one_shot", false)
		var fired := false
		LevelBuilder.make_trigger(self, pos, size, color, func(_body):
			if one_shot:
				if fired:
					return
				fired = true
			get_tree().change_scene_to_file.call_deferred("res://scenes/%s.tscn" % scene_name)
		)
	elif action == "unlock":
		var ability: String = t["ability"]
		LevelBuilder.make_trigger(self, pos, size, color, func(_body):
			PlayerState.unlock(ability)
		)
