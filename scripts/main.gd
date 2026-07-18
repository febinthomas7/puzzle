extends Control

@export var grid_width: int = 6
@export var grid_height: int = 8
@export var current_difficulty: String = "medium" # Fallback default

var grid_model: GridModel
var move_history: MoveHistory
var _is_game_resolved: bool = false # Tracks if game has hit a final win/loss state

@onready var grid_view: GridView = $GridWrapper/GridView
@onready var hud: HUD = $HUD
@onready var input_controller: InputController = $InputController
@onready var main_menu: MainMenu = $MainMenu

func _ready() -> void:
	grid_model = GridModel.new()
	move_history = MoveHistory.new()

	# Connect core structural model pipelines
	grid_model.board_changed.connect(_on_board_changed)
	grid_model.score_changed.connect(_on_score_changed)
	grid_model.combo_changed.connect(_on_combo_changed)
	grid_model.moves_changed.connect(_on_moves_changed) 
	grid_model.game_over.connect(_on_game_over)
	grid_model.game_won.connect(_on_game_won)

	# Wire up the input translation layers
	input_controller.grid_view = grid_view
	input_controller.grid_model = grid_model
	input_controller.tile_push_requested.connect(_on_tile_push_requested)

	# NEW: Catch the isolated interface broadcast event cleanly
	main_menu.difficulty_selected.connect(_on_difficulty_selected)
	
	
	_show_main_menu()

func _show_main_menu() -> void:
	main_menu.visible = true
	grid_view.visible = false
	hud.visible = false
	_is_game_resolved = true 
	hud.update_score(0)

# Intercepts selection signal payload and kicks off game loop
func _on_difficulty_selected(difficulty: String) -> void:
	current_difficulty = difficulty 
	main_menu.visible = false
	grid_view.visible = true
	hud.visible = true
	_is_game_resolved = false
	
	_start_new_game()


func _start_new_game() -> void:
	_is_game_resolved = false
	move_history.clear()
	hud.game_over_panel.visible = false
	hud.win_panel.visible = false
	
	# 1. Setup the internal metrics via the model engine
	grid_model.setup_with_difficulty(grid_width, grid_height, current_difficulty)
	hud.update_score(0) # Resets score display
	# 2. PUSH METRICS TO HUD LAYERS
	hud.update_target_score(grid_model.win_score) 
	hud.update_combo(1)                           

func _on_tile_push_requested(from: Vector2i, direction: int) -> void:
	if _is_game_resolved:
		return 

	
	var snapshot: Dictionary = grid_model.get_snapshot()

	var moved: bool = grid_model.push_tile(from, direction)
	if moved:
		move_history.push(snapshot)
		
		
		grid_model.resolve_chain_reactions()

func _on_board_changed() -> void:
	grid_view.render(grid_model)

func _on_score_changed(new_score: int) -> void:
	hud.update_score(new_score)

func _on_combo_changed(multiplier: int) -> void:
	hud.update_combo(multiplier)

# Direct listener updating the UI whenever the model changes remaining steps
func _on_moves_changed(remaining_moves: int) -> void:
	if grid_model.is_step_limited:
		hud.update_steps(remaining_moves)
	else:
		hud.update_steps(999) 

func _on_game_over() -> void:
	_is_game_resolved = true
	hud.show_game_over()

func _on_game_won() -> void:
	_is_game_resolved = true
	hud.show_win()

# Undo operation updates state directly from the restored model snapshot variables
func _on_undo_pressed() -> void:
	if _is_game_resolved:
		return 
		
	if move_history.can_undo():
		var snapshot: Dictionary = move_history.pop()
		grid_model.restore_snapshot(snapshot)
		
		# Re-enable inputs on retroactive rollback steps
		_is_game_resolved = false 

func _on_undo_button_pressed() -> void:
	_on_undo_pressed()


func _on_restart_pressed() -> void:
	_start_new_game()


func _on_button_pressed() -> void:
	_show_main_menu()
