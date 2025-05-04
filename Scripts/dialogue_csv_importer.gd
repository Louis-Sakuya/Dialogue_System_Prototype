extends Node

# CSV文件格式应该包含以下列（可以按需调整）：
# group_id, dialogue_id, character_name, content, avatar_path, show_on_left, bg_path, image_path, 
# is_choice, choice1, result1_group, choice2, result2_group, soundeffect_path

# 用于存储已加载的对话组的字典
var dialogue_groups = {}
# 用于存储CSV行数据的字典
var dialogue_row_data = {}

# 导入CSV文件并创建DialogueGroup资源
func import_csv(csv_path: String) -> Dictionary:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		printerr("无法打开CSV文件：", csv_path)
		return {}
	
	# 读取标题行
	var headers = file.get_csv_line()
	
	# 创建临时存储对话的字典
	var dialogues_by_group = {}
	var group_order = {}
	dialogue_row_data.clear()
	
	# 读取每一行并创建Dialogue资源
	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2:  # 至少需要group_id和dialogue_id
			continue  # 跳过不完整的行
		
		# 创建一个字典来存储行数据
		var row_data = {}
		for i in range(min(headers.size(), line.size())):
			row_data[headers[i]] = line[i]
		
		# 获取group_id和dialogue_id
		var group_id = row_data.get("group_id", "")
		var dialogue_id_str = row_data.get("dialogue_id", "0")
		var dialogue_id = int(dialogue_id_str) if dialogue_id_str.is_valid_int() else 0
		
		# 确保组字典存在
		if !dialogues_by_group.has(group_id):
			dialogues_by_group[group_id] = {}
			group_order[group_id] = {}
		
		# 创建Dialogue资源
		var dialogue = Dialogue.new()
		dialogue.character_name = row_data.get("character_name", "")
		dialogue.content = row_data.get("content", "")
		
		# 加载头像纹理（如果指定）
		var avatar_path = row_data.get("avatar_path", "")
		if avatar_path != "":
			if ResourceLoader.exists(avatar_path):
				dialogue.avatar = load(avatar_path)
			else:
				printerr("无法加载头像资源：", avatar_path)
		
		# 其他属性
		dialogue.show_on_left = row_data.get("show_on_left", "false").to_lower() == "true"
		
		var bg_path = row_data.get("bg_path", "")
		if bg_path != "":
			if ResourceLoader.exists(bg_path):
				dialogue.BG = load(bg_path)
			else:
				printerr("无法加载背景资源：", bg_path)
		
		var image_path = row_data.get("image_path", "")
		if image_path != "":
			if ResourceLoader.exists(image_path):
				dialogue.image = load(image_path)
			else:
				printerr("无法加载图片资源：", image_path)
		
		dialogue.is_choice = row_data.get("is_choice", "false").to_lower() == "true"
		dialogue.choice1 = row_data.get("choice1", "")
		dialogue.choice2 = row_data.get("choice2", "")
		
		var bgm = row_data.get("bgm", "")
		dialogue.bgm = int(bgm) if bgm.is_valid_int() else 0
		dialogue.isEND = row_data.get("isEND", "false").to_lower() == "true"
		
		# 存储对话、对话ID和行数据
		dialogues_by_group[group_id][dialogue_id] = dialogue
		group_order[group_id][dialogue_id] = true
		
		# 存储行数据以便后续处理
		var key = group_id + "_" + str(dialogue_id)
		dialogue_row_data[key] = row_data
	
	file.close()
	
	# 创建DialogueGroup资源并填充对话
	for group_id in dialogues_by_group.keys():
		var dialogue_group = DialogueGroup.new()
		# 创建类型化数组
		var typed_array: Array[Dialogue] = []
		
		# 按照dialogue_id的顺序添加对话
		var ids = group_order[group_id].keys()
		ids.sort()
		for id in ids:
			typed_array.append(dialogues_by_group[group_id][id])
		
		# 使用类型化数组赋值
		dialogue_group.dialogue_list = typed_array
		dialogue_groups[group_id] = dialogue_group
	
	# 设置选择结果
	# 需要在所有DialogueGroup都创建完成后再处理
	for group_id in dialogues_by_group.keys():
		for dialogue_id in dialogues_by_group[group_id].keys():
			var dialogue = dialogues_by_group[group_id][dialogue_id]
			if dialogue.is_choice:
				var key = group_id + "_" + str(dialogue_id)
				var row_data = dialogue_row_data.get(key, {})
				
				var result1_group = row_data.get("result1_group", "")
				if result1_group != "" and dialogue_groups.has(result1_group):
					dialogue.result1 = dialogue_groups[result1_group]
				
				var result2_group = row_data.get("result2_group", "")
				if result2_group != "" and dialogue_groups.has(result2_group):
					dialogue.result2 = dialogue_groups[result2_group]
	
	return dialogue_groups

# 获取指定ID的对话组
func get_dialogue_group(group_id: String) -> DialogueGroup:
	if dialogue_groups.has(group_id):
		return dialogue_groups[group_id]
	return null

# 保存对话组资源到文件
func save_dialogue_groups(output_dir: String) -> void:
	if !DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)
	
	for group_id in dialogue_groups.keys():
		var dialogue_group = dialogue_groups[group_id]
		var save_path = output_dir + "/" + group_id + ".tres"
		var err = ResourceSaver.save(dialogue_group, save_path)
		if err != OK:
			printerr("保存对话组资源失败：", group_id, " 错误码：", err) 
