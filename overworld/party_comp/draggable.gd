extends Node2D

class_name Draggable

@export_enum("Member", "Item") var type: String
var is_draggable := false
var is_dragging := false

func _ready():
	add_to_group("draggables")
	
func _process(delta):
	if is_draggable:
		if Input.is_action_just_pressed("LMB"):
			var topmost = get_topmost_draggable_at_mouse()
			if topmost == self:
				EventBus.emit_signal("dragging_start", type)
				is_dragging = true
		if Input.is_action_pressed("LMB") and is_dragging:
			global_position = get_global_mouse_position()
		elif Input.is_action_just_released("LMB"):
			is_dragging = false
			EventBus.emit_signal("dragging_stop", type)
	if is_dragging:
		z_index = 100  # Pull to top
	else:
		z_index = 0


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
				print("added " + node.name)
	
	# Sort by Z index descending
	candidates.sort_custom(func(a, b): return a.z_index > b.z_index)
	return candidates[0] if candidates.size() > 0 else self
