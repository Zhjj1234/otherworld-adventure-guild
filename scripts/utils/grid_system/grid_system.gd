#* 通用网格系统工具类
#* 提供纯逻辑的网格管理功能，支持多尺寸物体放置检测
#* 与视图完全解耦，适用于2D/3D场景
#* 
#* 使用示例：
#* ```gdscript
#* # 创建一个10x10的网格
#* var grid = GridSystem.new(Vector2i(10, 10))
#* 
#* # 检测2x2物体能否放置在(0, 0)位置
#* var rect = GridRect.new(GridPos.new(0, 0), 2, 2)
#* var result = grid.can_place(rect)
#* 
#* if result.is_valid:
#*     print("可以放置")
#*     grid.place(rect, "物体数据")
#* else:
#*     print("无法放置，冲突位置:", result.blocking_positions)
#* ```
extends RefCounted
class_name GridSystem

#* 网格大小
var grid_size: Vector2i = Vector2i(10, 10)

#* 网格数据 (GridPos -> Variant)
var _grid_data: Dictionary = {}

#* 构造函数，初始化网格大小
#* @param p_grid_size 网格大小（列数x行数）
func _init(p_grid_size: Vector2i):
	var initial_size = p_grid_size
	if initial_size.x <= 0 or initial_size.y <= 0:
		push_warning("Grid size must be positive, using default 10x10")
		initial_size = Vector2i(10, 10)
	
	self.grid_size = initial_size
	clear()

#* 检查单个格子是否在网格范围内
#* @param pos 格子坐标
#* @return 是否在范围内
func _is_pos_in_bounds(pos: GridPos) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and \
		   pos.y >= 0 and pos.y < grid_size.y

#* 将GridPos转换为字典键
#* @param pos 格子坐标
#* @return 字典键
func _pos_to_key(pos: GridPos) -> String:
	return "%d_%d" % [pos.x, pos.y]

#* 将字典键转换为GridPos
#* @param key 字典键
#* @return 格子坐标
func _key_to_pos(key: String) -> GridPos:
	var parts = key.split("_")
	return GridPos.new(int(parts[0]), int(parts[1]))

#* 核心方法：执行碰撞检测并返回详细结果
#* @param rect 要检测的物体区域
#* @return 放置结果，包含是否可放、检测区域和冲突格子列表
func can_place(rect: GridRect) -> PlacementResult:
	var result = PlacementResult.new(false, rect, [])
	
	# 检查所有覆盖的格子
	for pos in rect.get_covered_positions():
		# 边界检测
		if not _is_pos_in_bounds(pos):
			result.is_valid = false
			return result
		
		# 碰撞检测
		if not is_cell_empty(pos):
			result.blocking_positions.append(pos)
	
	# 如果没有冲突，则放置有效
	result.is_valid = result.blocking_positions.size() == 0
	return result

#* 放置物体
#* @param rect 物体占用区域
#* @param data 要存储的物体数据
#* @return 是否放置成功
func place(rect: GridRect, data: Variant) -> bool:
	# 先检查是否可以放置
	var result = can_place(rect)
	if not result.is_valid:
		return false
	
	# 执行放置
	for pos in rect.get_covered_positions():
		var key = _pos_to_key(pos)
		_grid_data[key] = data
	
	return true

#* 移除指定区域的物体
#* @param rect 要移除的区域
func remove(rect: GridRect):
	for pos in rect.get_covered_positions():
		if _is_pos_in_bounds(pos):
			var key = _pos_to_key(pos)
			_grid_data.erase(key)

#* 检查单个格子是否为空
#* @param pos 格子坐标
#* @return 是否为空
func is_cell_empty(pos: GridPos) -> bool:
	if not _is_pos_in_bounds(pos):
		return false
	
	var key = _pos_to_key(pos)
	return not _grid_data.has(key)

#* 清空整个网格
func clear():
	_grid_data.clear()

#* 获取指定格子的数据
#* @param pos 格子坐标
#* @return 格子数据，如果格子为空或超出范围则返回null
func get_cell_data(pos: GridPos) -> Variant:
	if not _is_pos_in_bounds(pos):
		return null
	
	var key = _pos_to_key(pos)
	if _grid_data.has(key):
		return _grid_data[key]
	return null

#* 获取网格中所有被占用的格子
#* @return 被占用的格子坐标列表
func get_all_occupied_positions() -> Array[GridPos]:
	var positions: Array[GridPos] = []
	for key in _grid_data.keys():
		positions.append(_key_to_pos(key))
	return positions

#* 使用示例
#* ```gdscript
#* # 2D场景示例
#* var grid = GridSystem.new(Vector2i(10, 10))
#* 
#* # 屏幕坐标转网格坐标（示例）
#* func screen_to_grid(screen_pos: Vector2, cell_size: int, cell_spacing: int) -> GridPos:
#*     var grid_x = int(screen_pos.x / (cell_size + cell_spacing))
#*     var grid_y = int(screen_pos.y / (cell_size + cell_spacing))
#*     return GridPos.new(grid_x, grid_y)
#* 
#* # 放置物体
#* func place_object_at_screen_pos(screen_pos: Vector2, object_size: Vector2i, object_data: Variant):
#*     var cell_size = 50
#*     var cell_spacing = 2
#*     
#*     var grid_pos = screen_to_grid(screen_pos, cell_size, cell_spacing)
#*     var rect = GridRect.new(grid_pos, object_size.x, object_size.y)
#*     
#*     var result = grid.can_place(rect)
#*     if result.is_valid:
#*         grid.place(rect, object_data)
#*         # 在2D场景中创建可视元素
#*         var object = preload("res://object.tscn").instantiate()
#*         object.position = Vector2(
#*             grid_pos.x * (cell_size + cell_spacing),
#*             grid_pos.y * (cell_size + cell_spacing)
#*         )
#*         add_child(object)
#*     else:
#*         # 显示冲突位置（例如绘制红色格子）
#*         for block_pos in result.blocking_positions:
#*             draw_conflict_cell(block_pos, cell_size, cell_spacing)
#* 
#* # 3D场景示例
#* var grid_3d = GridSystem.new(Vector2i(10, 10))
#* 
#* # 世界坐标转网格坐标（示例）
#* func world_to_grid(world_pos: Vector3, cell_size: float) -> GridPos:
#*     var grid_x = int(world_pos.x / cell_size)
#*     var grid_y = int(world_pos.z / cell_size)  # 3D中通常用z轴表示深度
#*     return GridPos.new(grid_x, grid_y)
#* 
#* # 放置3D物体
#* func place_3d_object(world_pos: Vector3, object_size: Vector2i, object_data: Variant):
#*     var cell_size = 2.0
#*     
#*     var grid_pos = world_to_grid(world_pos, cell_size)
#*     var rect = GridRect.new(grid_pos, object_size.x, object_size.y)
#*     
#*     if grid_3d.place(rect, object_data):
#*         # 在3D场景中创建可视元素
#*         var object = preload("res://object_3d.tscn").instantiate()
#*         object.position = Vector3(
#*             grid_pos.x * cell_size,
#*             0,
#*             grid_pos.y * cell_size
#*         )
#*         get_tree().current_scene.add_child(object)
#* ```
