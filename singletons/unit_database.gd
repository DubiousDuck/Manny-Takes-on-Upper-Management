extends Node

const UNIT_RESOURCE_PATHS = preload("res://unit/unit_resource_list.gd").UNIT_RESOURCE_PATHS

# Maps unit_class name (e.g., "Fighter") to the base UnitData resource
var unit_templates: Dictionary = {}

func _ready():
	load_units_from_list()
	print("UnitDatabase loaded with %d unit classes" % unit_templates.size())

func load_units_from_list():
	for path in UNIT_RESOURCE_PATHS:
		var unit_data = ResourceLoader.load(path)
		if unit_data != null and unit_data is UnitData:
			unit_templates[unit_data.unit_class] = unit_data
		else:
			push_error("UnitDatabase: Failed to load or cast unit at %s" % path)

# Returns a deep copy of the base UnitData for this class
func get_by_class(unit_class: String) -> UnitData:
	if unit_templates.has(unit_class):
		return unit_templates[unit_class].duplicate(true)
	else:
		push_error("UnitDatabase: No UnitData with unit_class '%s'" % unit_class)
		return null

# Optional: get raw template (non-duplicated)
func get_template(unit_class: String) -> UnitData:
	return unit_templates.get(unit_class, null)

# Optional: expose all available unit classes
func get_all_unit_classes() -> Array[String]:
	return unit_templates.keys()
