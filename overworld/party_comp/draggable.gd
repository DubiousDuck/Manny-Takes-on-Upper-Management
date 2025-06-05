extends Node2D

class_name Draggable

@export_enum("Member", "Item") var type: String
var is_draggable := false
var is_dragging := false

func _ready():
	add_to_group("draggables")
	
func _process(delta):
	z_index = 100 if is_dragging else 0

func _unhandled_input(event):
	if !is_draggable:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var topmost = get_topmost_draggable_at_mouse()
				if topmost == self:
					EventBus.emit_signal("dragging_start", type)
					is_dragging = true
					get_viewport().set_input_as_handled()
			elif event.is_released():
				if is_dragging:
					is_dragging = false
					EventBus.emit_signal("dragging_stop", type)

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position()



func _on_area_2d_mouse_entered():
	is_draggable = true

func _on_area_2d_mouse_exited():
	if !is_dragging:
		is_draggable = false

func get_topmost_draggable_at_mouse() -> Draggable:
	var mouse_pos = get_global_mouse_position()
	var candidates: Array = [self]
	for node in get_tree().get_nodes_in_group("draggables"):
		#print(node.name)
		if node is Draggable and node.is_visible_in_tree():
			var area = node.get_node("Area2D")
			if area.get_overlapping_bodies().has(self):  # works if using physics body
				candidates.append(node)
			elif area.get_overlapping_areas().has($Area2D):  # works if using Area2D-overlap
				candidates.append(node)
				#print("added " + node.name)
	
	# Sort by Z index descending
	candidates.sort_custom(func(a, b): return a.z_index > b.z_index)
	return candidates[0] if candidates.size() > 0 else self
