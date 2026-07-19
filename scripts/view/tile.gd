extends Panel
class_name Tile

@onready var label: Label = $Label

var _tile_stylebox := StyleBoxFlat.new()

func _ready() -> void:
	_tile_stylebox.border_width_left = 3
	_tile_stylebox.border_width_right = 3
	_tile_stylebox.border_width_top = 3
	_tile_stylebox.border_width_bottom = 3
	_tile_stylebox.corner_radius_top_left = 12
	_tile_stylebox.corner_radius_top_right = 12
	_tile_stylebox.corner_radius_bottom_left = 12
	_tile_stylebox.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", _tile_stylebox)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	pivot_offset = size / 2.0 # so scale animations grow/shrink from center

func set_value(value: int) -> void:
	label.text = ""

	match value:
		0:
			_tile_stylebox.bg_color = Color(0.13, 0.14, 0.22)
			_tile_stylebox.border_color = Color(0.25, 0.28, 0.4)
		GridModel.VOID:
			_tile_stylebox.bg_color = Color(0.08, 0.09, 0.14)
			_tile_stylebox.border_color = Color(0.15, 0.16, 0.22)
			label.text = "◈"
		GridModel.FREEZE:
			_tile_stylebox.bg_color = Color(0.25, 0.55, 0.85)
			_tile_stylebox.border_color = Color(0.6, 0.85, 1.0)
			label.text = "❄"
		GridModel.BLOCKED:
			_tile_stylebox.bg_color = Color(0.3, 0.3, 0.35)
			_tile_stylebox.border_color = Color(0.5, 0.5, 0.55)
			label.text = "✕"
		_:
			label.text = str(value)
			_tile_stylebox.bg_color = _color_for_value(value)
			_tile_stylebox.border_color = _tile_stylebox.bg_color.lightened(0.25)

	if value == 2 or value == 4:
		label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.40))
	else:
		label.add_theme_color_override("font_color", Color.WHITE)

	var calculated_font_size: int = int(size.y * 0.4) if size.y > 0 else 28
	label.add_theme_font_size_override("font_size", calculated_font_size)

func _color_for_value(value: int) -> Color:
	match value:
		2: return Color(0.93, 0.89, 0.85)
		4: return Color(0.93, 0.88, 0.78)
		8: return Color(0.95, 0.69, 0.47)
		16: return Color(0.96, 0.58, 0.39)
		32: return Color(0.96, 0.48, 0.37)
		64: return Color(0.96, 0.37, 0.23)
		128: return Color(0.93, 0.81, 0.45)
		256: return Color(0.93, 0.80, 0.38)
		512: return Color(0.93, 0.78, 0.31)
		_: return Color(0.24, 0.22, 0.20)

# --- Animations ---
func play_spawn_animation() -> void:
	pivot_offset = size / 2.0
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	# SoundManager.play_spawn()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.15)

func play_destroy_animation() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", Vector2(0, 0), 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		set_value(0)
		scale = Vector2(1, 1)
		modulate.a = 1.0
	)

func play_merge_animation() -> void:
	pivot_offset = size / 2.0
	SoundManager.play_merge()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15)