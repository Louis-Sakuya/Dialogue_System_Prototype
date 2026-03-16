# AffectionChange - 好感值变化数据单元
# 用于记录单次好感值变化，可附加在对话或选项上
# character_id: 角色唯一标识符（如 "sakura", "hero"），需与 AffectionManager 中注册的角色一致
# value: 正数为增加好感，负数为减少好感
extends Resource
class_name AffectionChange

@export var character_id: String
@export var value: int
