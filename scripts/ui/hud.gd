extends Control
class_name HUD

@onready var score_label: Label = $StatsPanel/ScoreLabel
@onready var steps_label: Label = $StatsPanel/StepsLabel
@onready var combo_label: Label = $StatsPanel/ComboLabel
@onready var game_over_panel: Control = $GameOverPanel
@onready var win_panel: Control = $WinPanel

func _ready() -> void:
	game_over_panel.visible = false
	win_panel.visible = false

func update_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score

func update_steps(steps: int) -> void:
	steps_label.text = "REMAINING: %d" % steps

func update_combo(multiplier: int) -> void:
	combo_label.text = "⚡ COMBO x%d" % multiplier
	combo_label.visible = multiplier > 1

func show_game_over() -> void:
	game_over_panel.visible = true

func show_win() -> void:
	win_panel.visible = true


