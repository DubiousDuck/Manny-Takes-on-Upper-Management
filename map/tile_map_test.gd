extends TileMapLayer

#tile map set up tutorial by https://www.youtube.com/watch?v=1qmXFIJU1QE

const GRID_SIZE = 5
const MAIN_ATLAS_ID = 0
const BLUE_CELL := Vector2i(1, 0)
const WHITE_CELL := Vector2i(0, 1)
const YELLOW_CELL := Vector2i(0, 0)
const RED_CELL := Vector2i(2, 0)

const SCENE_COLLECTION_ID = 1
const SCENE_COORDS := Vector2i(0, 0)
const PIT_ID: int = 1
const HEAL_ID: int = 2

func _ready():
	EventBus.connect("occupy_cell", _on_occupy_cell)
	EventBus.connect("clear_cells", _on_clear_cells)
	EventBus.connect("set_cell", _on_set_cell)
	
func set_cell_to_variant(id : int, cell : Vector2i):
	var cell_variant
	var alternative: int = 0
	match id:
		0: cell_variant = YELLOW_CELL
		1: cell_variant = RED_CELL
		2: cell_variant = BLUE_CELL
		3:
			cell_variant = YELLOW_CELL
			alternative = 1
		4:
			cell_variant = RED_CELL
			alternative = 1
	set_cell(cell, MAIN_ATLAS_ID, cell_variant, alternative)
	#Update cell weights
	HexNavi.set_weight_of_layer("traversable", true, 1)
	HexNavi.set_weight_of_layer("traversable", false, 999)
	EventBus.emit_signal("set_cell_done")

func _on_occupy_cell(pos : Vector2i, unit_type : String):
	if !HexNavi.get_cell_custom_data(pos, "traversable"):
		return
	var color_cell : Vector2i
	match unit_type:
		"player":
			color_cell = BLUE_CELL
		"enemy":
			color_cell = RED_CELL
		_:
			color_cell = YELLOW_CELL
	set_cell(pos, MAIN_ATLAS_ID, color_cell)

func _on_clear_cells():
	for pos in get_used_cells():
		if HexNavi.get_cell_custom_data(pos, "effect") == "":
			set_cell(pos, MAIN_ATLAS_ID, YELLOW_CELL)
	
func get_all_tilemap_cells() -> Array[Vector2i]:
	var all_cells: Array[Vector2i] = []
	for cell in get_used_cells():
		all_cells.append(cell)
	return all_cells

func _on_set_cell(pos: Vector2i, id: int):
	if id == 4: #if the pit
		single_tile_appear(pos, PIT_ID)
		await get_tree().create_timer(2).timeout
	if id == 3: #if the heal
		single_tile_appear(pos, HEAL_ID)
		await get_tree().create_timer(1.5).timeout
	set_cell_to_variant(id, pos)

func single_tile_appear(pos: Vector2i, tile_ID: int):
	set_cell(pos, SCENE_COLLECTION_ID, SCENE_COORDS, tile_ID)

#func _input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			#clear_path()
			#var pos_clicked = local_to_map(get_local_mouse_position())
			#show_path(pos_clicked)
			#var cur_cell_atlas_coords = get_cell_atlas_coords(pos_clicked)
			#var cur_cell_alt_id = get_cell_alternative_tile(pos_clicked)
			#var alt_counts = tile_set.get_source(MAIN_ATLAS_ID).get_alternative_tiles_count(cur_cell_atlas_coords)
			#set_cell(pos_clicked, MAIN_ATLAS_ID, cur_cell_atlas_coords, (cur_cell_alt_id+1)%alt_counts)
