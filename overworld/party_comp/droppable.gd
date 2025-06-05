extends Area2D

class_name Droppable

## constant pixel gap between members
const GAP: int = 400

@export var is_current_member: bool = false

@onready var anchor = $Marker2D
var members: Array[DraggableMember] = []

func _ready():
	EventBus.connect("dragging_start", _on_drag_start)
	EventBus.connect("dragging_stop", _on_drag_stop)

func init(array: Array[DraggableMember]):
	members.append_array(array)
	snap_to_queue()

func snap_to_queue():
	if members.size() <= 0:
		return

	var displacement = GAP/members.size()
	for i in range(members.size()):
		var offset = Vector2(displacement/2 + displacement*i-GAP/2, 0)
		members[i].global_position = anchor.global_position + offset
		members[i].snap_items()
		members[i].update_status_and_items(is_current_member)
	
func _on_drag_start(type: String):
	if type != "Member":
		return
	$ColorRect.show()

func _on_drag_stop(type: String):
	if type != "Member":
		return
	$ColorRect.hide()
	#print("dragging stopped!")
	snap_to_queue()

func _on_area_entered(area):
	if area.get_parent() is DraggableMember and !members.has(area.get_parent()):
		if is_current_member and members.size() >= Global.max_party_num:
			return
		members.append(area.get_parent())
		#print(members)

#FIXME: resolve bug that might arise when a member is in both areas
func _on_area_exited(area):
	if area.get_parent() is DraggableMember and members.has(area.get_parent()):
		members.erase(area.get_parent())
		#print(members)

func get_members_unit_data() -> Array[UnitData]:
	var output: Array[UnitData] = []
	for member in members:
		output.append(member.unit_data)
	return output
