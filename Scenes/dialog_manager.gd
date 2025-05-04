extends Control

@export_group("UI")
@export var character_name_label : Label 
@export var text_box : Label
@export var left_avatar : TextureRect
@export var right_avatar : TextureRect
@export var bg : TextureRect
@export var image : TextureRect
@export var choice_box : VBoxContainer
@export var choice1: Button
@export var choice2: Button
@export var save_panel: Panel
@export var load_panel: Panel
@export var save_slots_container: VBoxContainer
@export var load_slots_container: VBoxContainer
@export var save_back_button: Button
@export var load_back_button: Button
@export var main_menu_button: Button
@export var settings_panel: Panel
@export var volume_slider: HSlider
@export var volume_label: Label
@export var settings_back_button: Button
@export_group("Dialogue")
@export var current_dialogue : DialogueGroup

var dialogue_index := 0
var typing_tween : Tween
var save_manager: GameSaveManager
var is_end_dialogue := false  # 标记当前对话是否为结束对话
var is_any_panel_visible := false  # 标记是否有面板正在显示

func _ready() -> void:
	save_manager = GameSaveManager.new()
	
	# 初始化UI
	save_panel.visible = false
	load_panel.visible = false
	
	# 初始化设置面板
	settings_panel.visible = false
	
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
	
	# 连接设置返回按钮信号
	if settings_back_button:
		settings_back_button.pressed.connect(_on_settings_back_pressed)
	
	var data = GlobalGameData.get_dialogue_data()
	if data.is_loading:
		# 加载对话
		var dialogue_resource = load(data.dialogue_path)
		if dialogue_resource:
			current_dialogue = dialogue_resource
			dialogue_index = data.dialogue_index-1
	display_next_dialogue()
	
	# 设置为可聚焦，以便接收键盘事件
	set_process_input(true)
	focus_mode = Control.FOCUS_ALL
	grab_focus()

# 重写_input函数以处理键盘输入
func _input(event: InputEvent) -> void:
	# 检查是否按下空格键
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# 如果是空格键，尝试显示下一对话，但要排除选项对话和面板显示的情况
		advance_dialogue_by_key()
		# 阻止事件传递给其他控件
		get_viewport().set_input_as_handled()

# 通过按键前进对话
func advance_dialogue_by_key() -> void:
	# 如果有任何面板可见，不处理按键
	if save_panel.visible or load_panel.visible or settings_panel.visible:
		return
		
	# 如果当前对话是选项对话，不处理空格键
	if dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
		var current_dialogue_item = current_dialogue.dialogue_list[dialogue_index-1]
		if current_dialogue_item.is_choice:
			return
	
	# 检查是否为最后一句对话且标记为结束
	if dialogue_index > 0 and dialogue_index >= len(current_dialogue.dialogue_list) and is_end_dialogue:
		# 如果是结束对话，返回主菜单
		return_to_main_menu()
	elif dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
		# 显示下一对话
		display_next_dialogue()

func display_next_dialogue():
	if dialogue_index >= len(current_dialogue.dialogue_list):
		visible = false
		return
	var dialogue = current_dialogue.dialogue_list[dialogue_index]
		
	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		text_box.text = dialogue.content
		dialogue_index += 1
	else:
		character_name_label.text = dialogue.character_name
		typing_tween = get_tree().create_tween()
		text_box.text = ""
		for character in dialogue.content:
			typing_tween.tween_callback(append_character.bind(character)).set_delay(0.05)
		typing_tween.tween_callback(func(): dialogue_index += 1)
		
		if dialogue.show_on_left:
			left_avatar.texture = dialogue.avatar
			right_avatar.texture = null
		else: 
			left_avatar.texture = null
			right_avatar.texture = dialogue.avatar
		bg.texture = dialogue.BG
		image.texture = dialogue.image
		if !dialogue.is_choice:
			choice_box.visible = false
		else:
			choice_box.visible = true
			choice1.text = dialogue.choice1
			choice2.text = dialogue.choice2
		
		# 检查是否为结束对话
		is_end_dialogue = dialogue.get("isEND") == true
		
		# 处理BGM
		if dialogue.get("bgm") > 0:
			AudioManager.play_music(dialogue.bgm)
		elif dialogue.get("bgm") == 0:
			AudioManager.fade_out_and_stop()
			
func append_character(character : String):
	text_box.text += character

func set_dialogue_group(dialogue_group : DialogueGroup):
	current_dialogue = dialogue_group
	dialogue_index = 0
	is_end_dialogue = false  # 重置结束标记
	display_next_dialogue()

func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# 检查是否为最后一句对话且标记为结束
		if dialogue_index > 0 and dialogue_index >= len(current_dialogue.dialogue_list) and is_end_dialogue:
			# 如果是结束对话，点击后返回主菜单
			return_to_main_menu()
		elif dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
			# 检查当前显示的对话是否为选择项
			var current_dialogue_item = current_dialogue.dialogue_list[dialogue_index-1]
			if !current_dialogue_item.is_choice:
				display_next_dialogue()

