extends Node

var item_templates: Dictionary = {}

const ITEM_FOLDER := "res://items/" # Adjust this if needed

func _ready():
	load_items_from_folder(ITEM_FOLDER)
	print("ItemDatabase loaded %d items." % item_templates.size())

func load_items_from_folder(path: String):
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("ItemDatabase: Could not open folder %s" % path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path + file_name
			var item = load(file_path)
			if item != null and item is ItemData:
				item_templates[item.item_name] = item
		file_name = dir.get_next()
	dir.list_dir_end()

func get_by_name(item_name: String) -> ItemData:
	if item_templates.has(item_name):
		return item_templates[item_name].duplicate(true)
	else:
		push_error("ItemDatabase: No item named '%s'" % item_name)
		return null

func get_template(item_name: String) -> ItemData:
	return item_templates.get(item_name, null)

func get_all_item_names() -> Array[String]:
	return item_templates.keys()
