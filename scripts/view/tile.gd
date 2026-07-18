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
		-999: # BLOCKED
			style.bg_color = Color(0.3, 0.3, 0.35)
			style.border_color = Color(0.5, 0.5, 0.55)
			label.text = "✕"
		_:
			# 2048 NUMBERS: Fetch the custom background color from your color table
			label.text = str(value)
			style.bg_color = _color_for_value(value)
			
			# Dynamically shift border color slightly lighter to give depth
			style.border_color = style.bg_color.lightened(0.25)

	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	add_theme_stylebox_override("panel", style)

	# --- UI LAYOUT & TEXT CONTRAST OVERRIDES ---
	# Dynamic Text Contrast: Dark gray text for light 2 and 4 tiles, white for dark tiles
	if value == 2 or value == 4:
		label.add_theme_color_override("font_color", Color(0.47, 0.43, 0.40)) # Dark gray 2048 font
	else:
		label.add_theme_color_override("font_color", Color.WHITE)
	
	# Force center alignment inside the label bounding region
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Force the label to expand across the full rectangular area of the tile panel
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Dynamically scale font size based on the tile's visual dimensions (sweet spot is ~40% of tile height)
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
		_: return Color(0.24, 0.22, 0.20) # Fallback for high matching tiles