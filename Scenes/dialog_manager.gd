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
@export_group("Dialogue")
@export var current_dialogue : DialogueGroup

var dialogue_index := 0
var typing_tween : Tween

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

	
func append_character(character : String):
	text_box.text += character

	
func _ready() -> void:
	display_next_dialogue()

func set_dialogue_group(dialogue_group : DialogueGroup):
	current_dialogue = dialogue_group
	dialogue_index = 0
	display_next_dialogue()

func _on_click(event: InputEvent) -> void:
	var dialogue = current_dialogue.dialogue_list[dialogue_index-1]
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and !dialogue.is_choice:
		display_next_dialogue()

func _on_choice_1_pressed() -> void:
	var dialogue = current_dialogue.dialogue_list[dialogue_index-1]
	if dialogue.is_choice:
		set_dialogue_group(dialogue.result1)

func _on_choice_2_pressed() -> void:
	var dialogue = current_dialogue.dialogue_list[dialogue_index-1]
	if dialogue.is_choice:
		set_dialogue_group(dialogue.result2)
