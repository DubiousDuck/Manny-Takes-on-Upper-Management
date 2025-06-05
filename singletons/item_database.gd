extends Node

const ITEM_RESOURCE_PATHS = preload("res://items/item_resource_list.gd").ITEM_RESOURCE_PATHS

var item_templates: Dictionary = {}

func _ready():
	load_items_from_list()
	print("ItemDatabase loaded %d items." % item_templates.size())

func load_items_from_list():
	for path in ITEM_RESOURCE_PATHS:
		var item = ResourceLoader.load(path)
		if item != null and item is ItemData:
			item_templates[item.item_name] = item
		else:
			push_error("ItemDatabase: Failed to load or cast item at %s" % path)

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
