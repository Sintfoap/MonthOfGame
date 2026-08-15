class_name IceField
extends Node2D

## A blocking wall of frost-cells, built to be melted rather than walked
## through. Ignited by Sorcery: a small seed converts to Fire, and Fire
## spreads to any Ice cell touching a Fire neighbor (genuine cellular
## spread, one neighbor is enough -- this school is meant to catch and run
## on its own). A Fire cell burns for MELT_TIME steps, then clears
## permanently. That second stage is time-based rather than neighbor-based
## on purpose: a neighbor-counted rule for it would deadlock, since nothing
## starts Cleared for a freshly-uniform field to count against.

const CELL_SIZE := 16.0
const IGNITE_THRESHOLD := 1
const MELT_TIME := 6
const STEP_INTERVAL := 0.08
const ICE_COLOR := Color(0.55, 0.72, 0.82)
const FIRE_COLOR := Color(0.82, 0.42, 0.24)

var cols := 0
var rows := 0
var state: Array = []
var fire_ticks: Array = []
var cells: Array = []
var _timer := 0.0
var _active := false


func setup(grid_cols: int, grid_rows: int) -> void:
	add_to_group("ice_field")
	cols = grid_cols
	rows = grid_rows
	state.resize(cols * rows)
	fire_ticks.resize(cols * rows)
	cells.resize(cols * rows)
	for y in range(rows):
		for x in range(cols):
			var i := y * cols + x
			state[i] = 0
			fire_ticks[i] = 0
			cells[i] = LevelBuilder.make_platform(
				self,
				Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, y * CELL_SIZE + CELL_SIZE / 2.0),
				Vector2(CELL_SIZE, CELL_SIZE),
				ICE_COLOR
			)


func ignite(world_pos: Vector2) -> void:
	var local := to_local(world_pos)
	var gx: int = clampi(int(local.x / CELL_SIZE), 0, cols - 1)
	var gy: int = clampi(int(local.y / CELL_SIZE), 0, rows - 1)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x := gx + dx
			var y := gy + dy
			if x >= 0 and x < cols and y >= 0 and y < rows:
				_set_fire(y * cols + x)
	_active = true


func _process(delta: float) -> void:
	if not _active:
		return
	_timer += delta
	if _timer < STEP_INTERVAL:
		return
	_timer = 0.0
	_active = _step()


func _step() -> bool:
	var any_active := false
	var to_ignite: Array = []
	for i in range(state.size()):
		if state[i] == 0:
			var x := i % cols
			var y := i / cols
			if _count_fire_neighbors(x, y) >= IGNITE_THRESHOLD:
				to_ignite.append(i)
		elif state[i] == 1:
			fire_ticks[i] += 1
			any_active = true
			if fire_ticks[i] >= MELT_TIME:
				_clear_cell(i)

	for i in to_ignite:
		_set_fire(i)
		any_active = true

	return any_active


func _count_fire_neighbors(x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < cols and ny >= 0 and ny < rows:
				if state[ny * cols + nx] == 1:
					count += 1
	return count


func _set_fire(i: int) -> void:
	if state[i] != 0:
		return
	state[i] = 1
	fire_ticks[i] = 0
	var body: StaticBody2D = cells[i]
	if is_instance_valid(body):
		for child in body.get_children():
			if child is Polygon2D:
				child.color = FIRE_COLOR


func _clear_cell(i: int) -> void:
	state[i] = 2
	var body: StaticBody2D = cells[i]
	if is_instance_valid(body):
		body.queue_free()
	cells[i] = null
