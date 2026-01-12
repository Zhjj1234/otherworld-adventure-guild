#* UI管理器，负责游戏场景UI的加载、卸载和管理
extends CanvasLayer

#* UI配置缓存，存储所有UI的配置信息
var _game_scene_ui_cache: UIConfig

#* 当前UI栈
var _ui_stack: Array[String] = []

#* 已加载UI实例字典，key为ui_id，value为对应的Node实例
var _game_scene_ui_instance_dict: Dictionary[String, BaseGameUI]

#* 节点就绪时调用，初始化UI配置
func _ready() -> void:
	#* 预加载UI配置资源
	_game_scene_ui_cache = preload("res://res/config/ui_config/tres/ui_config.tres")
	#* 监听场景切换事件
	# SceneManager.scene_changed.connect(_on_scene_changed)

#* ============================ UI加载、卸载、显示、隐藏、切换方法 ============================

#* 根据ui_id加载单个UI实例
#* @param ui_id UI的唯一标识符
func _load_ui_instance(ui_id: String):
	#* 检查UI是否已加载
	if _game_scene_ui_instance_dict.has(ui_id) and _game_scene_ui_instance_dict[ui_id] != null:
		return
	#* 获取UI路径
	var ui_path: String = _get_ui_path_by_ui_id(ui_id)
	#* 加载并实例化UI
	var ui_instance: Node = load(ui_path).instantiate()
	#* 实例化失败则返回。
	if ui_instance == null:
		print("UI: [" + ui_id + "] load failed")
		return
	print("UI: [" + ui_id + "] loaded")
	#* 缓存UI实例
	_game_scene_ui_instance_dict[ui_id] = ui_instance
	#* 添加为子节点
	add_child(ui_instance)
	#* 检查是否需要显示UI
	ui_instance.hide()
	if _get_ui_is_display_on_load(ui_id):
		#* 显示UI
		push_ui(ui_id)
	#* 输出UI加载完毕信息

#* 根据ui_id卸载单个UI实例
#* @param ui_id UI的唯一标识符
func _unload_ui_instance(ui_id: String):
	#* 获取UI实例
	var ui_instance: Node = _game_scene_ui_instance_dict[ui_id]
	#* 实例不存在则返回
	if ui_instance == null:
		return
	#* 移除子节点
	remove_child(ui_instance)
	#* 释放UI实例
	ui_instance.queue_free()
	#* 从缓存中移除
	_game_scene_ui_instance_dict.erase(ui_id)
	#* 输出UI卸载完毕信息
	print("UI: [" + ui_id + "] unloaded")

#* 卸载所有非全局UI实例
func _unload_all_uis():
	#* 遍历卸载所有UI
	for ui_id: String in _game_scene_ui_instance_dict.keys():
		if ui_id != "global_scene":
			_unload_ui_instance(ui_id)

#* 根据scene_id加载多个UI实例
#* @param scene_id 场景的唯一标识符
func _load_uis(scene_id: String):
	#* 获取场景相关的所有UI ID
	var ui_ids: Array[String] = _get_ui_ids_by_scene_id(scene_id)
	#* 遍历加载所有UI
	for ui_id in ui_ids:
		if _get_is_lazy_load(ui_id):
			continue
		_load_ui_instance(ui_id)

#* ========================= _game_scene_ui_cache 相关方法 ===============================

#* 根据scene_id获取对应的UI ID列表
#* @param scene_id 场景的唯一标识符
#* @return 场景相关的UI ID数组
func _get_ui_ids_by_scene_id(scene_id: String) -> Array[String]:
	#* 初始化UI ID数组
	var ui_ids: Array[String] = []
	#* 遍历配置数据，查找匹配的UI ID
	for game_scene_ui_data: GameSceneUIData in _game_scene_ui_cache.game_scene_ui_data_list:
		if game_scene_ui_data.scene_id == scene_id:
			ui_ids.append(game_scene_ui_data.ui_id)
	#* 返回UI ID数组
	return ui_ids

#* 根据ui_id获取对应的UI路径
#* @param ui_id UI的唯一标识符
#* @return UI的资源路径
func _get_ui_path_by_ui_id(ui_id: String) -> String:
	#* 遍历配置数据，查找匹配的UI路径
	var game_scene_ui_data: GameSceneUIData = _get_game_scene_ui_data_by_ui_id(ui_id)
	if game_scene_ui_data == null:
		return ""
	return game_scene_ui_data.ui_path

