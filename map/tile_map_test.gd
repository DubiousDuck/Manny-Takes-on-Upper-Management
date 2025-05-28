extends TileMapLayer

#tile map set up tutorial by https://www.youtube.com/watch?v=1qmXFIJU1QE

class_name MyMapLayer

const GRID_SIZE = 5
const MAIN_ATLAS_ID = 0
const BLUE_CELL := Vector2i(2, 0)
const WHITE_CELL := Vector2i(0, 0)
const RED_CELL := Vector2i(1, 0)
const HEAL_CELL := Vector2i(3, 0)
const PIT_CELL := Vector2i(4, 0)

const SCENE_COLLECTION_ID = 1
const SCENE_COORDS := Vector2i(0, 0)
const PIT_ID: int = 1
const HEAL_ID: int = 2

enum CELL_TYPE {WHITE, RED, BLUE, HEAL, PIT, TELEPORT, SPIKE}

## prevents multiple set cell function called at once
static var is_busy: bool = false

func _ready():
	EventBus.connect("occupy_cell", _on_occupy_cell)
	EventBus.connect("clear_cells", _on_clear_cells)
	EventBus.connect("set_cell", _on_set_cell)
	
func set_cell_to_variant(id : int, cell : Vector2i):
	var cell_variant
	var alternative: int = 0
	match id:
		CELL_TYPE.WHITE: cell_variant = WHITE_CELL
		CELL_TYPE.RED: cell_variant = RED_CELL
		CELL_TYPE.BLUE: cell_variant = BLUE_CELL
		CELL_TYPE.HEAL: cell_variant = HEAL_CELL
		CELL_TYPE.PIT: cell_variant = PIT_CELL
		CELL_TYPE.TELEPORT:
			cell_variant = WHITE_CELL
			alternative = 1
		CELL_TYPE.SPIKE:
			cell_variant = WHITE_CELL
			alternative = 2
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
			color_cell = WHITE_CELL
	set_cell(pos, MAIN_ATLAS_ID, color_cell)

func _on_clear_cells():
	for pos in get_used_cells():
		if HexNavi.get_cell_custom_data(pos, "effect") == "":
			set_cell(pos, MAIN_ATLAS_ID, WHITE_CELL)
	
func get_all_tilemap_cells() -> Array[Vector2i]:
	var all_cells: Array[Vector2i] = []
	for cell in get_used_cells():
		all_cells.append(cell)
	return all_cells

func _on_set_cell(pos: Vector2i, id: int):
	if id == CELL_TYPE.PIT: #if the pit
		single_tile_appear(pos, PIT_ID)
		await get_tree().create_timer(2).timeout
	if id == CELL_TYPE.HEAL: #if the heal
		single_tile_appear(pos, HEAL_ID)
		await get_tree().create_timer(1.5).timeout
	set_cell_to_variant(id, pos)

func single_tile_appear(pos: Vector2i, tile_ID: int):
	set_cell(pos, SCENE_COLLECTION_ID, SCENE_COORDS, tile_ID)

static func set_random_heal_tile(unit: Unit):
	if is_busy:
		return
	is_busy = true
	unit.regain_health(1, true)
	var new_cell := HexNavi.get_random_tile_pos()
	while Vector2i(new_cell) == unit.cell:
		new_cell = HexNavi.get_random_tile_pos()
	EventBus.emit_signal("set_cell", new_cell, MyMapLayer.CELL_TYPE.HEAL)
	await EventBus.set_cell_done
	EventBus.emit_signal("set_cell", unit.cell, MyMapLayer.CELL_TYPE.WHITE)
	EventBus.emit_signal("update_cell_status", true)
	is_busy = false
