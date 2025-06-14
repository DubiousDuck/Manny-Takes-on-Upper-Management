extends Node2D

class_name PartyComp

const MEMBER = preload("res://overworld/party_comp/member_draggable.tscn")
const ITEM = preload("res://overworld/party_comp/item_draggable.tscn")

@export var tutorial_queue: Array[TutorialContent] = []

@onready var member_folder = $MemberFolder
@onready var item_folder = $ItemFolder

## Two possible values: "overworld", "battle"
var last_scene_type: String = "overworld"

func _ready():
	var reserves: Array[DraggableMember] = []
	# Spawning reserves
	for unit_data in Global.reserves:
		var a = MEMBER.instantiate()
		a.unit_data = unit_data
		#print("reserve",unit_data.id)
		reserves.append(a)
		member_folder.add_child(a)
	
	# spawning current party members
	var party: Array[DraggableMember] = []
	for unit_data in Global.current_party:
		var	a = MEMBER.instantiate()
		a.unit_data = unit_data
		# spawn the unit's items
		var items: Array[DraggableItem] = []
		if a.unit_data:
			for item in unit_data.item_list:
				var b = ITEM.instantiate()
				b.item_data = item
				item_folder.add_child(b)
				b.update_original_pos(item_folder.global_position)
				items.append(b)
		party.append(a)
		member_folder.add_child(a)
		a.init(items)
	
	$Reserves.init(reserves)
	$CurrParty.init(party)
	
	# spawn unequipped items
	for item in Global.unequipped_items:
		var a = ITEM.instantiate()
		a.item_data = item
		item_folder.add_child(a)
		var random_pos: Vector2 = Vector2(
			randi_range(item_folder.global_position.x - 100, item_folder.global_position.x + 100),
			randi_range(item_folder.global_position.y - 100, item_folder.global_position.y + 100))
		a.global_position = random_pos
		a.update_original_pos(random_pos)
	
	TutorialManager.set_tutorial_queue(tutorial_queue)
	EventBus.tutorial_trigger.emit("first_time_party_manage")
			
#default all members that are not in CurrParty to reserves
func find_lone_members(container: Droppable):
	for member in $MemberFolder.get_children():
		if !$CurrParty.members.has(member) and !$Reserves.members.has(member):
			container.members.append(member)

func _on_button_pressed():
	AudioPreload.play_sfx("menu_click")
	#save member item data
	for member in member_folder.get_children():
		if member is DraggableMember:
			member.save_all_items_to_data()
			
	Global.current_party = $CurrParty.get_members_unit_data()
	Global.reserves = $Reserves.get_members_unit_data()
	
	#save unequipped items
	Global.unequipped_items.clear()
	for child in item_folder.get_children():
		if child is DraggableItem and child.equipper == null:
			Global.unequipped_items.append(child.item_data)
	
	if Global.get_last_overworld_scene() and Global.last_scene_type == "overworld":
		get_tree().change_scene_to_packed(Global.get_last_overworld_scene())
	elif Global.get_last_battle_scene() and Global.last_scene_type == "battle":
		get_tree().change_scene_to_file(Global.get_last_battle_scene())
