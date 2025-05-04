extends Node
class_name GameSaveManager

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".dat"
const MAX_SAVES = 5

# 保存对话状态
func save_game(slot: int, dialogue_group_path: String, dialogue_index: int) -> bool:
	# 确保目录存在
	var dir = DirAccess.open("user://")
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir(SAVE_DIR)
	
	# 准备保存数据
	var save_data = {
		"dialogue_group_path": dialogue_group_path,
		"dialogue_index": dialogue_index,
		"save_date": Time.get_datetime_string_from_system()
	}
	
	# 保存到文件
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	
	# 使用FileAccess正确打开文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		printerr("保存游戏时出错: ", error)
		return false
	
	# 使用JSON正确存储数据
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	return true

# 加载对话状态
func load_game(slot: int) -> Dictionary:
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	
	if !FileAccess.file_exists(file_path):
		# 这是正常情况，如果是检查存档是否存在，不需要打印错误
		if slot > 1: # 仅对首次检查存档2-5时不打印错误
			return {}
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("无法打开存档文件: ", file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	# 检查文件内容是否为空
	if content.strip_edges() == "":
		printerr("存档文件内容为空: ", file_path)
		return {}
	
	# 正确解析JSON
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK:
		printerr("解析存档数据出错: ", json.get_error_message(), " 位置: ", json.get_error_line(), "\n内容: ", content)
		return {}
	
	return json.get_data()

# 获取所有存档信息
func get_all_saves() -> Array:
	var saves = []
	
	# 确保目录存在
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

# 删除存档
func delete_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "save_" + str(slot) + SAVE_FILE_EXTENSION
	
	if !FileAccess.file_exists(file_path):
		return false
	
	var dir = DirAccess.open("user://")
	if dir == null:
		return false
		
	var error = dir.remove(file_path)
	
	return error == OK
