extends Node

const SKILL_RESOURCE_PATHS = preload("res://skills/skill_resource_list.gd").SKILL_RESOURCE_PATHS

var skill_templates: Dictionary = {}

func _ready():
	load_skills_from_list()
	print("SkillDatabase loaded %d skills." % skill_templates.size())

func load_skills_from_list():
	for path in SKILL_RESOURCE_PATHS:
		var skill = ResourceLoader.load(path)
		if skill != null and skill is SkillInfo:
			skill_templates[skill.name] = skill
		else:
			push_error("SkillDatabase: Failed to load or cast skill at %s" % path)

func get_by_name(skill_name: String) -> SkillInfo:
	if skill_templates.has(skill_name):
		return skill_templates[skill_name].duplicate(true)
	else:
		push_error("SkillDatabase: No skill named '%s'" % skill_name)
		return null

func get_template(skill_name: String) -> SkillInfo:
	return skill_templates.get(skill_name, null)

func get_all_skill_names() -> Array[String]:
	return skill_templates.keys()
