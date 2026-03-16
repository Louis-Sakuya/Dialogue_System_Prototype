# dialogue_csv_importer.gd - CSV 对话数据导入器
#
# ==================== CSV 列定义 ====================
#
# group_id        : 对话组 ID（同一 group_id 的行归为一个 DialogueGroup）
# dialogue_id     : 对话组内的序号（整数，用于排序）
# character_name  : 角色名（默认语言）
# content         : 对话正文（默认语言）
# content_en      : 对话正文英文翻译（可选，留空则使用 content）
# avatar_path     : 头像图片路径，如 res://assets/avatars/sakura.png
# show_on_left    : 头像显示在左侧 true/false
# bg_path         : 背景图路径，如 res://assets/BG/school.jpg（留空保持上一帧）
# image_path      : 立绘图路径，如 res://assets/sprites/sakura_happy.png
# sprite_anim     : 立绘动画名: shake/bounce/fade_in/fade_out/zoom/slide_left/slide_right（留空=无动画）
# is_choice       : 是否为选项对话 true/false
# choices_json    : 选项 JSON 数组，格式见下方示例（仅 is_choice=true 时填写）
# bgm             : BGM ID 整数，>0 播放, =0 停止, 留空或 <0 保持当前
# isEND           : 是否为剧情终点 true/false
# affection_json  : 非选项好感值变化 JSON 数组（可选）
# is_checkpoint   : 是否为章节节点 true/false
# chapter_id      : 章节 ID，如 ch_01（仅 is_checkpoint=true 时填写）
# chapter_name    : 章节显示名，如 "第一章 相遇"（仅 is_checkpoint=true 时填写）
#
# ==================== JSON 格式示例 ====================
#
# choices_json 示例:
#   [{"text":"帮助她","text_en":"Help her","result_group":"ch1_help","affection":[{"char":"sakura","value":5}]},
#    {"text":"走开","text_en":"Walk away","result_group":"ch1_leave","affection":[{"char":"sakura","value":-3}]},
#    {"text":"观望","text_en":"Watch","result_group":"ch1_watch","affection":[]}]
#
# affection_json 示例:
#   [{"char":"sakura","value":3},{"char":"rival","value":-1}]
#
# ==================== 素材路径约定 ====================
#
# 立绘:  res://assets/sprites/{角色名}_{表情}.png  (如 sakura_happy.png, sakura_sad.png)
# 头像:  res://assets/avatars/{角色名}.png
# 背景:  res://assets/BG/{场景名}.jpg
# 音乐:  通过 AudioManager BGM ID 引用，映射表在 audio_manager.gd 中定义
extends Node

var dialogue_groups = {}
var dialogue_row_data = {}

func import_csv(csv_path: String) -> Dictionary:
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		printerr("无法打开CSV文件：", csv_path)
		return {}

	var headers = file.get_csv_line()
	var dialogues_by_group = {}
	var group_order = {}
	dialogue_row_data.clear()

	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 2:
			continue

		var row_data = {}
		for i in range(min(headers.size(), line.size())):
			row_data[headers[i]] = line[i]

		var group_id = row_data.get("group_id", "")
		if group_id.strip_edges() == "":
			continue
		var dialogue_id_str = row_data.get("dialogue_id", "0")
		var dialogue_id = int(dialogue_id_str) if dialogue_id_str.is_valid_int() else 0

		if !dialogues_by_group.has(group_id):
			dialogues_by_group[group_id] = {}
			group_order[group_id] = {}

		var dialogue = Dialogue.new()
		dialogue.dialogue_id = group_id + "_" + str(dialogue_id)
		dialogue.character_name = row_data.get("character_name", "")
		dialogue.content = row_data.get("content", "")

		var avatar_path = row_data.get("avatar_path", "")
		if avatar_path != "":
			if ResourceLoader.exists(avatar_path):
				dialogue.avatar = load(avatar_path)
			else:
				printerr("无法加载头像资源：", avatar_path)

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
				printerr("无法加载立绘资源：", image_path)

		dialogue.sprite_anim = row_data.get("sprite_anim", "")
		dialogue.is_choice = row_data.get("is_choice", "false").to_lower() == "true"

		var bgm_str = row_data.get("bgm", "")
		dialogue.bgm = int(bgm_str) if bgm_str.is_valid_int() else -1
		dialogue.isEND = row_data.get("isEND", "false").to_lower() == "true"

		# 解析非选项好感值变化
		var affection_json_str = row_data.get("affection_json", "")
		if affection_json_str.strip_edges() != "":
			dialogue.affection_changes = _parse_affection_json(affection_json_str)

		# 章节标记
		dialogue.is_checkpoint = row_data.get("is_checkpoint", "false").to_lower() == "true"
		dialogue.chapter_id = row_data.get("chapter_id", "")
		dialogue.chapter_name = row_data.get("chapter_name", "")

		# 本地化键
		dialogue.localization_key = "dialogue_%s_%d" % [group_id, dialogue_id]

		dialogues_by_group[group_id][dialogue_id] = dialogue
		group_order[group_id][dialogue_id] = true
		var key = group_id + "_" + str(dialogue_id)
		dialogue_row_data[key] = row_data

	file.close()

	# 创建 DialogueGroup 资源
	for group_id in dialogues_by_group.keys():
		var dialogue_group = DialogueGroup.new()
		var typed_array: Array[Dialogue] = []
		var ids = group_order[group_id].keys()
		ids.sort()
		for id in ids:
			typed_array.append(dialogues_by_group[group_id][id])
		dialogue_group.dialogue_list = typed_array
		dialogue_groups[group_id] = dialogue_group

	# 第二遍：解析选项的 result_group 引用（需要所有 group 都已创建）
	for group_id in dialogues_by_group.keys():
		for dialogue_id in dialogues_by_group[group_id].keys():
			var dialogue = dialogues_by_group[group_id][dialogue_id]
			var key = group_id + "_" + str(dialogue_id)
			var row_data = dialogue_row_data.get(key, {})

			if dialogue.is_choice:
				var choices_json_str = row_data.get("choices_json", "")
				if choices_json_str.strip_edges() != "":
					dialogue.choices = _parse_choices_json(choices_json_str)
				else:
					# 兼容旧格式 choice1/choice2/result1_group/result2_group
					dialogue.choices = _parse_legacy_choices(row_data)

	return dialogue_groups

