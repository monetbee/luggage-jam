extends RefCounted
class_name LevelManager

const LEVELS_DIR := "res://data/levels/"

static func level_path(level_number: int) -> String:
	return LEVELS_DIR + "level_%03d.json" % level_number


static func load_level(level_number: int) -> Dictionary:
	var path := level_path(level_number)
	if not FileAccess.file_exists(path):
		return {
			"id": level_number,
			"name": "Level %d" % level_number,
			"size": 6,
			"luggages": [],
			"walls": [],
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"id": level_number,
			"name": "Level %d" % level_number,
			"size": 6,
			"luggages": [],
			"walls": [],
		}

	var json_text := file.get_as_text()
	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	return {
		"id": level_number,
		"name": "Level %d" % level_number,
		"size": 6,
		"luggages": [],
		"walls": [],
	}
