extends Node2D

## Galdur: an elementary cellular automaton wrapped in a ring, exactly like
## the one in the "Six Grammars" prototype. When it finishes growing, the
## final ring's density decides the size and lifetime of a temporary rune
## ward — a stepping-stone platform ahead of the caster, and (since it's
## solid on the World layer, same as any wall) a real obstacle to whatever
## is walking toward them.

const RING_SIZE := 48
const MAX_GEN := 10
const RULE_NUMBER := 30
const GEN_INTERVAL := 0.04
const FORWARD_OFFSET := 80.0  # clears the ward's own max half-width (65px)

var _rule_table: Array = []
var _ring: Array = []
var _growing := false
var _timer := 0.0
var _generation := 0
var _facing := 1.0


func _ready() -> void:
	_rule_table = _compute_rule_table(RULE_NUMBER)


func _compute_rule_table(num: int) -> Array:
	var table := []
	table.resize(8)
	for i in range(8):
		table[i] = (num >> i) & 1
	return table


func cast(facing: float = 1.0) -> void:
	_facing = facing
	_ring.resize(RING_SIZE)
	for i in range(RING_SIZE):
		_ring[i] = 0
	_ring[RING_SIZE / 2] = 1
	_generation = 0
	_growing = true
	_timer = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not _growing:
		return
	_timer += delta
	if _timer < GEN_INTERVAL:
		return
	_timer = 0.0
	_step_ring()
	queue_redraw()
	if _generation >= MAX_GEN:
		_growing = false
		_resolve_ward()


func _step_ring() -> void:
	var next := []
	next.resize(RING_SIZE)
	for i in range(RING_SIZE):
		var l = _ring[(i - 1 + RING_SIZE) % RING_SIZE]
		var c = _ring[i]
		var r = _ring[(i + 1) % RING_SIZE]
		next[i] = _rule_table[(l << 2) | (c << 1) | r]
	_ring = next
	_generation += 1


func _resolve_ward() -> void:
	var lit := 0
	for v in _ring:
		lit += v
	var density := float(lit) / float(_ring.size())
	var radius := 40.0 + density * 90.0
	var duration := 1.0 + density * 1.6

	# Ahead of the caster and at foot height, not below -- a caster
	# standing on solid ground has nothing but more solid ground beneath
	# them, so a ward placed there would spawn embedded in it, unreachable
	# by anything walking at ground level. FORWARD_OFFSET clears the
	# player's own collision box even at the ward's widest.
	var body := LevelBuilder.make_platform(
		get_tree().current_scene,
		global_position + Vector2(_facing * FORWARD_OFFSET, 0),
		Vector2(radius, 12),
		Color(0.73, 0.56, 0.26, 0.9)
	)
	get_tree().create_timer(duration).timeout.connect(body.queue_free)

	_ring.clear()
	queue_redraw()


func _draw() -> void:
	if _ring.is_empty():
		return
	var n := _ring.size()
	for i in range(n):
		if _ring[i] == 0:
			continue
		var angle := (float(i) / float(n)) * TAU - PI / 2.0
		var point := Vector2(cos(angle), sin(angle)) * (20.0 + float(_generation) * 3.0)
		draw_circle(point, 2.0, Color(0.85, 0.66, 0.32, 0.9))