func _parse_choices_json(json_str: String) -> Array[DialogueChoice]:
	var result: Array[DialogueChoice] = []
	var json = JSON.new()
	if json.parse(json_str) != OK:
		printerr("解析 choices_json 失败: ", json.get_error_message())
		return result

	var data = json.get_data()
	if not data is Array:
		printerr("choices_json 格式错误，应为数组")
		return result

	for item in data:
		var choice = DialogueChoice.new()
		choice.choice_text = item.get("text", "")
		choice.localization_key = item.get("text_en", "")

		var result_group_id = item.get("result_group", "")
		if result_group_id != "" and dialogue_groups.has(result_group_id):
			choice.result_group = dialogue_groups[result_group_id]

		var affection_arr = item.get("affection", [])
		var changes: Array[AffectionChange] = []
		for aff in affection_arr:
			var change = AffectionChange.new()
			change.character_id = aff.get("char", "")
			change.value = int(aff.get("value", 0))
			changes.append(change)
		choice.affection_changes = changes

		result.append(choice)
	return result

func _parse_legacy_choices(row_data: Dictionary) -> Array[DialogueChoice]:
	var result: Array[DialogueChoice] = []

	var choice1_text = row_data.get("choice1", "")
	var result1_group = row_data.get("result1_group", "")
	if choice1_text != "":
		var c1 = DialogueChoice.new()
		c1.choice_text = choice1_text
		if result1_group != "" and dialogue_groups.has(result1_group):
			c1.result_group = dialogue_groups[result1_group]
		result.append(c1)

	var choice2_text = row_data.get("choice2", "")
	var result2_group = row_data.get("result2_group", "")
	if choice2_text != "":
		var c2 = DialogueChoice.new()
		c2.choice_text = choice2_text
		if result2_group != "" and dialogue_groups.has(result2_group):
			c2.result_group = dialogue_groups[result2_group]
		result.append(c2)

	return result

func _parse_affection_json(json_str: String) -> Array[AffectionChange]:
	var result: Array[AffectionChange] = []
	var json = JSON.new()
	if json.parse(json_str) != OK:
		printerr("解析 affection_json 失败: ", json.get_error_message())
		return result

	var data = json.get_data()
	if not data is Array:
		return result

	for item in data:
		var change = AffectionChange.new()
		change.character_id = item.get("char", "")
		change.value = int(item.get("value", 0))
		result.append(change)
	return result

func get_dialogue_group(group_id: String) -> DialogueGroup:
	if dialogue_groups.has(group_id):
		return dialogue_groups[group_id]
	return null

func save_dialogue_groups(output_dir: String) -> void:
	if !DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	for group_id in dialogue_groups.keys():
		var dialogue_group = dialogue_groups[group_id]
		var save_path = output_dir + "/" + group_id + ".tres"
		var err = ResourceSaver.save(dialogue_group, save_path)
		if err != OK:
			printerr("保存对话组资源失败：", group_id, " 错误码：", err)
