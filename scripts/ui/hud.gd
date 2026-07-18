extends Control
class_name HUD

@onready var score_label: Label = $StatsPanel/ScoreLabel
@onready var steps_label: Label = $StatsPanel/StepsLabel
@onready var combo_label: Label = $StatsPanel/ComboLabel
@onready var target_label: Label = $StatsPanel/TargetLabel # ADDED: Target text node link
@onready var game_over_panel: Control = $GameOverPanel
@onready var win_panel: Control = $WinPanel

func _ready() -> void:
	game_over_panel.visible = false
	win_panel.visible = false
	combo_label.visible = false # Keep hidden until a real combo happens

func update_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score

# ADDED: Updates the target finish line score from the dynamic grid_model metrics
func update_target_score(target_value: int) -> void:
	target_label.text = "TARGET: %d" % target_value

func update_steps(steps: int) -> void:
	steps_label.text = "REMAINING: %d" % steps

# CLEANED UP: Pointing directly to the numerical format strategy
func update_steps_text(steps_text: int) -> void:
	steps_label.text = "REMAINING: %d" % steps_text

func update_combo(multiplier: int) -> void:
	combo_label.text = "⚡ COMBO x%d" % multiplier
	
	# Dynamically shift visual color profile when combo goes wild
	if multiplier > 1:
		combo_label.add_theme_color_override("font_color", Color(0.95, 0.69, 0.47)) # Vivid orange highlight
		combo_label.visible = true
	else:
		combo_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55)) # Muted fallback
		combo_label.visible = false

func show_game_over() -> void:
	game_over_panel.visible = true

func show_win() -> void:
	win_panel.visible = true