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


func display_next_dialogue():
	if dialogue_index >= len(current_dialogue.dialogue_list):
		visible = false
		return
	var dialogue = current_dialogue.dialogue_list[dialogue_index]
	
	character_name_label.text = dialogue.character_name
	
	
	text_box.text = dialogue.content
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
	dialogue_index += 1
	
func _ready() -> void:
	display_next_dialogue()

func _on_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		display_next_dialogue()
