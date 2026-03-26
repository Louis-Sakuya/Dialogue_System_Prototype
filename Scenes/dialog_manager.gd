extends Control

@export_group("UI")
@export var character_name_label: Label
@export var text_box: Label
@export var left_avatar: TextureRect
@export var right_avatar: TextureRect
@export var bg: TextureRect
@export var image_container: HBoxContainer
@export var choice_box: VBoxContainer
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
@export var log_panel: Panel
@export var log_container: VBoxContainer
@export var log_back_button: Button

@export_group("Dialogue")
@export var current_dialogue: DialogueGroup

var dialogue_index := 0
var typing_tween: Tween
var sprite_anim_tween: Tween
var save_manager: GameSaveManager
var is_end_dialogue := false
var dialogue_history: Array[Dictionary] = []
var _container_original_pos: Vector2
var _container_original_scale: Vector2

func _ready() -> void:
	save_manager = GameSaveManager.new()

	save_panel.visible = false
	load_panel.visible = false
	settings_panel.visible = false
	log_panel.visible = false
	choice_box.visible = false

	if volume_slider:
		var current_volume = AudioManager.get_master_volume()
		volume_slider.value = current_volume
		if volume_label:
			volume_label.text = LocalizationManager.get_text("menu_volume") + ": " + str(int(current_volume * 100)) + "%"
		volume_slider.value_changed.connect(_on_volume_slider_changed)

	if settings_back_button:
		settings_back_button.pressed.connect(_on_settings_back_pressed)

	if log_back_button:
		log_back_button.pressed.connect(_on_log_back_pressed)

	var data = GlobalGameData.get_dialogue_data()
	if data.is_loading:
		var dialogue_resource = load(data.dialogue_path)
		if dialogue_resource:
			current_dialogue = dialogue_resource
			dialogue_index = data.dialogue_index - 1
		# 恢复好感值和 Log
		if data.has("affection_data") and data.affection_data is Dictionary:
			AffectionManager.load_from_dict(data.affection_data)
		if data.has("dialogue_history") and data.dialogue_history is Array:
			dialogue_history = []
			for item in data.dialogue_history:
				dialogue_history.append(item)

	# 记录立绘容器原始位置（用于动画归位）
	if image_container:
		_container_original_pos = image_container.position
		_container_original_scale = image_container.scale

	display_next_dialogue()

	set_process_input(true)
	focus_mode = Control.FOCUS_ALL
	grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		advance_dialogue_by_key()
		get_viewport().set_input_as_handled()

func advance_dialogue_by_key() -> void:
	if _is_any_panel_visible():
		return

	if dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
		var current_item = current_dialogue.dialogue_list[dialogue_index - 1]
		if current_item.is_choice:
			return

	if dialogue_index > 0 and dialogue_index >= len(current_dialogue.dialogue_list):
		if is_end_dialogue:
			_handle_game_end()
		else:
			display_next_dialogue()
	elif dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
		display_next_dialogue()

func _is_any_panel_visible() -> bool:
	return save_panel.visible or load_panel.visible or settings_panel.visible or log_panel.visible

# ==================== 核心对话推进 ====================