#* 根据ui_id获取_game_scene_ui_cache中对应的GameSceneUIData
#* @param ui_id UI的唯一标识符
#* @return 对应的GameSceneUIData对象
func _get_game_scene_ui_data_by_ui_id(ui_id: String) -> GameSceneUIData:
	#* 遍历配置数据，查找匹配的UI路径
	for game_scene_ui_data: GameSceneUIData in _game_scene_ui_cache.game_scene_ui_data_list:
		if game_scene_ui_data.ui_id == ui_id:
			return game_scene_ui_data
	#* 未找到则返回null
	return null

#* 根据ui_id获取对应的UI是否在加载时显示
#* @param ui_id UI的唯一标识符
#* @return 如果在加载时显示则返回true，否则返回false
func _get_ui_is_display_on_load(ui_id: String) -> bool:
	#* 遍历配置数据，查找匹配的UI路径
	for game_scene_ui_data: GameSceneUIData in _game_scene_ui_cache.game_scene_ui_data_list:
		if game_scene_ui_data.ui_id == ui_id:
			return game_scene_ui_data.is_display_on_load
	#* 未找到则返回false
	return false

#* 根据ui_id获取对应的UI是否懒加载
#* @param ui_id UI的唯一标识符
#* @return 如果是懒加载则返回true，否则返回false
func _get_is_lazy_load(ui_id: String) -> bool:
	#* 遍历配置数据，查找匹配的UI路径
	for game_scene_ui_data: GameSceneUIData in _game_scene_ui_cache.game_scene_ui_data_list:
		if game_scene_ui_data.ui_id == ui_id:
			return game_scene_ui_data.is_lazy_load
	#* 未找到则返回false
	return false

#* ==================================== 场景切换事件处理 ====================================

#* 当场景切换时调用，卸载当前场景的所有UI实例并加载新场景的所有UI实例
#* @param scene_id 新场景的唯一标识符
func load_uis(scene_id: String):
	#* 清空UI栈
	_ui_stack.clear()
	#* 卸载当前场景的所有UI实例
	_unload_all_uis()
	#* 加载新场景的所有UI实例
	_load_uis(scene_id)

#* ==================================== UI栈管理方法 ====================================
func push_ui(ui_id: String):
	if _ui_stack.find(ui_id) != -1:
		print("UI: [" + ui_id + "] already in stack")
		return
	#* 如果UI实例不存在，则加载UI实例
	if _game_scene_ui_instance_dict.has(ui_id) and _game_scene_ui_instance_dict[ui_id] == null:
		_load_ui_instance(ui_id)
	#* 将UI ID压入栈顶
	_ui_stack.append(ui_id)
	var current_ui_instance: BaseGameUI = _game_scene_ui_instance_dict[ui_id]
	#* 确保UI实例存在
	if current_ui_instance == null:
		print("UI: [" + ui_id + "] not found")
		return
	current_ui_instance.move_to_front()
	current_ui_instance.show_game_ui()
	#* 设置栈顶的UI ID的默认焦点
	current_ui_instance.set_set_default_focus()
	#* 输出UI压栈信息
	print("UI: [" + ui_id + "] pushed")

#* 弹出栈顶的UI ID
#* @return 弹出的UI ID
func pop_ui() -> String:
	if _ui_stack.size() == 0:
		print("UI: stack is empty")
		return ""
	#* 获取栈顶的UI ID
	var ui_id: String = _ui_stack.back()
	var game_scene_ui_data: GameSceneUIData = _get_game_scene_ui_data_by_ui_id(ui_id)
	if game_scene_ui_data.is_only_push:
		print("UI: [" + ui_id + "] is only push")
		return ""
	_ui_stack.pop_back()
	#* 如果UI实例不存在，则卸载UI实例
	if _game_scene_ui_instance_dict.has(ui_id) and _game_scene_ui_instance_dict[ui_id] == null:
		_unload_ui_instance(ui_id)
	var ui_instance: BaseGameUI = _game_scene_ui_instance_dict[ui_id]
	ui_instance.hide_game_ui()
	#* 设置栈顶的UI ID的默认焦点
	var current_ui_instance: BaseGameUI = get_current_ui_instance()
	#* 如果栈顶的UI实例存在，则设置默认焦点
	if current_ui_instance != null:
		current_ui_instance.set_set_default_focus()
	#* 输出UI弹栈信息
	print("UI: [" + ui_id + "] popped")
	return ui_id

#* 获取栈顶的UI实例
func get_current_ui_instance() -> BaseGameUI:
	if _ui_stack.size() == 0:
		return null
	return _game_scene_ui_instance_dict[_ui_stack.back()]

#* 获取栈顶的UI ID
func get_current_ui_id() -> String:
	return _ui_stack.back()
