extends Node2D

## One script for every room. Reads a JSON file (data/levels/*.json) and
## builds the scene from it via the same LevelBuilder/Enemy/IceField
## primitives each room used to call directly, hardcoded, in its own
## _ready(). What used to distinguish Midgard.gd from Svartalfheim.gd now
## just lives in which JSON file this instance points at.
##
## Rooms connect to each other through "doors" -- paired directional exits
## (see the doors array below) rather than the plain change_scene triggers
## this used to have. A door names its destination room AND the specific
## door in that room to arrive through, so leaving via the east edge of one
## room lands the player just inside the matching west door of the next,
## not at some unrelated fixed spawn point. RoomTransition.gd carries which
## door was used across the scene reload.
##
## The companion piece is the web-based World Loom designer (see the
## artifact linked from the design conversation) -- it currently edits the
## single-room JSON shape only; door/room-graph editing is a follow-up.

const PLAYER_SCENE := preload("res://scenes/Player.tscn")

@export_file("*.json") var level_path: String = ""

var _gates: Dictionary = {}
var _door_lookup: Dictionary = {}


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

	for d in data.get("doors", []):
		_door_lookup[d["id"]] = d
		_build_door(d)

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

	_spawn_player(data)


func _spawn_player(data: Dictionary) -> void:
	var player := PLAYER_SCENE.instantiate()

	var door_id := RoomTransition.pending_door_id
	RoomTransition.pending_door_id = ""

	if door_id != "" and _door_lookup.has(door_id):
		var door: Dictionary = _door_lookup[door_id]
		var landing: Dictionary = door["landing"]
		player.position = Vector2(landing["x"], landing["y"])
		add_child(player)
		player.set_initial_facing(float(door.get("facing", 1)))
		return

	var spawn: Dictionary = data.get("player_spawn", {"x": 0, "y": 0})
	player.position = Vector2(spawn["x"], spawn["y"])
	add_child(player)


func _build_door(d: Dictionary) -> void:
	var pos := Vector2(d["x"], d["y"])
	var size := Vector2(d["w"], d["h"])
	var color := Color.html(d["color"])
	var target_room: String = d["target_room"]
	var target_door: String = d["target_door"]
	var fired := false
	LevelBuilder.make_trigger(self, pos, size, color, func(_body):
		# Guards against the deferred change_scene_to_file firing more than
		# once if the player's body lingers in the trigger for a couple of
		# physics frames before the scene actually swaps out from under it.
		if fired:
			return
		fired = true
		RoomTransition.go_to(target_room, target_door)
	)


func _build_trigger(t: Dictionary) -> void:
	var pos := Vector2(t["x"], t["y"])
	var size := Vector2(t["w"], t["h"])
	var color := Color.html(t["color"])
	var action: String = t.get("action", "")

	if action == "unlock":
		var ability: String = t["ability"]
		LevelBuilder.make_trigger(self, pos, size, color, func(_body):
			PlayerState.unlock(ability)
		)
