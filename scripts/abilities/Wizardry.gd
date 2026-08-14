extends Node

## Wizardry: a mobile automaton (turmite), like the prototype's Wandering
## Mote. The mote marks each cell it crosses; landing on an already-marked
## cell is the only thing that turns it. In practice that means it travels
## in a precise straight line through open lattice — the "exact,
## controllable" wand of the six schools — and would only spiral once it
## crossed its own path. Reaching a WizardrySwitch fires it.

const CELL_SIZE := 16.0
const MAX_STEPS := 60
const STEP_INTERVAL := 0.015
const TRIGGER_RADIUS := 10.0

var _marks := {}
var _pos := Vector2i.ZERO
var _dir := Vector2i.ZERO
var _steps := 0
var _active := false
var _timer := 0.0
var _beam: WizardryBeam = null


func cast(world_pos: Vector2, direction: Vector2) -> void:
	if _active:
		return
	_marks.clear()
	_pos = _to_grid(world_pos)
	_dir = Vector2i(sign(direction.x) if direction.x != 0.0 else 1, 0)
	_steps = 0
	_active = true
	_timer = 0.0

	_beam = WizardryBeam.new()
	get_tree().current_scene.add_child(_beam)


func _to_grid(p: Vector2) -> Vector2i:
	return Vector2i(round(p.x / CELL_SIZE), round(p.y / CELL_SIZE))


func _process(delta: float) -> void:
	if not _active:
		return
	_timer += delta
	if _timer < STEP_INTERVAL:
		return
	_timer = 0.0
	_step()


func _step() -> void:
	if _marks.get(_pos, false):
		_dir = Vector2i(-_dir.y, _dir.x)
	_marks[_pos] = true
	_pos += _dir
	_steps += 1

	_beam.trail.append(_pos)
	_beam.queue_redraw()
	_check_switches()

	if _steps >= MAX_STEPS:
		_finish()


func _check_switches() -> void:
	var world_target := Vector2(_pos.x, _pos.y) * CELL_SIZE
	for node in get_tree().get_nodes_in_group("wizardry_switch"):
		if node.global_position.distance_to(world_target) <= TRIGGER_RADIUS:
			node.fire()


func _finish() -> void:
	_active = false
	var beam := _beam
	_beam = null
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(beam):
			beam.queue_free()
	)
