extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://luggage_jam_save.json"

static func load_save() -> Dictionary:
	var default_save := {
		"coins": 0,
		"highest_level": 1,
		"current_level": 1,
	}

	if not FileAccess.file_exists(SAVE_PATH):
		return default_save

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_save

	var json_text := file.get_as_text().strip_edges()
	if json_text.is_empty():
		return default_save

	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	return default_save


static func save(save_data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data))
