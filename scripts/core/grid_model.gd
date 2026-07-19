extends RefCounted
class_name GridModel

signal board_changed
signal score_changed(new_score: int)
signal combo_changed(multiplier: int)
signal moves_changed(remaining_moves: int)
signal game_over
signal game_won

enum Direction { UP, DOWN, LEFT, RIGHT }

const EMPTY := 0
const BLOCKED := -999
const FREEZE := 99
const VOID := 98 # Added to match tile.gd layout configurations

var width: int
var height: int
var grid: Array = []
var score: int = 0
var win_score: int = 500
var combo_multiplier: int = 1

var remaining_moves: int = 0
var is_step_limited: bool = false

func setup(w: int, h: int) -> void:
	setup_with_difficulty(w, h, "easy")

func setup_with_difficulty(w: int, h: int, difficulty: String) -> void:
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
	
	var wall_ratio := 0.05
	var freeze_ratio := 0.05
	var void_ratio := 0.00 # Base fallback ratio
	
	match difficulty.to_lower():
		"easy":
			wall_ratio = 0.04     
			freeze_ratio = 0.04   
			void_ratio = 0.00 # Safe layout
			win_score = 300       
			is_step_limited = true
			remaining_moves = 999
		"medium":
			wall_ratio = 0.06
			freeze_ratio = 0.06
			void_ratio = 0.04 # Introduces minor pathing hazards
			win_score = 500
			is_step_limited = true
			remaining_moves = 45  
		"hard":
			wall_ratio = 0.10    
			freeze_ratio = 0.10   
			void_ratio = 0.08 # Heavy threat presence
			win_score = 800       
			is_step_limited = true
			remaining_moves = 30  
			
	_place_initial_tiles(wall_ratio, freeze_ratio, void_ratio)
	board_changed.emit()
	moves_changed.emit(remaining_moves)

func _place_initial_tiles(wall_ratio: float, freeze_ratio: float, void_ratio: float) -> void:
	# 1. Spawn Permanent Wall Blocks
	var wall_count: int = int(width * height * wall_ratio)
	for i in range(wall_count):
		var pos := _random_empty_cell()
		if pos.x != -1:
			grid[pos.y][pos.x] = BLOCKED

	# 2. Spawn Interactive Freeze Blocks
	var freeze_count: int = int(width * height * freeze_ratio)
	for i in range(freeze_count):
		var pos := _random_empty_cell()
		if pos.x != -1:
			grid[pos.y][pos.x] = FREEZE

	# 3. Spawn Static Void Hazards
	var void_count: int = int(width * height * void_ratio)
	for i in range(void_count):
		var pos := _random_empty_cell()
		if pos.x != -1:
			grid[pos.y][pos.x] = VOID

	# 4. Spawn Standard Positive Numbers
	var particle_count: int = int(width * height * 0.25)
	var attempts := 0
	var particles_placed := 0
	
	while particles_placed < particle_count and attempts < 200:
		attempts += 1
		var pos := _random_empty_cell()
		if pos.x == -1:
			break
			
		var test_value: int = [2, 4].pick_random()
		var is_safe := true
		
		for dir: Vector2i in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var neighbor_pos := pos + dir
			if is_in_bounds(neighbor_pos.x, neighbor_pos.y):
				var neighbor_val: int = grid[neighbor_pos.y][neighbor_pos.x]
				if neighbor_val != EMPTY and neighbor_val != BLOCKED and neighbor_val != FREEZE and neighbor_val != VOID:
					if neighbor_val == test_value:
						is_safe = false
						break
		
		if is_safe:
			grid[pos.y][pos.x] = test_value
			particles_placed += 1

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

func _spawn_new_particle() -> void:
	var pos := _random_empty_cell()
	if pos.x != -1:
		var new_value := 2
		var roll := randf()
		
		if score < 200:
			new_value = 4 if roll < 0.15 else 2
		elif score < 400:
			new_value = 4 if roll < 0.30 else 2
		else:
			if roll < 0.10: new_value = 8
			elif roll < 0.35: new_value = 4
			else: new_value = 2
			
		grid[pos.y][pos.x] = new_value

