# DialogueChoice - 单个对话选项
#
# choice_text       : 选项显示文本（默认语言）
# result_group      : 选择后跳转的目标对话组
# affection_changes : 选择该选项后触发的好感值变化列表
# localization_key  : 本地化键，用于多语言切换时获取翻译后的选项文本
# condition         : 前置条件（可选），满足才可选择或改变结果。格式见下方
# lock_reason       : 条件不满足时显示的提示文本
# lock_reason_en    : 提示文本英文翻译
# fail_group        : 条件不满足但仍可选择时，跳转到的替代对话组（软锁定）
# fail_affection_changes : 软锁定选择时触发的好感值变化（可与正常路线不同）
#
# 锁定模式：
#   硬锁定：有 condition + 无 fail_group → 不满足时按钮置灰不可点击
#   软锁定：有 condition + 有 fail_group → 不满足时仍可点击，跳转 fail_group
#
# condition 格式（Dictionary）：
#   {"type": "affection", "char": "sakura", "op": ">=", "value": 10}
#   type     : 条件类型，目前支持 "affection"（好感值判定）
#   char     : 角色 ID
#   op       : 比较运算符 ">=" / ">" / "<=" / "<" / "==" / "!="
#   value    : 比较阈值（整数）
#
# 无条件时 condition 为空字典 {}，选项始终可选
extends Resource
class_name DialogueChoice

@export var choice_text: String
@export var result_group: DialogueGroup
@export var affection_changes: Array[AffectionChange] = []
@export var localization_key: String
@export var condition: Dictionary = {}
@export var lock_reason: String
@export var lock_reason_en: String
@export var fail_group: DialogueGroup
@export var fail_affection_changes: Array[AffectionChange] = []
