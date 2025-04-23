extends Draggable

class_name DraggableItem

@export var item_data: ItemData

@onready var remove_button : Button = $Remove

var original_pos: Vector2
var equipper: DraggableMember

func _ready():
	if item_data:
		$Label.text = item_data.item_name
	original_pos = global_position

func _on_remove_pressed():
	EventBus.emit_signal("remove_item")

func back_to_origin():
	global_position = original_pos

func clear_equipper_and_reset():
	equipper = null
	back_to_origin()

func update_original_pos(new_pos: Vector2):
	if new_pos:
		original_pos = new_pos
	else: original_pos = global_position