func display_next_dialogue():
	if dialogue_index >= len(current_dialogue.dialogue_list):
		if not is_end_dialogue and current_dialogue.next_group:
			set_dialogue_group(current_dialogue.next_group)
			return
		visible = false
		return

	var dialogue = current_dialogue.dialogue_list[dialogue_index]

	if typing_tween and typing_tween.is_running():
		typing_tween.kill()
		text_box.text = _get_localized_content(dialogue)
		dialogue_index += 1
	else:
		var display_content = _get_localized_content(dialogue)
		character_name_label.text = dialogue.character_name
		typing_tween = get_tree().create_tween()
		text_box.text = ""
		for character in display_content:
			typing_tween.tween_callback(append_character.bind(character)).set_delay(0.05)
		typing_tween.tween_callback(func(): dialogue_index += 1)

		# 头像
		if dialogue.show_on_left:
			left_avatar.texture = dialogue.avatar
			right_avatar.texture = null
		else:
			left_avatar.texture = null
			right_avatar.texture = dialogue.avatar

		# 背景（留空保持上一帧）
		if dialogue.BG:
			bg.texture = dialogue.BG

		# 立绘 + 动画
		_display_images(dialogue.images)
		if dialogue.images.size() > 0:
			_play_sprite_animation(dialogue.sprite_anim)
		

		# 选项
		if !dialogue.is_choice:
			choice_box.visible = false
		else:
			_show_dynamic_choices(dialogue)

		# 结局标记
		is_end_dialogue = dialogue.isEND

		# BGM
		if dialogue.bgm > 0:
			AudioManager.play_music(dialogue.bgm)
		elif dialogue.bgm == 0:
			AudioManager.fade_out_and_stop()

		# SFX
		if dialogue.sfx == "STOP":
			AudioManager.stop_sfx()
		elif dialogue.sfx != "":
			AudioManager.play_sfx(dialogue.sfx)

		# 好感值（非选项触发的固定变化）
		if dialogue.affection_changes.size() > 0:
			AffectionManager.apply_affection_changes(dialogue.affection_changes)

		# 章节检测
		if dialogue.is_checkpoint and dialogue.chapter_id != "":
			var group_path = current_dialogue.resource_path
			ChapterManager.unlock_chapter(dialogue.chapter_id, dialogue.chapter_name, group_path, dialogue_index)

		# 记录到 Log
		_record_to_log(dialogue.character_name, display_content, false)

func _get_localized_content(dialogue: Dialogue) -> String:
	if dialogue.localization_key != "":
		var translated = LocalizationManager.get_text(dialogue.localization_key)
		if translated != dialogue.localization_key:
			return translated
	return dialogue.content

func append_character(character: String):
	text_box.text += character

func set_dialogue_group(dialogue_group: DialogueGroup):
	current_dialogue = dialogue_group
	dialogue_index = 0
	is_end_dialogue = false
	display_next_dialogue()

# ==================== 动态选项系统 ====================

func _show_dynamic_choices(dialogue: Dialogue) -> void:
	# 清除旧按钮
	for child in choice_box.get_children():
		child.queue_free()

	choice_box.visible = true

	for i in range(dialogue.choices.size()):
		var choice = dialogue.choices[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 22)

		var is_unlocked = AffectionManager.check_condition(choice.condition)

		var display_text = choice.choice_text
		if choice.localization_key != "":
			var translated = LocalizationManager.get_text(choice.localization_key)
			if translated != choice.localization_key:
				display_text = translated

		if is_unlocked:
			button.text = display_text
			button.pressed.connect(_on_dynamic_choice_pressed.bind(choice, true))
		elif choice.fail_group:
			# 软锁定：可点击，但走失败分支
			var reason = _get_lock_reason_text(choice)
			button.text = display_text + "  [" + reason + "]"
			button.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
			button.pressed.connect(_on_dynamic_choice_pressed.bind(choice, false))
		else:
			# 硬锁定：不可点击
			var reason = _get_lock_reason_text(choice)
			button.text = "[" + reason + "]"
			button.disabled = true
			button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 0.7))

		choice_box.add_child(button)

func _on_dynamic_choice_pressed(choice: DialogueChoice, is_success: bool) -> void:
	_record_to_log("", choice.choice_text, true)

	if is_success:
		if choice.affection_changes.size() > 0:
			AffectionManager.apply_affection_changes(choice.affection_changes)
		if choice.result_group:
			set_dialogue_group(choice.result_group)
	else:
		if choice.fail_affection_changes.size() > 0:
			AffectionManager.apply_affection_changes(choice.fail_affection_changes)
		if choice.fail_group:
			set_dialogue_group(choice.fail_group)

func _get_lock_reason_text(choice: DialogueChoice) -> String:
	var reason = choice.lock_reason
	if choice.lock_reason_en != "":
		var translated = LocalizationManager.get_text(choice.lock_reason_en)
		if translated != choice.lock_reason_en:
			reason = translated
	if reason == "":
		reason = "???"
	return reason

