extends GridContainer
class_name GridView

const TileScene = preload("res://scenes/grid/tile.tscn")

var tile_nodes: Array = [] # tile_nodes[y][x] = Tile instance

func render(model: GridModel) -> void:
	if tile_nodes.is_empty():
		_build_grid(model)

	for y in range(model.height):
		for x in range(model.width):
			var value: int = model.get_cell(x, y)
			tile_nodes[y][x].set_value(value)

func _build_grid(model: GridModel) -> void:
	tile_nodes.clear()
	for child in get_children():
		child.queue_free()

	columns = model.width # GridContainer's built-in property — this is the key line

	for y in range(model.height):
		var row: Array = []
		for x in range(model.width):
			var tile = TileScene.instantiate()
			add_child(tile)
			tile.custom_minimum_size = Vector2(150, 150) # adjust to your preferred tile size
			row.append(tile)
		tile_nodes.append(row)
