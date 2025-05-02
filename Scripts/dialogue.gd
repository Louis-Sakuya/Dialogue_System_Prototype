extends Resource
class_name Dialogue

@export var character_name : String
@export_multiline var content : String
@export var avatar : Texture
@export var show_on_left : bool
@export var BG : Texture
@export var image: Texture
@export var is_choice : bool
@export var choice1: String
@export var result1: DialogueGroup
@export var choice2: String
@export var result2: DialogueGroup
@export var soundeffect: AudioEffect
