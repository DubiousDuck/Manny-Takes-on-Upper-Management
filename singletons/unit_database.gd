extends Node

const UNIT_DATA_FOLDER := "res://unit/params/"
# Maps unit_class name (e.g., "Fighter") to the base UnitData resource
var unit_templates: Dictionary = {}

func _ready():
	load_unit_from_folder(UNIT_DATA_FOLDER)
	print("UnitDatabase loaded with %d unit classes" % unit_templates.size())

func load_unit_from_folder(path: String):
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("UnitDatabase: Could not open folder %s" % path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path + file_name
			var unit_data = load(file_path)
			if unit_data != null and unit_data is UnitData:
				unit_templates[unit_data.unit_class] = unit_data
		file_name = dir.get_next()
	dir.list_dir_end()

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
