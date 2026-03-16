# ChapterManager - 章节管理器 (Autoload 单例)
#
# 章节 ID 约定：
#   使用 "ch_01", "ch_02" 等格式标识章节
#   在 CSV 中通过 is_checkpoint=true, chapter_id, chapter_name 定义章节节点
#   通关后（isEND=true 被触发），所有经过的章节自动解锁
#
# 使用方式：
#   ChapterManager.unlock_chapter("ch_01", "序章", "res://Dialogues/intro.tres", 0)
#   ChapterManager.get_unlocked_chapters()  # 获取可选章节列表
#   ChapterManager.is_game_cleared()        # 是否已通关
extends Node

const SAVE_PATH = "user://chapter_progress.cfg"

signal chapter_unlocked(chapter_id: String)
signal game_cleared

var _unlocked_chapters: Dictionary = {}
var _game_cleared: bool = false

func _ready() -> void:
	_load_progress()

func unlock_chapter(chapter_id: String, chapter_name: String, dialogue_group_path: String, dialogue_index: int) -> void:
	if _unlocked_chapters.has(chapter_id):
		return
	_unlocked_chapters[chapter_id] = {
		"chapter_id": chapter_id,
		"chapter_name": chapter_name,
		"dialogue_group_path": dialogue_group_path,
		"dialogue_index": dialogue_index
	}
	chapter_unlocked.emit(chapter_id)
	_save_progress()

func mark_game_cleared() -> void:
	if not _game_cleared:
		_game_cleared = true
		game_cleared.emit()
		_save_progress()

func is_game_cleared() -> bool:
	return _game_cleared

func get_unlocked_chapters() -> Array:
	var chapters := []
	for key in _unlocked_chapters:
		chapters.append(_unlocked_chapters[key])
	chapters.sort_custom(func(a, b): return a.chapter_id < b.chapter_id)
	return chapters

func is_chapter_unlocked(chapter_id: String) -> bool:
	return _unlocked_chapters.has(chapter_id)

func _save_progress() -> void:
	var config = ConfigFile.new()
	config.set_value("progress", "game_cleared", _game_cleared)
	for chapter_id in _unlocked_chapters:
		var data = _unlocked_chapters[chapter_id]
		config.set_value("chapters", chapter_id, data)
	config.save(SAVE_PATH)

func _load_progress() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_game_cleared = config.get_value("progress", "game_cleared", false)
	if config.has_section("chapters"):
		for key in config.get_section_keys("chapters"):
			_unlocked_chapters[key] = config.get_value("chapters", key)

func reset() -> void:
	_unlocked_chapters.clear()
	_game_cleared = false
	_save_progress()
