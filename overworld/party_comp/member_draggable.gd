extends Draggable

class_name DraggableMember

@export var unit_data: UnitData
var current_item: ItemData

func _ready():
	$Label.text = unit_data.unit_class
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
		unit_data.add_item(current_item)
		print("added " + current_item.item_name + " to " + unit_data.unit_class)

func _on_item_detector_area_entered(area):
	if area.get_parent() is DraggableItem:
		current_item = area.get_parent().item_data

func _on_item_detector_area_exited(area):
	if area.get_parent() is DraggableItem:
		current_item = null
