class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://mind_pharmacy_save.json"
const SAVE_VERSION := 1


static func save_game(state: Dictionary) -> bool:
	var payload := state.duplicate(true)
	payload["schema_version"] = SAVE_VERSION
	payload["saved_at"] = Time.get_datetime_string_from_system(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true


static func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	if int(parsed.get("schema_version", -1)) != SAVE_VERSION:
		return {}
	return parsed


static func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
