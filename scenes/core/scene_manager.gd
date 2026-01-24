extends Node

# 定义一个信号，当场景切换成功后发出
signal scene_changed(new_scene_id: String)

#*
var _game_scene_cache: SceneConfig

# 唯一的核心状态变量
var _current_scene_data: GameSceneData

func _ready() -> void:
	# 建议使用 preload 在脚本加载时就完成加载，效率更高
	_game_scene_cache = preload("res://res/config/scene_config/tres/scene_config.tres")

#* 切换到游戏主场景 (公共API)
func to_game_main_scene() -> void:
	change_scene("game_main")

#* 通用的场景切换函数 (公共API)
func change_scene(scene_id: String) -> void:
	print("\nScene: [" + get_current_scene_id() + "] switching to [" + scene_id + "]")
	# 1. 查找数据
	var target_scene_data: GameSceneData = get_game_scene_data_by_id(scene_id)
	
	# 2. 健壮性检查：如果数据不存在，则直接返回
	if not target_scene_data:
		return

	
	# 4. 更新内部状态 (唯一真相)
	_current_scene_data = target_scene_data
	get_tree().call_deferred("change_scene_to_file", _current_scene_data.game_scene_path)
	
	await get_tree().scene_changed
	# 5. 执行场景切换操作
	var current_scene = get_tree().current_scene
	# await current_scene.ready
	# 6. 发出信号，通知所有关心这个事件的模块
	print("Scene: [" + get_current_scene_id() + " " + current_scene.to_string() + "] loaded\n")
	scene_changed.emit(get_current_scene_id())
	

#* 获取当前场景的完整数据 (内部/紧密耦合使用)
func _get_current_scene_data() -> GameSceneData:
	return _current_scene_data

#* 获取当前场景的ID (对外接口)
func get_current_scene_id() -> String:
	if _current_scene_data:
		return _current_scene_data.game_scene_id
	return ""

#* 根据ID获取游戏场景数据
func get_game_scene_data_by_id(scene_id: String) -> GameSceneData:
	for game_scene_data: GameSceneData in _game_scene_cache.game_scene_data_list:
		if scene_id == game_scene_data.game_scene_id:
			return game_scene_data
	# 打印错误日志，方便调试
	push_error("[SceneManager] Scene data with ID: '" + scene_id + "' not found in cache.")
	return null
