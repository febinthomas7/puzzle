extends GridContainer
class_name GridView

const TileScene = preload("res://scenes/grid/tile.tscn")

var tile_nodes: Array = []
var _previous_values: Array = []

func render(model: GridModel) -> void:
	if tile_nodes.is_empty():
		_build_grid(model)

	for y in range(model.height):
		for x in range(model.width):
			var new_value: int = model.get_cell(x, y)
			var old_value: int = _previous_values[y][x]
			var tile = tile_nodes[y][x]

			if old_value == 0 and new_value != 0:
				tile.set_value(new_value)
				tile.play_spawn_animation()
			elif old_value != 0 and new_value == 0:
				tile.play_destroy_animation()
			elif old_value != 0 and new_value != 0 and old_value != new_value:
				tile.set_value(new_value)
				tile.play_merge_animation()
			else:
				tile.set_value(new_value)

			_previous_values[y][x] = new_value


func render_immediate(model: GridModel) -> void:
	if tile_nodes.is_empty():
		_build_grid(model)

	for y in range(model.height):
		for x in range(model.width):
			var value: int = model.get_cell(x, y)
			tile_nodes[y][x].set_value(value)
			_previous_values[y][x] = value

func _build_grid(model: GridModel) -> void:
	tile_nodes.clear()
	_previous_values.clear()
	for child in get_children():
		child.queue_free()

	columns = model.width

	for y in range(model.height):
		var row: Array = []
		var value_row: Array = []
		for x in range(model.width):
			var tile = TileScene.instantiate()
			add_child(tile)
			tile.custom_minimum_size = Vector2(150, 150)
			row.append(tile)
			value_row.append(0)
		tile_nodes.append(row)
		_previous_values.append(value_row)