func _on_choice_1_pressed() -> void:
	var dialogue = current_dialogue.dialogue_list[dialogue_index-1]
	if dialogue.is_choice:
		set_dialogue_group(dialogue.result1)

func _on_choice_2_pressed() -> void:
	var dialogue = current_dialogue.dialogue_list[dialogue_index-1]
	if dialogue.is_choice:
		set_dialogue_group(dialogue.result2)

# 打开保存面板
func _on_save_pressed() -> void:
	save_panel.visible = true
	load_panel.visible = false
	update_save_slots()

# 打开加载面板
func _on_load_pressed() -> void:
	save_panel.visible = false
	load_panel.visible = true
	update_load_slots()

# 更新保存槽
func update_save_slots() -> void:
	# 清除现有按钮
	for child in save_slots_container.get_children():
		child.queue_free()
	
	# 创建5个保存槽按钮
	for i in range(1, 6):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		
		# 正确设置字体大小
		var font_size = 20
		button.add_theme_font_size_override("font_size", font_size)
		
		# 检查存档是否存在
		var save_data = save_manager.load_game(i)
		if !save_data.is_empty():
			button.text = "存档位置 " + str(i) + " (" + save_data.save_date + ")"
		else:
			button.text = "存档位置 " + str(i) + " (空)"
		
		# 连接点击事件
		button.pressed.connect(func(): _on_save_slot_pressed(i))
		
		save_slots_container.add_child(button)

# 更新加载槽
func update_load_slots() -> void:
	# 清除现有按钮
	for child in load_slots_container.get_children():
		child.queue_free()
	
	# 创建5个加载槽按钮
	for i in range(1, 6):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		
		# 正确设置字体大小
		var font_size = 20
		button.add_theme_font_size_override("font_size", font_size)
		
		# 检查存档是否存在
		var save_data = save_manager.load_game(i)
		if !save_data.is_empty():
			button.text = "存档位置 " + str(i) + " (" + save_data.save_date + ")"
			# 有存档时可以点击
			button.pressed.connect(func(): _on_load_slot_pressed(i))
		else:
			button.text = "存档位置 " + str(i) + " (无存档)"
			button.disabled = true
		
		load_slots_container.add_child(button)

# 保存到选中的槽位
func _on_save_slot_pressed(slot: int) -> void:
	# 获取当前对话资源的路径
	var resource_path = current_dialogue.resource_path
	
	# 保存游戏状态
	var success = save_manager.save_game(slot, resource_path, dialogue_index)
	
	if success:
		# 显示保存成功提示
		var popup = AcceptDialog.new()
		popup.title = "保存成功"
		popup.dialog_text = "游戏已成功保存到槽位 " + str(slot)
		add_child(popup)
		popup.popup_centered()
		
		# 更新保存槽列表
		update_save_slots()

# 加载选中的存档
func _on_load_slot_pressed(slot: int) -> void:
	var save_data = save_manager.load_game(slot)
	if save_data.is_empty():
		return
	
	# 加载对话组
	var dialogue_resource = load(save_data.dialogue_group_path)
	if dialogue_resource:
		current_dialogue = dialogue_resource
		# 将保存的索引赋值给dialogue_index变量
		# 注意：我们需要减去1，因为display_next_dialogue会将索引加1
		dialogue_index = save_data.dialogue_index - 1
		is_end_dialogue = false  # 重置结束标记
		
		# 重新显示对话
		display_next_dialogue()
		
		# 隐藏面板
		save_panel.visible = false
		load_panel.visible = false

# 从保存面板返回
func _on_save_back_pressed() -> void:
	save_panel.visible = false

# 从加载面板返回
func _on_load_back_pressed() -> void:
	load_panel.visible = false

# 返回主菜单
func _on_main_menu_pressed() -> void:
	return_to_main_menu()

# 统一处理返回主菜单的逻辑
func return_to_main_menu() -> void:
	# 停止所有音乐
	if AudioManager:
		AudioManager.fade_out_and_stop()
	
	# 重置全局对话数据
	GlobalGameData.reset_dialogue_data()
	
	# 使用change_scene_to_file完全释放当前场景并切换到主菜单
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
	# 强制垃圾回收
	Engine.get_main_loop().call_deferred("garbage_collect")

# 处理音量滑块值变化
func _on_volume_slider_changed(value: float) -> void:
	# 设置主音量
	AudioManager.set_master_volume(value)
	
	# 更新音量标签
	if volume_label:
		volume_label.text = "音量: " + str(int(value * 100)) + "%"

# 打开设置面板
func _on_setting_pressed() -> void:
	settings_panel.visible = true
	save_panel.visible = false
	load_panel.visible = false

# 从设置面板返回
func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
