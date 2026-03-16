extends Node
class_name GameSaveManager

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".dat"
const MAX_SAVES = 5
const MAX_LOG_ENTRIES = 200

func save_game(slot: int, dialogue_group_path: String, dialogue_index: int,
		affection_data: Dictionary = {}, dialogue_history: Array = []) -> bool:
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)

	# 限制 Log 条数避免存档过大
	var trimmed_history = dialogue_history
	if trimmed_history.size() > MAX_LOG_ENTRIES:
		trimmed_history = trimmed_history.slice(trimmed_history.size() - MAX_LOG_ENTRIES)

	var save_data = {
		"dialogue_group_path": dialogue_group_path,
		"dialogue_index": dialogue_index,
		"save_date": Time.get_datetime_string_from_system(),
		"affection_data": affection_data,
		"dialogue_history": trimmed_history,
	}

	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		printerr("保存游戏时出错: ", FileAccess.get_open_error())
		return false

	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	return true

func load_game(slot: int) -> Dictionary:
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION

	if !FileAccess.file_exists(file_path):
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("无法打开存档文件: ", file_path)
		return {}

	var content = file.get_as_text()
	file.close()

	if content.strip_edges() == "":
		printerr("存档文件内容为空: ", file_path)
		return {}

	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		printerr("解析存档数据出错: ", json.get_error_message(), " 位置: ", json.get_error_line())
		return {}

	return json.get_data()

func get_all_saves() -> Array:
	var saves = []

	if !DirAccess.dir_exists_absolute(SAVE_DIR):
		return saves

	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		printerr("无法打开存档目录: ", SAVE_DIR)
		return saves

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
			var slot = file_name.replace("save_", "").replace(SAVE_FILE_EXTENSION, "")
			if slot.is_valid_int():
				var save_data = load_game(int(slot))
				if !save_data.is_empty():
					save_data["slot"] = int(slot)
					saves.append(save_data)
		file_name = dir.get_next()

	return saves

func delete_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION

	if !FileAccess.file_exists(file_path):
		return false

	var dir = DirAccess.open("user://")
	if dir == null:
		return false

	var error = dir.remove(file_path)
	return error == OK