# ==================== 立绘显示系统 ====================

func _display_images(textures: Array[Texture]) -> void:
	for child in image_container.get_children():
		child.queue_free()

	if textures.size() == 0:
		image_container.visible = false
		return

	image_container.visible = true
	for tex in textures:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		image_container.add_child(rect)

# ==================== 立绘动画系统 ====================

func _play_sprite_animation(anim_name: String) -> void:
	if sprite_anim_tween and sprite_anim_tween.is_running():
		sprite_anim_tween.kill()

	image_container.position = _container_original_pos
	image_container.scale = _container_original_scale
	image_container.modulate.a = 1.0

	if anim_name == "" or anim_name == "none":
		return

	sprite_anim_tween = create_tween()
	var target = image_container

	match anim_name:
		"shake":
			var orig_x = _container_original_pos.x
			sprite_anim_tween.tween_property(target, "position:x", orig_x + 10, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x - 10, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x + 8, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x - 8, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x + 4, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x - 4, 0.05)
			sprite_anim_tween.tween_property(target, "position:x", orig_x, 0.05)

		"bounce":
			var orig_y = _container_original_pos.y
			sprite_anim_tween.tween_property(target, "position:y", orig_y - 20, 0.15).set_ease(Tween.EASE_OUT)
			sprite_anim_tween.tween_property(target, "position:y", orig_y, 0.15).set_ease(Tween.EASE_IN)
			sprite_anim_tween.tween_property(target, "position:y", orig_y - 10, 0.1).set_ease(Tween.EASE_OUT)
			sprite_anim_tween.tween_property(target, "position:y", orig_y, 0.1).set_ease(Tween.EASE_IN)

		"fade_in":
			target.modulate.a = 0.0
			sprite_anim_tween.tween_property(target, "modulate:a", 1.0, 0.5)

		"fade_out":
			sprite_anim_tween.tween_property(target, "modulate:a", 0.0, 0.5)

		"zoom":
			var orig_scale = _container_original_scale
			sprite_anim_tween.tween_property(target, "scale", orig_scale * 1.15, 0.2).set_ease(Tween.EASE_OUT)
			sprite_anim_tween.tween_property(target, "scale", orig_scale, 0.3).set_ease(Tween.EASE_IN_OUT)

		"slide_left":
			target.position.x = _container_original_pos.x + 300
			sprite_anim_tween.tween_property(target, "position:x", _container_original_pos.x, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

		"slide_right":
			target.position.x = _container_original_pos.x - 300
			sprite_anim_tween.tween_property(target, "position:x", _container_original_pos.x, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

		_:
			printerr("未知的立绘动画: ", anim_name)

# ==================== Log 故事回溯系统 ====================

func _record_to_log(char_name: String, text: String, is_player_choice: bool) -> void:
	dialogue_history.append({
		"character_name": char_name,
		"content": text,
		"is_player_choice": is_player_choice,
	})

func _on_log_pressed() -> void:
	_refresh_log_panel()
	log_panel.visible = true

func _on_log_back_pressed() -> void:
	log_panel.visible = false

func _refresh_log_panel() -> void:
	for child in log_container.get_children():
		child.queue_free()

	for entry in dialogue_history:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var name_label = Label.new()
		name_label.custom_minimum_size = Vector2(120, 0)
		name_label.add_theme_font_size_override("font_size", 16)

		if entry.is_player_choice:
			name_label.text = "[" + LocalizationManager.get_text("log_player_choice") + "]"
			name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		else:
			name_label.text = entry.character_name
			name_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.5))

		var content_label = Label.new()
		content_label.text = entry.content
		content_label.add_theme_font_size_override("font_size", 16)
		content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		hbox.add_child(name_label)
		hbox.add_child(content_label)
		log_container.add_child(hbox)

		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 4)
		log_container.add_child(separator)

# ==================== 结局处理 ====================

func _handle_game_end() -> void:
	ChapterManager.mark_game_cleared()
	return_to_main_menu()

# ==================== 点击推进 ====================

