extends Control

# 菜单按钮
@export var new_game_button: Button
@export var load_game_button: Button
@export var settings_button: Button
@export var language_button: Button
@export var quit_button: Button

# 加载游戏面板
@export var load_game_panel: Panel
@export var save_slots_container: VBoxContainer
@export var save_slot_button: PackedScene
@export var back_button: Button

# 设置面板
@export var settings_panel: Panel
@export var settings_back_button: Button

# 语言选择面板  
@export var language_panel: Panel
@export var language_back_button: Button

# 在main_menu.gd中添加设置面板相关导出变量
@export var volume_slider: HSlider
@export var volume_label: Label

var main_scene_path = "res://Scenes/main_scene.tscn"
var intro_dialogue_path = "res://Dialogues/intro.tres"
var save_manager: GameSaveManager

func _ready():
	save_manager = GameSaveManager.new()
	
	AudioManager.play_music(1)
	GlobalGameData.reset_dialogue_data()
	# 初始化隐藏所有面板
	load_game_panel.visible = false
	settings_panel.visible = false
	language_panel.visible = false
	
	# 如果有音量滑块，设置它的初始值和连接信号
	if volume_slider:
		# 获取当前音量并设置滑块初始值
		var current_volume = AudioManager.get_master_volume()
		volume_slider.value = current_volume
		
		# 更新音量标签
		if volume_label:
			volume_label.text = "音量: " + str(int(current_volume * 100)) + "%"
		
		# 连接滑块值变化信号
		volume_slider.value_changed.connect(_on_volume_slider_changed)

func _on_new_game_button_pressed() -> void:
	# 设置全局对话数据
	var global_data = {
		"is_loading": false,
		"dialogue_path": intro_dialogue_path,
		"dialogue_index": 0
	}
	
	# 将数据存储到全局单例
	GlobalGameData.set_dialogue_data(global_data)
	
	# 完全释放当前场景并切换到主场景
	get_tree().change_scene_to_file(main_scene_path)

# 打开加载游戏面板
func _on_load_game_pressed():
	# 显示加载游戏面板
	load_game_panel.visible = true
	update_save_slots()

# 更新存档槽列表
func update_save_slots():
	# 清除现有存档按钮
	for child in save_slots_container.get_children():
		child.queue_free()
	
	# 获取所有存档并创建按钮
	var saves = save_manager.get_all_saves()
	
	# 如果没有存档，显示提示
	if saves.size() == 0:
		var label = Label.new()
		label.text = "没有找到存档"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_slots_container.add_child(label)
		return
	
	# 按槽位排序
	saves.sort_custom(func(a, b): return a.slot < b.slot)
	
	# 为每个存档创建按钮
	for save_data in saves:
		var button = Button.new()
		button.text = "存档 " + str(save_data.slot) + " - " + save_data.save_date
		button.custom_minimum_size = Vector2(300, 50)
		
		# 连接点击事件
		button.pressed.connect(func(): _on_save_slot_pressed(save_data.slot))
		
		save_slots_container.add_child(button)

# 加载选中的存档
func _on_save_slot_pressed(slot: int):
	var save_data = save_manager.load_game(slot)
	print("读取存档", slot)
	print(save_data)
	if save_data.is_empty():
		return
	
	# 设置全局加载数据
	var global_data = {
		"is_loading": true,
		"dialogue_path": save_data.dialogue_group_path,
		"dialogue_index": save_data.dialogue_index
	}
	
	# 将数据存储到全局单例
	GlobalGameData.set_dialogue_data(global_data)
	
	# 完全释放当前场景并切换到主场景
	get_tree().change_scene_to_file(main_scene_path)

# 打开设置面板
func _on_settings_pressed():
	settings_panel.visible = true

# 打开语言选择面板
func _on_language_pressed():
	language_panel.visible = true

# 退出游戏
func _on_quit_pressed():
	get_tree().quit()

# 从加载面板返回
func _on_back_pressed():
	load_game_panel.visible = false

# 从设置面板返回
func _on_settings_back_pressed():
	settings_panel.visible = false

# 从语言面板返回
func _on_language_back_pressed():
	language_panel.visible = false

# 处理音量滑块值变化
func _on_volume_slider_changed(value: float) -> void:
	# 设置主音量
	AudioManager.set_master_volume(value)
	
	# 更新音量标签
	if volume_label:
		volume_label.text = "音量: " + str(int(value * 100)) + "%"
