extends Node2D

class_name PartyComp

const MEMBER = preload("res://overworld/party_comp/draggable_member.tscn")

@onready var member_folder = $MemberFolder

func _ready():
	var reserves: Array[DraggableMember] = []
	for unit_data in Global.reserves:
		var a = MEMBER.instantiate()
		a.unit_data = unit_data
		print("reserve",unit_data.id)
		reserves.append(a)
		member_folder.add_child(a)
	
	var party: Array[DraggableMember] = []
	for unit_data in Global.current_party:
		var	a = MEMBER.instantiate()
		a.unit_data = unit_data
		#print("party",unit_data.id)
		party.append(a)
		member_folder.add_child(a)
	
	$Reserves.init(reserves)
	$CurrParty.init(party)

func _process(_delta):
	#default all members that are not in CurrParty to reserves
	for member in $MemberFolder.get_children():
		if !$CurrParty.members.has(member) and !$Reserves.members.has(member):
			member.global_position = $Reserves.anchor.global_position

func _on_button_pressed():
	Global.current_party = $CurrParty.get_members_unit_data()
	Global.reserves = $Reserves.get_members_unit_data()
	
	if Global.get_last_overworld_scene():
		get_tree().change_scene_to_packed(Global.get_last_overworld_scene())