func push_tile(from: Vector2i, direction: Direction) -> bool:
	if not is_in_bounds(from.x, from.y):
		return false
	# Structural rules: You cannot select or push an empty space, wall, freeze, or void tile directly
	if grid[from.y][from.x] <= EMPTY or grid[from.y][from.x] == FREEZE or grid[from.y][from.x] == VOID:
		return false

	var step: Vector2i = _direction_vector(direction)
	var val_a: int = grid[from.y][from.x]
	var target_pos := from
	
	# Slide across empty spaces
	while true:
		var next_pos := target_pos + step
		if not is_in_bounds(next_pos.x, next_pos.y):
			break
		
		var next_val: int = grid[next_pos.y][next_pos.x]
		if next_val == EMPTY:
			target_pos = next_pos
		else:
			break

	var final_next_pos := target_pos + step
	var moved_any := false
	var merged := false
	var consumed_by_void := false

	if is_in_bounds(final_next_pos.x, final_next_pos.y):
		var structural_target: int = grid[final_next_pos.y][final_next_pos.x]
		
		# INTERACTION 1: Slide into a VOID cell -> Tile drops out and disappears
		if structural_target == VOID:
			grid[from.y][from.x] = EMPTY
			consumed_by_void = true
			moved_any = true
		
		# INTERACTION 2: Hitting a Freeze tile shatters it
		elif structural_target == FREEZE:
			grid[final_next_pos.y][final_next_pos.x] = EMPTY 
			moved_any = true
		
		# INTERACTION 3: Direct value matching merge
		elif structural_target != BLOCKED:
			if val_a == structural_target:
				grid[from.y][from.x] = EMPTY
				grid[final_next_pos.y][final_next_pos.x] = val_a * 2
				score += (val_a * 2) * combo_multiplier
				moved_any = true
				merged = true

	# If it did not merge or get consumed by a void, map its final sliding resting position
	if not merged and not consumed_by_void and target_pos != from:
		grid[target_pos.y][target_pos.x] = val_a
		grid[from.y][from.x] = EMPTY
		moved_any = true

	if moved_any:
		if is_step_limited:
			remaining_moves -= 1
			moves_changed.emit(remaining_moves)
			
		_spawn_new_particle()
		board_changed.emit()
		score_changed.emit(score)
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

func _try_react(pos_a: Vector2i, pos_b: Vector2i, a: int, b: int) -> bool:
	if a == b:
		var fused: int = a * 2
		grid[pos_a.y][pos_a.x] = fused
		grid[pos_b.y][pos_b.x] = EMPTY
		score += fused * combo_multiplier
		return true
	return false

func get_snapshot() -> Dictionary:
	var grid_copy: Array = []
	for row in grid:
		grid_copy.append(row.duplicate())
	return {
		"grid": grid_copy, 
		"score": score, 
		"combo": combo_multiplier,
		"remaining_moves": remaining_moves
	}

func resolve_chain_reactions() -> void: 
	pass

func restore_snapshot(snapshot: Dictionary) -> void:
	grid = []
	for row in snapshot["grid"]:
		grid.append(row.duplicate())
	score = snapshot["score"]
	combo_multiplier = snapshot["combo"]
	if snapshot.has("remaining_moves"):
		remaining_moves = snapshot["remaining_moves"]
	board_changed.emit()
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier)
	moves_changed.emit(remaining_moves) 

func _check_game_end_conditions() -> void:
	if score >= win_score:
		game_won.emit()
	elif is_step_limited and remaining_moves <= 0:
		game_over.emit()
	elif not _has_any_valid_move():
		game_over.emit()

func _has_any_valid_move() -> bool:
	for y in range(height):
		for x in range(width):
			# Added VOID validation skip here
			if grid[y][x] == EMPTY or grid[y][x] == BLOCKED or grid[y][x] == FREEZE or grid[y][x] == VOID:
				continue
			for dir in [Direction.UP, Direction.DOWN, Direction.LEFT, Direction.RIGHT]:
				var step: Vector2i = _direction_vector(dir)
				var next_pos: Vector2i = Vector2i(x, y) + step
				if is_in_bounds(next_pos.x, next_pos.y) and grid[next_pos.y][next_pos.x] == EMPTY:
					return true
	return false