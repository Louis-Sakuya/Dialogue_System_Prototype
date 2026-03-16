# AffectionManager - 好感值管理器 (Autoload 单例)
#
# 角色 ID 约定：
#   使用纯英文小写标识符，如 "sakura", "hero", "rival"
#   角色 ID 需在 CSV 的 affection_json / choices_json 中保持一致
#
# 使用方式：
#   AffectionManager.add_affection("sakura", 5)   # 增加好感
#   AffectionManager.get_affection("sakura")       # 查询好感
#   AffectionManager.get_ending_character()        # 获取好感最高角色（结局判定）
extends Node

signal affection_changed(character_id: String, new_value: int)

var _affection_data: Dictionary = {}

func add_affection(character_id: String, value: int) -> void:
	if not _affection_data.has(character_id):
		_affection_data[character_id] = 0
	_affection_data[character_id] += value
	affection_changed.emit(character_id, _affection_data[character_id])

func set_affection(character_id: String, value: int) -> void:
	_affection_data[character_id] = value
	affection_changed.emit(character_id, value)

func get_affection(character_id: String) -> int:
	return _affection_data.get(character_id, 0)

func get_all() -> Dictionary:
	return _affection_data.duplicate()

func get_ending_character() -> String:
	var best_char := ""
	var best_value := -999999
	for char_id in _affection_data:
		if _affection_data[char_id] > best_value:
			best_value = _affection_data[char_id]
			best_char = char_id
	return best_char

func apply_affection_changes(changes: Array) -> void:
	for change in changes:
		if change is AffectionChange:
			add_affection(change.character_id, change.value)

func load_from_dict(data: Dictionary) -> void:
	_affection_data = data.duplicate()

func save_to_dict() -> Dictionary:
	return _affection_data.duplicate()

func reset() -> void:
	_affection_data.clear()
