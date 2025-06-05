@tool
extends EditorScript

func _run():
	var paths := []
	var dir = DirAccess.open("res://skills/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				paths.append("\"res://skills/%s\"" % file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

		var file = FileAccess.open("res://skills/skill_resource_list.gd", FileAccess.WRITE)
		file.store_line("const SKILL_RESOURCE_PATHS = [")
		for path in paths:
			file.store_line("\t%s," % path)
		file.store_line("]")
		file.close()
		print("Generated skill_resource_list.gd with %d entries" % paths.size())
