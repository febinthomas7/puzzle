extends Node
class_name InputController

signal tile_push_requested(from: Vector2i, direction: int)

const DRAG_THRESHOLD := 20.0 # Lowered slightly for more responsive mobile tracking

var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_start_grid: Vector2i = Vector2i(-1, -1)
var _dragging: bool = false
var _direction_locked: bool = false
var _locked_direction: int = -1
var _action_triggered_this_drag: bool = false # FIXED: Prevents double-firing on a single gesture

# Set by main.gd
var grid_view: Control = null
var grid_model: GridModel = null

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _dragging:
		_update_drag(event.position)

func _start_drag(screen_pos: Vector2) -> void:
	if grid_model == null:
		return
		
	var grid_pos: Vector2i = _screen_to_grid(screen_pos)
	if grid_pos.x == -1:
		return
		
	if grid_model.get_cell(grid_pos.x, grid_pos.y) in [GridModel.EMPTY, GridModel.BLOCKED]:
		return 

	_drag_start_screen = screen_pos
	_drag_start_grid = grid_pos
	_dragging = true
	_direction_locked = false
	_locked_direction = -1
	_action_triggered_this_drag = false

func _update_drag(screen_pos: Vector2) -> void:
	if not _dragging or _action_triggered_this_drag:
		return

	var delta: Vector2 = screen_pos - _drag_start_screen
	
	# Lock direction if the movement vector passes the threshold radius
	if not _direction_locked:
		if delta.length() < DRAG_THRESHOLD:
			return
			
		if abs(delta.x) > abs(delta.y):
			_locked_direction = GridModel.Direction.RIGHT if delta.x > 0 else GridModel.Direction.LEFT
		else:
			_locked_direction = GridModel.Direction.DOWN if delta.y > 0 else GridModel.Direction.UP
		_direction_locked = true

	# FIXED: Instead of waiting for release, evaluate if the drag has moved far
	# enough to cross into an entirely new grid space along the locked axis.
	var current_grid_pos: Vector2i = _screen_to_grid(screen_pos)
	if current_grid_pos == _drag_start_grid or current_grid_pos.x == -1:
		return

	# Confirm the vector change aligns with our intended locked step direction
	var step_taken := current_grid_pos - _drag_start_grid
	var is_valid_move := false
	
	match _locked_direction:
		GridModel.Direction.LEFT: is_valid_move = (step_taken.x <= -1 and step_taken.y == 0)
		GridModel.Direction.RIGHT: is_valid_move = (step_taken.x >= 1 and step_taken.y == 0)
		GridModel.Direction.UP: is_valid_move = (step_taken.y <= -1 and step_taken.x == 0)
		GridModel.Direction.DOWN: is_valid_move = (step_taken.y >= 1 and step_taken.x == 0)

	if is_valid_move:
		tile_push_requested.emit(_drag_start_grid, _locked_direction)
		_action_triggered_this_drag = true # Locks out further adjustments until finger lift
		_dragging = false # Safely wind down the drag process

func _end_drag() -> void:
	_dragging = false
	_direction_locked = false
	_locked_direction = -1
	_drag_start_grid = Vector2i(-1, -1)
	_action_triggered_this_drag = false

func _screen_to_grid(screen_pos: Vector2) -> Vector2i:
	if grid_view == null or grid_model == null:
		return Vector2i(-1, -1)

	# Transform coordinates safely back to the layout viewport box boundary context
	var local_pos: Vector2 = grid_view.get_global_transform().affine_inverse() * screen_pos
	
	# Safe column check handles non-square window edge scaling scenarios
	var cell_w: float = grid_view.size.x / grid_model.width
	var cell_h: float = grid_view.size.y / grid_model.height

	var gx: int = int(local_pos.x / cell_w)
	var gy: int = int(local_pos.y / cell_h)

	if gx < 0 or gx >= grid_model.width or gy < 0 or gy >= grid_model.height:
		return Vector2i(-1, -1)

	return Vector2i(gx, gy)