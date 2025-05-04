extends Node

# 支持的语言
enum Language {
    CHINESE,
    ENGLISH
}

# 当前语言
var current_language: Language = Language.CHINESE

# 翻译字典
var translations = {
    Language.CHINESE: {},
    Language.ENGLISH: {}
}

# 加载翻译文件时使用的信号
signal translations_loaded
signal language_changed(new_language)

func _ready() -> void:
    # 加载翻译文件
    load_translations()

# 加载翻译文件
func load_translations() -> void:
    # 加载菜单翻译
    load_menu_translations()
    
    # 加载对话翻译
    load_dialogue_translations()
    
    # 发出翻译加载完成信号
    emit_signal("translations_loaded")

# 加载菜单翻译
func load_menu_translations() -> void:
    # 中文菜单翻译
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
    
    # 英文菜单翻译
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
    translations[Language.ENGLISH]["menu_save_to_slot"] = "Game has been saved to slot"
    translations[Language.ENGLISH]["menu_no_save"] = "No Save Data"
    translations[Language.ENGLISH]["menu_main_menu"] = "Main Menu"

# 加载对话翻译
func load_dialogue_translations() -> void:
    # 从CSV文件加载对话翻译
    var csv_path = "res://Localization/dialogue_translations.csv"
    if FileAccess.file_exists(csv_path):
        var file = FileAccess.open(csv_path, FileAccess.READ)
        if file:
            # 读取标题行
            var headers = file.get_csv_line()
            
            # 读取每一行
            while !file.eof_reached():
                var line = file.get_csv_line()
                if line.size() < 3:  # 至少需要key, zh_CN, en_US三列
                    continue
                
                var key = line[0]
                var cn_text = line[1]
                var en_text = line[2]
                
                # 存储翻译
                translations[Language.CHINESE][key] = cn_text
                translations[Language.ENGLISH][key] = en_text

# 切换语言
func switch_language(language: Language) -> void:
    current_language = language
    emit_signal("language_changed", language)
    
    # 可以在这里保存语言设置到用户配置中
    save_language_setting()

# 保存语言设置
func save_language_setting() -> void:
    var config = ConfigFile.new()
    config.set_value("settings", "language", current_language)
    var error = config.save("user://settings.cfg")
    if error != OK:
        printerr("保存语言设置失败: ", error)

# 加载语言设置
func load_language_setting() -> void:
    var config = ConfigFile.new()
    var error = config.load("user://settings.cfg")
    if error == OK:
        var saved_language = config.get_value("settings", "language", Language.CHINESE)
        current_language = saved_language
    else:
        # 默认使用中文
        current_language = Language.CHINESE

# 获取翻译文本
func tr(key: String) -> String:
    if translations[current_language].has(key):
        return translations[current_language][key]
    
    # 如果没有找到翻译，返回键名
    return key

# 获取对话翻译
func get_dialogue_translation(group_id: String, dialogue_id: int, field: String) -> String:
    var key = "dialogue_%s_%d_%s" % [group_id, dialogue_id, field]
    return tr(key)
