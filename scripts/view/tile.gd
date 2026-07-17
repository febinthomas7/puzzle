extends Panel
class_name Tile

@onready var label: Label = $Label

func set_value(value: int) -> void:
	label.text = ""
	var style := StyleBoxFlat.new()

	match value:
		0:
			style.bg_color = Color(0.13, 0.14, 0.22) # empty cell, dark navy
			style.border_color = Color(0.25, 0.28, 0.4)
		98: # VOID
			style.bg_color = Color(0.08, 0.09, 0.14)
			style.border_color = Color(0.15, 0.16, 0.22)
		99: # FREEZE
			style.bg_color = Color(0.25, 0.55, 0.85)
			style.border_color = Color(0.6, 0.85, 1.0)
			label.text = "❄"
		97: # BLOCKED
			style.bg_color = Color(0.3, 0.3, 0.35)
			style.border_color = Color(0.5, 0.5, 0.55)
			label.text = "✕"
		_:
			label.text = str(value)
			if value > 0:
				style.bg_color = Color(0.15, 0.35, 0.65) # blue for positive
				style.border_color = Color(0.4, 0.7, 1.0)
			else:
				style.bg_color = Color(0.55, 0.15, 0.2) # red for negative
				style.border_color = Color(0.9, 0.3, 0.35)

	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", style)

	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 28)

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
