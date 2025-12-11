extends Node

#* 用来保存所有加载任务的状态和结果（原来的全局容器）
#* 结构示例：
#* {
#*   total_count = 5,      #* 需要加载的总资源数
#*   count       = 3,      #* 已经加载完成的资源数
#*   res = {               #* 每个路径对应的状态
#*       "res://xxx.tscn" = { progress = [0.0], data = PackedScene, var_name = "key"}
#*   }
#* }
var _game_datas: Dictionary = {}

#* 只读属性：实时获取当前整体加载进度（0.0 ~ 1.0）
#* 每次访问 get 都会重新计算一次
var current_progress: float:
	get:
		var percent = 0
		if _game_datas.get("total_count", 0) == 0: # * 防止除零
			return 0.0
			
		var total_progress: float = 0.0
		#* 遍历所有正在加载的资源，累加它们的进度
		for path in _game_datas["res"].keys():
			var info = _game_datas["res"][path]
			if info and info.has("progress") and info["progress"].size() > 0:
				total_progress += info["progress"][0] # * ResourceLoader 实时写入的进度值
		
		#* 计算平均进度（即整体进度）
		percent = total_progress / _game_datas["total_count"]
		return percent

#* ------------------------------------------------------------------
#* 主加载函数：并行加载所有资源，并实时报告进度
#* key_path      : { "变量名": "资源路径" } 例如 { "MainScene": "res://main.tscn" }
#* progress_func : 可选的 Callable，每帧调用一次，参数为 _game_datas（外面自己读 current_progress 也行）
#* ------------------------------------------------------------------
func _load_all(key_path: Dictionary, progress_func = null) -> void:
	#* 初始化全局容器，清空上次残留数据
	_game_datas.clear()
	_game_datas["total_count"] = key_path.keys().size() # * 总资源数量
	_game_datas["res"] = {} # * 存放每个资源的进度和结果
	_game_datas["count"] = 0 # * 已完成计数清零
	
	#* 关键：并行启动所有资源的后台加载（这里不 await，只是提交任务）
	for var_name in key_path.keys():
		load_res_async(var_name, key_path[var_name])
	
	#* 主线程每帧轮询，直到所有资源加载完毕
	while _game_datas["count"] < _game_datas["total_count"]:
		#* 如果外部传了进度回调，就把整个 _game_datas 扔过去（外面可以读 current_progress）
		if progress_func is Callable:
			progress_func.call(_game_datas)
		
		#* 必须让出本帧，否则后台线程得不到执行时间，会卡住
		await get_tree().process_frame
	
	#* 全部加载完毕后，再强制回调一次（保证进度条一定到 100%）
	if progress_func is Callable:
		progress_func.call(_game_datas)
	
	#* 清理容器，释放内存
	_game_datas.clear()

#* ------------------------------------------------------------------
#* 单个资源的异步加载协程（真正后台线程干活的地方）
#* var_name : 加载完成后要存到 GameDataManager.game_data 的 key
#* path     : 资源路径
#* ------------------------------------------------------------------
func load_res_async(var_name: String, path: String) -> void:
	#* 为这个资源在全局容器里预留位置
	_game_datas["res"][path] = {
		"progress": [0.0], # * ResourceLoader 会实时把进度写入这个数组
		"data": null, # * 加载完成后存放实际资源对象
		"var_name": "", # * 暂时留空，后面填
	}
	
	#* 正式提交后台线程加载请求
	var err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		push_error("提交加载请求失败：%s (错误码: %d)" % [path, err])
		_game_datas["count"] += 1 # * 失败也要计数，防止死循环
		return
	
	#* 轮询加载状态
	var status: int
	var progress_array = _game_datas["res"][path]["progress"]
	_game_datas["res"][path]["var_name"] = var_name # * 记录变量名，后面直接赋值
	
	while true:
		#* 查询当前状态，同时把最新进度写入 progress_array
		status = ResourceLoader.load_threaded_get_status(path, progress_array)
		
		#* 加载完成
		if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
			break
			
		#* 加载失败
		if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED \
		or status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
			push_error("加载失败：%s" % path)
			break
		
		#* 必须每帧让出，否则后台线程拿不到时间片，会卡死
		await get_tree().process_frame
	
	#* 加载成功后取出资源实例
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		var resource = ResourceLoader.load_threaded_get(path)
		_game_datas["res"][path]["data"] = resource
		#* 直接挂到全局 GameDataManager，外部可以直接用
		GameDataManager._game_data[var_name] = resource
	
	#* 无论成功还是失败，都要 +1 计数，结束这个任务
	_game_datas["count"] += 1