func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if dialogue_index > 0 and dialogue_index >= len(current_dialogue.dialogue_list):
			if is_end_dialogue:
				_handle_game_end()
			else:
				display_next_dialogue()
		elif dialogue_index > 0 and dialogue_index <= len(current_dialogue.dialogue_list):
			var current_item = current_dialogue.dialogue_list[dialogue_index - 1]
			if !current_item.is_choice:
				display_next_dialogue()

# ==================== 存档/读档面板 ====================

func _on_save_pressed() -> void:
	save_panel.visible = true
	load_panel.visible = false
	update_save_slots()

func _on_load_pressed() -> void:
	save_panel.visible = false
	load_panel.visible = true
	update_load_slots()

func update_save_slots() -> void:
	for child in save_slots_container.get_children():
		child.queue_free()

	for i in range(1, 6):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 20)

		var save_data = save_manager.load_game(i)
		if !save_data.is_empty():
			button.text = LocalizationManager.get_text("menu_save_slot") + " " + str(i) + " (" + save_data.save_date + ")"
		else:
			button.text = LocalizationManager.get_text("menu_save_slot") + " " + str(i) + " (" + LocalizationManager.get_text("menu_save_empty") + ")"

		button.pressed.connect(func(): _on_save_slot_pressed(i))
		save_slots_container.add_child(button)

func update_load_slots() -> void:
	for child in load_slots_container.get_children():
		child.queue_free()

	for i in range(1, 6):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 20)

		var save_data = save_manager.load_game(i)
		if !save_data.is_empty():
			button.text = LocalizationManager.get_text("menu_save_slot") + " " + str(i) + " (" + save_data.save_date + ")"
			button.pressed.connect(func(): _on_load_slot_pressed(i))
		else:
			button.text = LocalizationManager.get_text("menu_save_slot") + " " + str(i) + " (" + LocalizationManager.get_text("menu_no_save") + ")"
			button.disabled = true

		load_slots_container.add_child(button)

func _on_save_slot_pressed(slot: int) -> void:
	var resource_path = current_dialogue.resource_path
	var success = save_manager.save_game(slot, resource_path, dialogue_index,
		AffectionManager.save_to_dict(), dialogue_history)

	if success:
		var popup = AcceptDialog.new()
		popup.title = LocalizationManager.get_text("menu_save_success")
		popup.dialog_text = LocalizationManager.get_text("menu_save_to_slot") + " " + str(slot)
		add_child(popup)
		popup.popup_centered()
		update_save_slots()

func _on_load_slot_pressed(slot: int) -> void:
	var save_data = save_manager.load_game(slot)
	if save_data.is_empty():
		return

	var dialogue_resource = load(save_data.dialogue_group_path)
	if dialogue_resource:
		current_dialogue = dialogue_resource
		dialogue_index = save_data.dialogue_index - 1
		is_end_dialogue = false

		# 恢复好感值
		if save_data.has("affection_data") and save_data.affection_data is Dictionary:
			AffectionManager.load_from_dict(save_data.affection_data)

		# 恢复 Log
		if save_data.has("dialogue_history") and save_data.dialogue_history is Array:
			dialogue_history = []
			for item in save_data.dialogue_history:
				dialogue_history.append(item)

		display_next_dialogue()
		save_panel.visible = false
		load_panel.visible = false

func _on_save_back_pressed() -> void:
	save_panel.visible = false

func _on_load_back_pressed() -> void:
	load_panel.visible = false

# ==================== 设置 / 主菜单 ====================

func _on_main_menu_pressed() -> void:
	return_to_main_menu()

func return_to_main_menu() -> void:
	if AudioManager:
		AudioManager.fade_out_and_stop()
	GlobalGameData.reset_dialogue_data()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_volume_slider_changed(value: float) -> void:
	AudioManager.set_master_volume(value)
	if volume_label:
		volume_label.text = LocalizationManager.get_text("menu_volume") + ": " + str(int(value * 100)) + "%"

func _on_setting_pressed() -> void:
	settings_panel.visible = true
	save_panel.visible = false
	load_panel.visible = false
	log_panel.visible = false

func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
