extends Node

# ========== 全局变量 ==========
# 地图容器（Stage节点引用）
var _map_manager: Node = null
# 当前加载的地图实例
var current_map: Node = null
# 预加载地图缓存
var preloaded_maps: Dictionary = {}

# ========== 核心接口 ==========
## 1. 注册Stage节点（必须先调用）
func on_map_manager_registered(map_manager: Node) -> void:
	_map_manager = map_manager
	print("✅ MapLoaderManager: Stage节点注册成功")

## 2. 切换地图（主方法）
func switch_map(map_scene_path: String) -> void:
	print("🔄 MapLoaderManager: 地图开始切换 → ", map_scene_path)
	# 校验Stage是否注册
	if not _map_manager:
		push_error("❌ MapLoaderManager: 请先调用 register_stage 注册Stage节点！")
		return
	
	# 卸载旧地图
	if current_map:
		current_map.queue_free()
		current_map = null
		print("🗑️ MapLoaderManager: 旧地图已卸载")
	
	# 加载新地图（优先用预加载缓存）
	var map_packed: PackedScene
	if preloaded_maps.has(map_scene_path):
		map_packed = preloaded_maps[map_scene_path]
	else:
		map_packed = load(map_scene_path) as PackedScene
	
	if not map_packed:
		push_error("❌ MapLoaderManager: 地图加载失败 → ", map_scene_path)
		return
	
	# 实例化并挂载到Stage
	current_map = map_packed.instantiate()
	# 监听地图就绪信号
	current_map.ready.connect(_on_map_ready)
	_map_manager.add_child(current_map)
	# print("🔄 MapLoaderManager: 地图切换中 → ", map_scene_path)

## 3. 预加载地图（提前缓存，避免卡顿）
func preload_map(map_scene_path: String) -> void:
	if preloaded_maps.has(map_scene_path):
		print("ℹ️ MapLoaderManager: 地图已预加载 → ", map_scene_path)
		return
	
	var map_packed = load(map_scene_path) as PackedScene
	if map_packed:
		preloaded_maps[map_scene_path] = map_packed
		print("📥 MapLoaderManager: 地图预加载完成 → ", map_scene_path)
	else:
		push_error("❌ MapLoaderManager: 预加载失败 → ", map_scene_path)

## 4. 清理预加载缓存
func clear_preloaded_maps() -> void:
	preloaded_maps.clear()
	print("🧹 MapLoaderManager: 预加载缓存已清空")

## 5. 获取当前地图实例（对外只读）
func get_current_map() -> Node:
	return current_map

# ========== 内部回调 ==========
func _on_map_ready() -> void:
	if not current_map:
		return
	# EventBus.map_ready.emit(current_map)
	print("✅ MapLoaderManager: 地图切换完成 → ", current_map.name)
