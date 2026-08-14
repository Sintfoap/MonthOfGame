extends Node

## Smithcraft: diffusion-limited aggregation, the same automaton as the
## "Six Grammars" prototype's Ore-Vein. Motes spawn near the cast point and
## random-walk until they touch the vein, then stick permanently as solid
## CrystalCell platforms. The vein persists between casts — walking back and
## casting again grows it further from where it already stands.

const CELL_SIZE := 16.0
const MAX_WALKERS := 24
const MAX_CELLS := 90
const STEP_INTERVAL := 0.03
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var _crystal := {}
var _walkers: Array = []
var _active := false
var _timer := 0.0
var _world: Node = null


func cast(world_pos: Vector2, direction: Vector2) -> void:
	if _active or _crystal.size() >= MAX_CELLS:
		return
	_world = get_tree().current_scene

	var origin := _to_grid(world_pos)
	if not _crystal.has(origin):
		_crystal[origin] = true
		_spawn_cell(origin)

	_walkers.clear()
	for i in range(MAX_WALKERS):
		var spread := int(direction.x) * (2 + i % 4)
		_walkers.append(origin + Vector2i(spread, (i % 3) - 1))

	_active = true
	_timer = 0.0


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
	for i in range(_walkers.size()):
		var w: Vector2i = _walkers[i]
		if _touching_crystal(w):
			_crystal[w] = true
			_spawn_cell(w)
			continue
		_walkers[i] = w + DIRS[randi() % DIRS.size()]

	_walkers = _walkers.filter(func(w): return not _crystal.has(w))

	if _crystal.size() >= MAX_CELLS or _walkers.is_empty():
		_active = false


func _touching_crystal(cell: Vector2i) -> bool:
	for d in DIRS:
		if _crystal.has(cell + d):
			return true
	return false


func _spawn_cell(cell: Vector2i) -> void:
	var body := CrystalCell.new()
	body.position = Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)
	body.setup(CELL_SIZE)
	_world.add_child(body)
