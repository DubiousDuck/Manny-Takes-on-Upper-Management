extends Node

## Global script with utility functions

# Overworld
var _last_overworld: String = ""

var brightness_val: float = 100.0

func start():
	brightness_val = 100.0

func set_last_overworld(file_name: String):
	#TODO: check if the file_name is a valid scene path
	_last_overworld = file_name

func get_last_overworld() -> String:
	return _last_overworld


# Skill Tree Related
enum talent_type{PROTAG, COMPANY}

## A dictionary of all protagonist talent nodes that have been activated.
var _protag_talent: Dictionary = {}
## A dictionary of all company talent nodes that have been activated.
var _company_talent: Dictionary = {}

func get_talent_activated(code: int) -> Dictionary:
	match code:
		talent_type.PROTAG:
			return _protag_talent
		talent_type.COMPANY:
			return _company_talent
		_:
			return {}

func clear_talent(code: int) -> void:
	match code:
		talent_type.PROTAG:
			_protag_talent.clear()
		talent_type.COMPANY:
			_company_talent.clear()

func copy_talent_dict_from(code: int, from: Dictionary):
	match code:
		talent_type.PROTAG:
			_protag_talent = from.duplicate()
		talent_type.COMPANY:
			_company_talent = from.duplicate()

func merge_talent_dict_with(code: int, target: Dictionary):
	match code:
		talent_type.PROTAG:
			_protag_talent.merge(target, true)
		talent_type.COMPANY:
			_company_talent.merge(target, true)
