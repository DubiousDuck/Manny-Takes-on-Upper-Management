extends Draggable

class_name DraggableMember

const GAP = 150
const CLASS_TEXTURE: Dictionary[String, String] = {
	"Protagonist": "res://ui/single_sprite_atlus/base_sprite.atlastex",
	"Fighter": "res://ui/single_sprite_atlus/fighter_sprite.atlastex",
	"Ranger": "res://ui/single_sprite_atlus/ranger_sprite.atlastex",
	"Tank": "res://ui/single_sprite_atlus/tank_sprite.atlastex",
	"Mage": "res://ui/single_sprite_atlus/mage_sprite.atlastex",
	"Healer": "res://ui/single_sprite_atlus/healer_sprite.atlastex"
}

@onready var item_folder = $ItemFolder

@export var unit_data: UnitData
var current_item: DraggableItem
var equipped_items: Array[DraggableItem]

## A boolean variable representing whether this member is in current party or not
var in_curr_party: bool = false

func _ready():
	super()
	$Label.text = "%s\nLv.%d" %[unit_data.unit_class, unit_data.level]
	EventBus.connect("dragging_stop", _on_dragging_stop)
	EventBus.connect("remove_item", _on_remove_item)
	
	$Sprite2D.texture = load(CLASS_TEXTURE.get(unit_data.unit_class, "res://ui/single_sprite_atlus/base_sprite.atlastex"))

func init(items: Array[DraggableItem]):
	equipped_items.append_array(items)
	equipped_items.map(func(item: DraggableItem):
		item.equipper = self
	)
	snap_items()

func _process(_delta):
	#if unit is protanoist, can't be dragged out of current party
	if unit_data.unit_class == "Protagonist":
		return	
	super(_delta)

func _on_dragging_stop(type: String):
	if type != "Item":
		return
	if current_item:
		add_item_to_equipped(current_item)
		current_item = null
	snap_items()

func update_status_and_items(new_state: bool):
	in_curr_party = new_state
	# if no longer in current pary, release all items
	if !in_curr_party:
		for item in equipped_items:
			item.clear_equipper_and_reset()
	
func add_item_to_equipped(item: DraggableItem):
	if equipped_items.has(item) or equipped_items.size() >= 1:
		return
	else:
		equipped_items.append(item)
		item.equipper = self
		snap_items()

func _on_remove_item():
	for item in equipped_items:
		if item is DraggableItem and item.remove_button.button_pressed:
			item.remove_button.button_pressed = false
			equipped_items.erase(item)
			item.back_to_origin()
			item.equipper = null
			break
	snap_items()
			
func save_all_items_to_data():
	unit_data.item_list.clear()
	for item in equipped_items:
		if !(unit_data.item_list.has(item.item_data)):
			unit_data.add_item(item.item_data)

func snap_items():
	
	#scan through array and clean off those that are no longer equipped by this member
	var cleaned_items: Array[DraggableItem] = []
	for item in equipped_items:
		if item.equipper == self:
			cleaned_items.append(item)
	equipped_items = cleaned_items.duplicate()
	
	#queueing
	if equipped_items.size() <= 0:
		return
	var displacement = GAP/equipped_items.size()
	for i in range(equipped_items.size()):
		var offset = Vector2(displacement/2 + displacement*i-GAP/2, 0)
		equipped_items[i].global_position = $ItemMarker.global_position + offset

func _on_item_detector_area_entered(area):
	if area.get_parent() is DraggableItem:
		current_item = area.get_parent()

func _on_item_detector_area_exited(area):
	if area.get_parent() is DraggableItem:
		current_item = null
