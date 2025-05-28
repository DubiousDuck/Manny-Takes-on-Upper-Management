extends Node

# Maps unit_class name (e.g., "Fighter") to the base UnitData resource
var unit_templates: Dictionary = {}

func _ready():
	# Preload templates (excluding special enemies) and map by unit_class
	var protagonist = preload("res://unit/params/protagonist.tres")
	var fighter = preload("res://unit/params/fighter.tres")
	var tank = preload("res://unit/params/tank.tres")
	var healer = preload("res://unit/params/healer.tres")
	var mage = preload("res://unit/params/mage.tres")
	var ranger = preload("res://unit/params/ranger.tres")

	unit_templates[protagonist.unit_class] = protagonist
	unit_templates[fighter.unit_class] = fighter
	unit_templates[tank.unit_class] = tank
	unit_templates[healer.unit_class] = healer
	unit_templates[mage.unit_class] = mage
	unit_templates[healer.unit_class] = healer
	unit_templates[ranger.unit_class] = ranger

	print("UnitDatabase loaded with %d unit classes" % unit_templates.size())

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
