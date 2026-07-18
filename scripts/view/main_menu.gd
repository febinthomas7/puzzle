extends Control
class_name MainMenu

# Signal emitted when a player picks a difficulty setting
signal difficulty_selected(difficulty_type: String)

@onready var easy_button: Button = $MenuLayout/EasyButton
@onready var medium_button: Button = $MenuLayout/MediumButton
@onready var hard_button: Button = $MenuLayout/HardButton
@onready var title_label: Label = $MenuLayout/Label

func _ready() -> void:
	# Configure professional, accessible UI styling alignments
	$MenuLayout.set_anchors_preset(Control.PRESET_CENTER)
	$MenuLayout.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Connect local button interaction signals directly using clean anonymous lambdas
	easy_button.pressed.connect(func(): _on_difficulty_pressed("easy"))
	medium_button.pressed.connect(func(): _on_difficulty_pressed("medium"))
	hard_button.pressed.connect(func(): _on_difficulty_pressed("hard"))
	
	_apply_text_styling()

func _on_difficulty_pressed(mode: String) -> void:
	# Broadcast selection metrics upward out of the isolated layer
	difficulty_selected.emit(mode)

func _apply_text_styling() -> void:
	# Clean inline visual theme overrides matching your game layout parameters
	title_label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.85)) # Warm cream 2048 color
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER