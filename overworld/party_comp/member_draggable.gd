extends Draggable

class_name DraggableMember

const drag_item = preload("res://overworld/party_comp/item_draggable.tscn")
const GAP = 100

@onready var item_folder = $ItemFolder

@export var unit_data: UnitData
var current_item: DraggableItem
var equipped_items: Array[DraggableItem]

func _ready():
	$Label.text = unit_data.unit_class
	load_all_items_from_data()
	EventBus.connect("dragging_stop", _on_dragging_stop)
	
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

func add_item_to_equipped(item: DraggableItem):
	if equipped_items.has(item):
		print("I already have this item. -- " + name)
		return
	else:
		print("equipping item... -- " + name)
		equipped_items.append(item)
		snap_items()

func save_all_items_to_data():
	for item in equipped_items:
		if !(unit_data.item_list.has(item.item_data)):
			unit_data.add_item(item.item_data)

func load_all_items_from_data():
	equipped_items.clear()
	for child in item_folder.get_children():
		child.queue_free()
	if unit_data:
		for item in unit_data.item_list:
			var a = drag_item.instantiate()
			a.item_data = item
			equipped_items.append(a)
			item_folder.add_child(a)
		snap_items()

func snap_items():
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
