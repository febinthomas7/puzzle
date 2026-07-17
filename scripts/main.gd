extends Control

@export var grid_width: int = 6
@export var grid_height: int = 6
@export var max_steps: int = 30

var grid_model: GridModel
var move_history: MoveHistory
var _step_count: int = 0
var _is_game_resolved: bool = false # Tracks if game has hit a final win/loss state

@onready var grid_view: GridView = $GridWrapper/GridView
@onready var hud: HUD = $HUD
@onready var input_controller: InputController = $InputController

func _ready() -> void:
	grid_model = GridModel.new()
	move_history = MoveHistory.new()

	# Connect core structural model pipelines
	grid_model.board_changed.connect(_on_board_changed)
	grid_model.score_changed.connect(_on_score_changed)
	grid_model.combo_changed.connect(_on_combo_changed)
	grid_model.game_over.connect(_on_game_over)
	grid_model.game_won.connect(_on_game_won)

	# Wire up the input translation layers
	input_controller.grid_view = grid_view
	input_controller.grid_model = grid_model
	input_controller.tile_push_requested.connect(_on_tile_push_requested)

	# Initialize board run metrics
	_is_game_resolved = false
	grid_model.setup(grid_width, grid_height)
	hud.update_steps(max_steps - _step_count)

func _on_tile_push_requested(from: Vector2i, direction: int) -> void:
	if _is_game_resolved:
		return # Block moves if the game is already won/lost

	# Snapshot BEFORE mutation for an immutable history framework
	var snapshot: Dictionary = grid_model.get_snapshot()

	var moved: bool = grid_model.push_tile(from, direction)
	if moved:
		move_history.push(snapshot)
		
		# Incremented steps before cascade evaluation so step counter state is accurate
		_step_count += 1
		hud.update_steps(max_steps - _step_count)
		
		# Triggers internal recursive loops and evaluations
		grid_model.resolve_chain_reactions()

		# Check for out-of-steps step exhaustion ONLY if level isn't won or grid-locked
		if _step_count >= max_steps and not _is_game_resolved:
			_on_game_over()

func _on_board_changed() -> void:
	grid_view.render(grid_model)

func _on_score_changed(new_score: int) -> void:
	hud.update_score(new_score)

func _on_combo_changed(multiplier: int) -> void:
	hud.update_combo(multiplier)

func _on_game_over() -> void:
	_is_game_resolved = true
	hud.show_game_over()

func _on_game_won() -> void:
	_is_game_resolved = true
	hud.show_win()

# FIXED: Unified both your UI node binding connections to one robust undo implementation
func _on_undo_pressed() -> void:
	if move_history.can_undo():
		var snapshot: Dictionary = move_history.pop()
		grid_model.restore_snapshot(snapshot)
		
		_step_count = max(0, _step_count - 1)
		hud.update_steps(max_steps - _step_count)
		
		# Re-enable inputs on retroactive rollback steps
		_is_game_resolved = false 

func _on_undo_button_pressed() -> void:
	_on_undo_pressed()

func _on_restart_pressed() -> void:
	hud.game_over_panel.visible = false
	hud.win_panel.visible = false
	_step_count = 0
	_is_game_resolved = false  # <-- this line was missing
	move_history.clear()
	grid_model.setup(grid_width, grid_height)
	hud.update_steps(max_steps)