# LocalizationManager - 多语言本地化管理器 (Autoload 单例)
#
# 支持两种翻译来源：
#   1. 内置菜单翻译（硬编码在 load_menu_translations 中）
#   2. CSV 文件翻译（从 res://Localization/dialogue_translations.csv 加载）
#
# 使用方式：
#   LocalizationManager.get_text("menu_new_game")      # 获取 UI 文本翻译
#   LocalizationManager.switch_language(Language.ENGLISH)  # 切换语言
#
# 添加新语言：
#   1. 在 Language 枚举中增加新语言
#   2. 在 load_menu_translations() 中添加对应翻译
#   3. 在 CSV 中增加新的语言列
extends Node

enum Language {
	CHINESE,
	ENGLISH
}

var current_language: Language = Language.CHINESE

var translations = {
	Language.CHINESE: {},
	Language.ENGLISH: {}
}

signal translations_loaded
signal language_changed(new_language)

func _ready() -> void:
	load_language_setting()
	load_translations()

func load_translations() -> void:
	load_menu_translations()
	load_dialogue_translations()
	translations_loaded.emit()

func load_menu_translations() -> void:
	# 中文
	translations[Language.CHINESE]["game_title"] = "视觉小说构造器"
	translations[Language.CHINESE]["menu_new_game"] = "新游戏"
	translations[Language.CHINESE]["menu_load_game"] = "读取游戏"
	translations[Language.CHINESE]["menu_settings"] = "设置"
	translations[Language.CHINESE]["menu_language"] = "语言"
	translations[Language.CHINESE]["menu_quit"] = "退出"
	translations[Language.CHINESE]["menu_back"] = "返回"
	translations[Language.CHINESE]["menu_volume"] = "音量"
	translations[Language.CHINESE]["menu_save_game"] = "保存游戏"
	translations[Language.CHINESE]["menu_save_slot"] = "存档位置"
	translations[Language.CHINESE]["menu_save_empty"] = "空"
	translations[Language.CHINESE]["menu_save_success"] = "保存成功"
	translations[Language.CHINESE]["menu_save_to_slot"] = "游戏已成功保存到槽位"
	translations[Language.CHINESE]["menu_no_save"] = "无存档"
	translations[Language.CHINESE]["menu_main_menu"] = "主菜单"
	translations[Language.CHINESE]["menu_log"] = "回顾"
	translations[Language.CHINESE]["menu_chapter_select"] = "章节选择"
	translations[Language.CHINESE]["menu_chapter_locked"] = "通关后解锁"
	translations[Language.CHINESE]["log_title"] = "对话记录"
	translations[Language.CHINESE]["log_player_choice"] = "你的选择"
	translations[Language.CHINESE]["chapter_select_title"] = "章节选择"
	translations[Language.CHINESE]["menu_save"] = "保存"
	translations[Language.CHINESE]["menu_load"] = "读取"
	translations[Language.CHINESE]["menu_read_game"] = "读取游戏"
	translations[Language.CHINESE]["menu_select_language"] = "选择语言"
	translations[Language.CHINESE]["menu_lang_coming_soon"] = "语言选择功能将在后续版本实现"

	# 英文
	translations[Language.ENGLISH]["game_title"] = "Visual Novel Game Creator"
	translations[Language.ENGLISH]["menu_new_game"] = "New Game"
	translations[Language.ENGLISH]["menu_load_game"] = "Load Game"
	translations[Language.ENGLISH]["menu_settings"] = "Settings"
	translations[Language.ENGLISH]["menu_language"] = "Language"
	translations[Language.ENGLISH]["menu_quit"] = "Quit"
	translations[Language.ENGLISH]["menu_back"] = "Back"
	translations[Language.ENGLISH]["menu_volume"] = "Volume"
	translations[Language.ENGLISH]["menu_save_game"] = "Save Game"
	translations[Language.ENGLISH]["menu_save_slot"] = "Save Slot"
	translations[Language.ENGLISH]["menu_save_empty"] = "Empty"
	translations[Language.ENGLISH]["menu_save_success"] = "Save Successful"
	translations[Language.ENGLISH]["menu_save_to_slot"] = "Game saved to slot"
	translations[Language.ENGLISH]["menu_no_save"] = "No Save Data"
	translations[Language.ENGLISH]["menu_main_menu"] = "Main Menu"
	translations[Language.ENGLISH]["menu_log"] = "Log"
	translations[Language.ENGLISH]["menu_chapter_select"] = "Chapter Select"
	translations[Language.ENGLISH]["menu_chapter_locked"] = "Clear game to unlock"
	translations[Language.ENGLISH]["log_title"] = "Dialogue Log"
	translations[Language.ENGLISH]["log_player_choice"] = "Your Choice"
	translations[Language.ENGLISH]["chapter_select_title"] = "Chapter Select"
	translations[Language.ENGLISH]["menu_save"] = "Save"
	translations[Language.ENGLISH]["menu_load"] = "Load"
	translations[Language.ENGLISH]["menu_read_game"] = "Load Game"
	translations[Language.ENGLISH]["menu_select_language"] = "Select Language"
	translations[Language.ENGLISH]["menu_lang_coming_soon"] = "Language selection will be available in future versions"

func load_dialogue_translations() -> void:
	var csv_path = "res://Localization/dialogue_translations.csv"
	if not FileAccess.file_exists(csv_path):
		return
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		return

	var headers = file.get_csv_line()

	while !file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 3:
			continue
		var key = line[0]
		var cn_text = line[1]
		var en_text = line[2]
		translations[Language.CHINESE][key] = cn_text
		translations[Language.ENGLISH][key] = en_text

func switch_language(language: Language) -> void:
	current_language = language
	language_changed.emit(language)
	save_language_setting()

func save_language_setting() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "language", current_language)
	var error = config.save("user://settings.cfg")
	if error != OK:
		printerr("保存语言设置失败: ", error)

func load_language_setting() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	if error == OK:
		current_language = config.get_value("settings", "language", Language.CHINESE)
	else:
		current_language = Language.CHINESE

func get_text(key: String) -> String:
	if translations[current_language].has(key):
		return translations[current_language][key]
	return key

func get_dialogue_translation(group_id: String, dialogue_id: int, field: String) -> String:
	var key = "dialogue_%s_%d_%s" % [group_id, dialogue_id, field]
	return get_text(key)
