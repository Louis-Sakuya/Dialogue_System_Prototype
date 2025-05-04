extends Node

# 音频播放器
var music_player: AudioStreamPlayer
var current_bgm_id: int = -1 # 当前播放的BGM ID，-1表示无

# 渐变效果控制
var fade_tween: Tween
var is_fading: bool = false
var fade_duration: float = 1.5 # 渐变持续时间（秒）
var default_volume_db: float = -10 # 默认音量（分贝）

# 音乐路径映射表
var bgm_paths = {
	0: "", 
	1: "res://assets/music/opening.mp3",
	2: "res://assets/music/relax1.mp3",
	3: "res://assets/music/relax2.mp3",
	4: "res://assets/music/fight1.mp3",
	5: "res://assets/music/fight2.mp3",
	6: "res://assets/music/fight3.mp3",
	7: "res://assets/music/fight4.mp3",
	8: "res://assets/music/lose1.mp3",
	9: "res://assets/music/lose2.mp3",
	10: "res://assets/music/victory1.mp3",
	11: "res://assets/music/bo5.mp3",
	12: "res://assets/music/end.mp3",
	13: "res://assets/music/end2.mp3",
	14: "res://assets/music/faker.mp3",

	# 可以根据需要添加更多音乐
}

func _ready() -> void:
	# 创建音频播放器
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music" # 假设你有一个名为"Music"的音频总线
	music_player.volume_db = default_volume_db # 设置默认音量
	add_child(music_player)
	
	# 设置循环播放
	music_player.finished.connect(func(): 
		if current_bgm_id > 0:
			play_music(current_bgm_id)
	)

# 播放指定ID的音乐（带渐变效果）
func play_music(bgm_id: int) -> void:
	# 如果ID为0或无效，停止当前音乐
	if bgm_id == 0 or not bgm_paths.has(bgm_id):
		fade_out_and_stop()
		return
	
	# 如果已经在播放相同的音乐，不做任何操作
	if bgm_id == current_bgm_id and music_player.playing:
		return
	
	# 加载音乐
	var music_path = bgm_paths[bgm_id]
	if music_path.is_empty():
		fade_out_and_stop()
		return
	
	# 检查音频文件是否存在
	if ResourceLoader.exists(music_path):
		var music_stream = load(music_path)
		if music_stream:
			# 如果当前有音乐在播放，先淡出当前音乐，然后淡入新音乐
			if music_player.playing:
				fade_out_then_play(music_stream, bgm_id)
			else:
				# 直接淡入新音乐
				music_player.stream = music_stream
				current_bgm_id = bgm_id
				fade_in()
	else:
		printerr("音乐文件不存在: ", music_path)

# 淡出当前音乐，然后淡入新音乐
func fade_out_then_play(new_stream: AudioStream, new_bgm_id: int) -> void:
	if is_fading:
		if fade_tween:
			fade_tween.kill() # 终止正在进行的渐变
	
	is_fading = true
	
	# 创建新的渐变效果
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration / 2.0) # 淡出到静音
	
	# 淡出完成后切换音乐并淡入
	fade_tween.tween_callback(func():
		music_player.stop()
		music_player.stream = new_stream
		current_bgm_id = new_bgm_id
		music_player.volume_db = -80.0 # 从静音开始
		music_player.play()
	)
	
	fade_tween.tween_property(music_player, "volume_db", default_volume_db, fade_duration / 2.0) # 淡入到默认音量
	
	# 渐变完成
	fade_tween.tween_callback(func():
		is_fading = false
	)

# 淡入当前设置的音乐
func fade_in() -> void:
	if is_fading:
		if fade_tween:
			fade_tween.kill()
	
	is_fading = true
	
	# 从静音开始播放
	music_player.volume_db = -80.0
	music_player.play()
	
	# 创建渐入效果
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", default_volume_db, fade_duration)
	
	# 渐变完成
	fade_tween.tween_callback(func():
		is_fading = false
	)

# 淡出当前音乐并停止
func fade_out_and_stop() -> void:
	if !music_player.playing:
		return
		
	if is_fading:
		if fade_tween:
			fade_tween.kill()
	
	is_fading = true
	
	# 创建渐出效果
	fade_tween = create_tween()
	fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
	
	# 渐出完成后停止
	fade_tween.tween_callback(func():
		music_player.stop()
		current_bgm_id = -1
		is_fading = false
	)

# 停止音乐（立即停止，无渐变）
func stop_music() -> void:
	if fade_tween:
		fade_tween.kill()
	
	music_player.stop()
	music_player.volume_db = default_volume_db
	current_bgm_id = -1
	is_fading = false

# 设置音乐音量 (0.0 到 1.0)
func set_music_volume(volume: float) -> void:
	# 将0-1的音量值转换为分贝值 (-80db 到 0db)
	default_volume_db = linear_to_db(volume)
	
	# 如果没有正在进行的渐变，直接应用新音量
	if !is_fading and music_player.playing:
		music_player.volume_db = default_volume_db

# 设置主音量（Master音量）(0.0 到 1.0)
func set_master_volume(volume: float) -> void:
	# 将0-1的音量值转换为分贝值 (-80db 到 0db)
	var db = linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	
# 获取当前主音量（0.0 到 1.0）
func get_master_volume() -> float:
	var bus_index = AudioServer.get_bus_index("Master")
	var volume_db = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(volume_db)
