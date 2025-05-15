extends Node

var skill_templates: Dictionary = {}

# Set this to the folder where your SkillInfo resources are stored
const SKILL_FOLDER := "res://skills/" # Adjust as needed

func _ready():
	load_skills_from_folder(SKILL_FOLDER)
	print("SkillDatabase loaded %d skills." % skill_templates.size())

func load_skills_from_folder(path: String):
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("SkillDatabase: Could not open folder %s" % path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path + file_name
			var skill = load(file_path)
			if skill != null and skill is SkillInfo:
				skill_templates[skill.name] = skill
		file_name = dir.get_next()
	dir.list_dir_end()

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
