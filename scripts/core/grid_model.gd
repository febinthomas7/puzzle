extends RefCounted
class_name GridModel

signal board_changed
signal score_changed(new_score: int)
signal combo_changed(multiplier: int)
signal game_over
signal game_won

enum Direction { UP, DOWN, LEFT, RIGHT }

const EMPTY := 0
const BLOCKED := -999

var width: int
var height: int
var grid: Array = [] # grid[y][x] = int value
var score: int = 0
var win_score: int = 500
var combo_multiplier: int = 1

func setup(w: int, h: int) -> void:
	width = w
	height = h
	grid = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(EMPTY)
		grid.append(row)
	score = 0
	combo_multiplier = 1
	_place_initial_tiles()
	board_changed.emit()

func _place_initial_tiles() -> void:
	var wall_count: int = int(width * height * 0.1)
	for i in range(wall_count):
		var pos := _random_empty_cell()
		if pos.x != -1:
			grid[pos.y][pos.x] = BLOCKED

	var particle_count: int = int(width * height * 0.4)
	for i in range(particle_count):
		var pos := _random_empty_cell()
		if pos.x == -1:
			continue
		var value: int = [2, 4].pick_random()
		if randf() < 0.5:
			value = -value
		grid[pos.y][pos.x] = value

func _random_empty_cell() -> Vector2i:
	var empties: Array = []
	for y in range(height):
		for x in range(width):
			if grid[y][x] == EMPTY:
				empties.append(Vector2i(x, y))
	if empties.is_empty():
		return Vector2i(-1, -1)
	return empties[randi() % empties.size()]

func get_cell(x: int, y: int) -> int:
	if x < 0 or x >= width or y < 0 or y >= height:
		return BLOCKED
	return grid[y][x]

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

func get_snapshot() -> Dictionary:
	var grid_copy: Array = []
	for row in grid:
		grid_copy.append(row.duplicate())
	return {"grid": grid_copy, "score": score, "combo": combo_multiplier}

func restore_snapshot(snapshot: Dictionary) -> void:
	grid = []
	for row in snapshot["grid"]:
		grid.append(row.duplicate())
	score = snapshot["score"]
	combo_multiplier = snapshot["combo"]
	board_changed.emit()
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier)

# UPDATED: Processes movement and evaluates collisions strictly at the point of impact
func push_tile(from: Vector2i, direction: Direction) -> bool:
	if not is_in_bounds(from.x, from.y):
		return false
	if grid[from.y][from.x] == EMPTY or grid[from.y][from.x] == BLOCKED:
		return false

	var step: Vector2i = _direction_vector(direction)
	var chain: Array = [] 
	var pos: Vector2i = from
	
	while is_in_bounds(pos.x, pos.y) and grid[pos.y][pos.x] != EMPTY and grid[pos.y][pos.x] != BLOCKED:
		chain.append(pos)
		pos += step

	if chain.is_empty():
		return false

	var max_shift: int = 0
	var check_pos: Vector2i = pos
	while is_in_bounds(check_pos.x, check_pos.y) and grid[check_pos.y][check_pos.x] == EMPTY:
		max_shift += 1
		check_pos += step

	# Calculate where the front tile will land and what it will collide with
	var collision_target_pos: Vector2i = chain.back() + step * (max_shift + 1)
	
	if max_shift > 0:
		for i in range(chain.size() - 1, -1, -1):
			var old_pos: Vector2i = chain[i]
			var new_pos: Vector2i = old_pos + step * max_shift
			grid[new_pos.y][new_pos.x] = grid[old_pos.y][old_pos.x]
			grid[old_pos.y][old_pos.x] = EMPTY
		
		for i in range(chain.size()):
			chain[i] += step * max_shift

	# --- POINT OF IMPACT COLLISION ONLY ---
	if is_in_bounds(collision_target_pos.x, collision_target_pos.y):
		var leader_pos: Vector2i = chain.back()
		var a: int = grid[leader_pos.y][leader_pos.x]
		var b: int = grid[collision_target_pos.y][collision_target_pos.x]
		
		if b != EMPTY and b != BLOCKED:
			combo_multiplier = 1
			if _try_react(leader_pos, collision_target_pos, a, b):
				board_changed.emit()
				score_changed.emit(score)
				_check_game_end_conditions()
				return true

	if max_shift > 0:
		board_changed.emit()
		_check_game_end_conditions()
		return true

	return false

func _direction_vector(direction: Direction) -> Vector2i:
	match direction:
		Direction.UP: return Vector2i(0, -1)
		Direction.DOWN: return Vector2i(0, 1)
		Direction.LEFT: return Vector2i(-1, 0)
		Direction.RIGHT: return Vector2i(1, 0)
	return Vector2i.ZERO

# Cleaned: Kept empty to satisfy architecture requirements without triggering full board loops
func resolve_chain_reactions() -> void:
	pass

func _try_react(pos_a: Vector2i, pos_b: Vector2i, a: int, b: int) -> bool:
	if a == b:
		var fused: int = a * 2
		grid[pos_a.y][pos_a.x] = fused
		grid[pos_b.y][pos_b.x] = EMPTY
		score += abs(fused) * combo_multiplier
		return true
	elif a == -b:
		grid[pos_a.y][pos_a.x] = EMPTY
		grid[pos_b.y][pos_b.x] = EMPTY
		score += abs(a) * 2 * combo_multiplier
		return true
	return false

func _check_game_end_conditions() -> void:
	if score >= win_score:
		game_won.emit()
	elif not _has_any_valid_move():
		game_over.emit()

func _has_any_valid_move() -> bool:
	for y in range(height):
		for x in range(width):
			if grid[y][x] == EMPTY or grid[y][x] == BLOCKED:
				continue
			for dir in [Direction.UP, Direction.DOWN, Direction.LEFT, Direction.RIGHT]:
				var step: Vector2i = _direction_vector(dir)
				var next_pos: Vector2i = Vector2i(x, y) + step
				if is_in_bounds(next_pos.x, next_pos.y) and grid[next_pos.y][next_pos.x] == EMPTY:
					return true
	return false