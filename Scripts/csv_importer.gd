extends Node

# 导入CSV对话的实例
var csv_importer = preload("res://Scripts/dialogue_csv_importer.gd").new()

# 重写ready函数来从CSV加载对话
func _ready() -> void:
	# 加载CSV对话
	var dialogue_groups = csv_importer.import_csv("res://Dialogues/Database/MainStory.csv")
	
	# 可选：保存生成的对话组资源
	csv_importer.save_dialogue_groups("res://Dialogues")

# 你可以添加一个方法来按ID获取对话组
func get_dialogue_group_by_id(group_id: String) -> DialogueGroup:
	return csv_importer.get_dialogue_group(group_id) 
