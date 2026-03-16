# DialogueChoice - 单个对话选项
# choice_text: 选项显示文本（默认语言）
# result_group: 选择后跳转的目标对话组
# affection_changes: 选择该选项后触发的好感值变化列表
# localization_key: 本地化键，用于多语言切换时获取翻译后的选项文本
extends Resource
class_name DialogueChoice

@export var choice_text: String
@export var result_group: DialogueGroup
@export var affection_changes: Array[AffectionChange] = []
@export var localization_key: String
