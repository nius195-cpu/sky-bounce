class_name ProgressStore
extends RefCounted

static func load_file(path := "user://progress.cfg") -> ConfigFile:
	for candidate in [path, path + ".bak"]:
		var config := ConfigFile.new()
		if config.load(candidate) == OK:
			return config
	return ConfigFile.new()

static func write_file(config: ConfigFile, path := "user://progress.cfg") -> Error:
	var temporary := path + ".tmp"
	var result := config.save(temporary)
	if result != OK:
		return result
	var validated := ConfigFile.new()
	if validated.load(temporary) != OK:
		return ERR_FILE_CORRUPT
	var previous := ConfigFile.new()
	if previous.load(path) == OK:
		result = DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
		if result != OK:
			return result
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
