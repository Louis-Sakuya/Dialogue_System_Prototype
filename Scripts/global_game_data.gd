extends Node

# 对话加载数据
var dialogue_data = {
	"is_loading": false,
	"dialogue_path": "",
	"dialogue_index": 0
}

func set_dialogue_data(data: Dictionary):
	dialogue_data = data

func get_dialogue_data() -> Dictionary:
	return dialogue_data

func reset_dialogue_data():
	dialogue_data = {
		"is_loading": false,
		"dialogue_path": "",
		"dialogue_index": 0
	}
