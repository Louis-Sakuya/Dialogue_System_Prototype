# Dialogue - 单条对话数据资源
#
# 字段说明：
#   dialogue_id      : 对话唯一标识（用于本地化和存档引用）
#   character_name   : 说话角色名（默认语言）
#   content          : 对话正文（默认语言）
#   avatar           : 角色头像纹理（显示在对话框左/右侧）
#   show_on_left     : true=头像在左侧, false=右侧
#   BG               : 背景图纹理（留空则保持上一帧背景）
#   image            : 角色立绘纹理（显示在画面中央区域）
#   sprite_anim      : 立绘动画名称: "shake"/"bounce"/"fade_in"/"fade_out"/"zoom"/"slide_left"/"slide_right"/""
#   is_choice        : 是否为选项对话
#   choices          : 选项列表（仅 is_choice=true 时有效），数量不限
#   bgm              : BGM ID，>0 播放对应音乐, =0 停止, <0 保持当前
#   isEND            : 是否为剧情终点（触发结局流程）
#   affection_changes: 非选项对话触发的固定好感值变化
#   is_checkpoint    : 是否为章节存档点（通关后可从此处重新开始）
#   chapter_id       : 章节标识符（与 ChapterManager 对应）
#   chapter_name     : 章节显示名称
#   localization_key : 本地化键前缀（用于查找翻译文本）
extends Resource
class_name Dialogue

@export var dialogue_id: String
@export var character_name: String
@export_multiline var content: String
@export var avatar: Texture
@export var show_on_left: bool
@export var BG: Texture
@export var image: Texture
@export var sprite_anim: String
@export var is_choice: bool
@export var choices: Array[DialogueChoice] = []
@export var bgm: int = -1
@export var isEND: bool
@export var affection_changes: Array[AffectionChange] = []
@export var is_checkpoint: bool
@export var chapter_id: String
@export var chapter_name: String
@export var localization_key: String
