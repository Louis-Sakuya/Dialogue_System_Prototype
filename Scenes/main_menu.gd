extends Control

@export var new_game_button: Button
@export var load_game_button: Button
@export var settings_button: Button
@export var language_button: Button
@export var quit_button: Button
@export var chapter_select_button: Button
@export var title_label: Label

# 加载游戏面板
@export var load_game_panel: Panel
@export var save_slots_container: VBoxContainer
@export var back_button: Button

# 设置面板
@export var settings_panel: Panel
@export var settings_back_button: Button
@export var volume_slider: HSlider
@export var volume_label: Label

# 语言选择面板
@export var language_panel: Panel
@export var language_back_button: Button
@export var chinese_button: Button
@export var english_button: Button
@export var language_status_label: Label

# 章节选择面板
@export var chapter_panel: Panel
@export var chapter_container: VBoxContainer
@export var chapter_back_button: Button

var main_scene_path = "res://Scenes/main_scene.tscn"
var intro_dialogue_path = "res://Dialogues/intro.tres"
var save_manager: GameSaveManager

func _ready():
	save_manager = GameSaveManager.new()

	AudioManager.play_music(1)
	GlobalGameData.reset_dialogue_data()
	AffectionManager.reset()

	load_game_panel.visible = false
	settings_panel.visible = false
	language_panel.visible = false
	chapter_panel.visible = false

	# 章节选择按钮仅通关后可见
	if chapter_select_button:
		chapter_select_button.visible = ChapterManager.is_game_cleared()

	if volume_slider:
		var current_volume = AudioManager.get_master_volume()
		volume_slider.value = current_volume
		if volume_label:
			volume_label.text = LocalizationManager.get_text("menu_volume") + ": " + str(int(current_volume * 100)) + "%"
		volume_slider.value_changed.connect(_on_volume_slider_changed)

	# 语言按钮连接
	if chinese_button:
		chinese_button.pressed.connect(_on_chinese_pressed)
	if english_button:
		english_button.pressed.connect(_on_english_pressed)

	# 章节返回按钮
	if chapter_back_button:
		chapter_back_button.pressed.connect(_on_chapter_back_pressed)

	_update_ui_text()
	LocalizationManager.language_changed.connect(_on_language_changed)

func _update_ui_text() -> void:
	if title_label:
		title_label.text = LocalizationManager.get_text("game_title")
	if new_game_button:
		new_game_button.text = LocalizationManager.get_text("menu_new_game")
	if load_game_button:
		load_game_button.text = LocalizationManager.get_text("menu_load_game")
	if settings_button:
		settings_button.text = LocalizationManager.get_text("menu_settings")
	if language_button:
		language_button.text = LocalizationManager.get_text("menu_language")
	if quit_button:
		quit_button.text = LocalizationManager.get_text("menu_quit")
	if chapter_select_button:
		chapter_select_button.text = LocalizationManager.get_text("menu_chapter_select")

func _on_language_changed(_new_lang) -> void:
	_update_ui_text()

func _on_new_game_button_pressed() -> void:
	var global_data = {
		"is_loading": false,
		"dialogue_path": intro_dialogue_path,
		"dialogue_index": 0,
		"is_chapter_select": false,
		"affection_data": {},
		"dialogue_history": [],
	}
	GlobalGameData.set_dialogue_data(global_data)
	AffectionManager.reset()
	get_tree().change_scene_to_file(main_scene_path)

# ==================== 读档面板 ====================

func _on_load_game_pressed():
	load_game_panel.visible = true
	update_save_slots()

func update_save_slots():
	for child in save_slots_container.get_children():
		child.queue_free()

	var saves = save_manager.get_all_saves()

	if saves.size() == 0:
		var label = Label.new()
		label.text = LocalizationManager.get_text("menu_no_save")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_slots_container.add_child(label)
		return

	saves.sort_custom(func(a, b): return a.slot < b.slot)

	for save_data in saves:
		var button = Button.new()
		button.text = LocalizationManager.get_text("menu_save_slot") + " " + str(save_data.slot) + " - " + save_data.save_date
		button.custom_minimum_size = Vector2(300, 50)
		button.pressed.connect(func(): _on_save_slot_pressed(save_data.slot))
		save_slots_container.add_child(button)

func _on_save_slot_pressed(slot: int):
	var save_data = save_manager.load_game(slot)
	if save_data.is_empty():
		return

	var global_data = {
		"is_loading": true,
		"dialogue_path": save_data.dialogue_group_path,
		"dialogue_index": save_data.dialogue_index,
		"is_chapter_select": false,
		"affection_data": save_data.get("affection_data", {}),
		"dialogue_history": save_data.get("dialogue_history", []),
	}
	GlobalGameData.set_dialogue_data(global_data)
	get_tree().change_scene_to_file(main_scene_path)

# ==================== 设置面板 ====================

func _on_settings_pressed():
	settings_panel.visible = true

func _on_settings_back_pressed():
	settings_panel.visible = false

func _on_volume_slider_changed(value: float) -> void:
	AudioManager.set_master_volume(value)
	if volume_label:
		volume_label.text = LocalizationManager.get_text("menu_volume") + ": " + str(int(value * 100)) + "%"

# ==================== 语言面板 ====================

func _on_language_pressed():
	language_panel.visible = true
	if language_status_label:
		language_status_label.text = ""

func _on_language_back_pressed():
	language_panel.visible = false

func _on_chinese_pressed():
	LocalizationManager.switch_language(LocalizationManager.Language.CHINESE)
	if language_status_label:
		language_status_label.text = "已切换为中文"

func _on_english_pressed():
	LocalizationManager.switch_language(LocalizationManager.Language.ENGLISH)
	if language_status_label:
		language_status_label.text = "Switched to English"

# ==================== 章节选择面板 ====================

func _on_chapter_select_pressed():
	if not ChapterManager.is_game_cleared():
		return
	chapter_panel.visible = true
	_refresh_chapter_list()

func _on_chapter_back_pressed():
	chapter_panel.visible = false

func _refresh_chapter_list():
	for child in chapter_container.get_children():
		child.queue_free()

	var chapters = ChapterManager.get_unlocked_chapters()
	if chapters.size() == 0:
		var label = Label.new()
		label.text = LocalizationManager.get_text("menu_no_save")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chapter_container.add_child(label)
		return

	for chapter in chapters:
		var button = Button.new()
		button.text = chapter.chapter_name
		button.custom_minimum_size = Vector2(300, 50)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func(): _on_chapter_pressed(chapter))
		chapter_container.add_child(button)

func _on_chapter_pressed(chapter: Dictionary):
	var global_data = {
		"is_loading": true,
		"dialogue_path": chapter.dialogue_group_path,
		"dialogue_index": chapter.dialogue_index,
		"is_chapter_select": true,
		"affection_data": {},
		"dialogue_history": [],
	}
	GlobalGameData.set_dialogue_data(global_data)
	AffectionManager.reset()
	get_tree().change_scene_to_file(main_scene_path)

# ==================== 退出/返回 ====================

func _on_quit_pressed():
	get_tree().quit()

func _on_back_pressed():
	load_game_panel.visible = false
