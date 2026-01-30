#* 通用网格系统工具类
#* 提供纯逻辑的网格管理功能，支持多尺寸物体放置检测和多区域管理
#* 与视图完全解耦，适用于2D/3D场景
#* 
#* ## 架构设计说明
#* 
#* **核心设计原则：数据驱动，视图分离**
#* - GridSystem 是纯逻辑层，只管理数据和规则，不涉及任何视图渲染
#* - 一个 GridSystem 实例可以管理多个区域（GridRegion），这些区域共享同一个数据空间
#* - 区域可以重叠，重叠部分的标识用 "&" 连接（如 "a&b"）
#* - 物体放置时，所有覆盖的格子必须属于同一个区域标识（不能跨区域放置）
#* 
#* **典型使用场景：**
#* - 一个 DraggableGrid（UI控件）对应一个 GridSystem 实例
#* - DraggableGrid 可以包含多个 GridRegionView（视图层），每个视图显示一个区域
#* - 所有区域视图共享同一个 GridSystem，实现统一的数据管理
#* - Slot（可拖拽物品）可以在不同区域之间移动，因为它们共享同一个 GridSystem
#* 
#* **重要：**
#* - GridSystem 不关心视图如何显示，只关心数据逻辑
#* - 视图层（如 DraggableGrid、GridRegionView）负责渲染和交互
#* - 一个 GridSystem 实例 = 一个逻辑网格空间 = 可以包含多个区域
#* 
#* 使用示例：
#* ```gdscript
#* # 创建一个网格系统（一个实例管理所有区域）
#* var grid = GridSystem.new()
#* 
#* # 添加区域A：从(0,0)开始，5x5大小，标识为"a"
#* grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 5, "a"))
#* 
#* # 添加区域B：从(3,3)开始，5x5大小，标识为"b"（与区域A有交集）
#* grid.add_region(GridRegion.new(GridPos.new(3, 3), 5, 5, "b"))
#* 
#* # 检测2x2物体能否放置在(0, 0)位置
#* var rect = GridRect.new(GridPos.new(0, 0), 2, 2)
#* var result = grid.can_place(rect)
#* 
#* if result.is_valid:
#*     print("可以放置，区域标识:", result.region_id)
#*     grid.place(rect, "物体数据", result.region_id)
#* else:
#*     print("无法放置，冲突位置:", result.blocking_positions)
#* ```
extends RefCounted
class_name GridSystem

#* 区域列表
var regions: Array[GridRegion] = []

#* 网格数据 (GridPos -> Variant)
var _grid_data: Dictionary = {}

#* 格子区域标识缓存 (GridPos -> String)，用于快速查找
#* 标识格式：单个区域为 "a"，多个区域交集为 "a&b&c"
var _cell_region_ids: Dictionary = {}

#* 构造函数，初始化网格系统
func _init():
	clear()

#* 添加一个区域
#* @param region 要添加的区域
func add_region(region: GridRegion):
	regions.append(region)
	_update_region_cache()

#* 移除一个区域
#* @param region_id 要移除的区域标识
func remove_region(region_id: String):
	var index = -1
	for i in range(regions.size()):
		if regions[i].region_id == region_id:
			index = i
			break
	
	if index >= 0:
		regions.remove_at(index)
		_update_region_cache()

#* 清空所有区域
func clear_regions():
	regions.clear()
	_update_region_cache()

#* 更新区域标识缓存
func _update_region_cache():
	_cell_region_ids.clear()
	
	# 遍历所有区域，为每个格子计算标识
	for region in regions:
		for pos in region.get_covered_positions():
			var key = _pos_to_key(pos)
			if _cell_region_ids.has(key):
				# 如果格子已经在多个区域中，用 & 连接标识
				var existing_ids = _cell_region_ids[key]
				var new_ids = existing_ids + "&" + region.region_id
				# 排序以确保一致性（a&b 和 b&a 是一样的）
				var id_array = new_ids.split("&")
				id_array.sort()
				_cell_region_ids[key] = "&".join(id_array)
			else:
				_cell_region_ids[key] = region.region_id

#* 检查单个格子是否在任何区域内
#* @param pos 格子坐标
#* @return 是否在范围内
func _is_pos_in_bounds(pos: GridPos) -> bool:
	var key = _pos_to_key(pos)
	return _cell_region_ids.has(key)

#* 获取格子的区域标识
#* @param pos 格子坐标
#* @return 区域标识，如果不在任何区域内则返回空字符串
func _get_cell_region_id(pos: GridPos) -> String:
	var key = _pos_to_key(pos)
	if _cell_region_ids.has(key):
		return _cell_region_ids[key]
	return ""

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
#* @return 放置结果，包含是否可放、检测区域、冲突格子列表和区域标识
func can_place(rect: GridRect) -> PlacementResult:
	var result = PlacementResult.new(false, rect, [], "")
	
	# 检查所有覆盖的格子
	var first_region_id: String = ""
	var all_same_region: bool = true
	
	for pos in rect.get_covered_positions():
		# 边界检测：检查是否在任何区域内
		if not _is_pos_in_bounds(pos):
			result.is_valid = false
			return result
		
		# 获取当前格子的区域标识
		var cell_region_id = _get_cell_region_id(pos)
		
		# 检查所有格子的标识是否一致
		if first_region_id == "":
			first_region_id = cell_region_id
		elif first_region_id != cell_region_id:
			# 标识不一致，不能放置
			all_same_region = false
			result.blocking_positions.append(pos)
		
		# 碰撞检测：检查格子是否已被占用
		if not is_cell_empty(pos):
			result.blocking_positions.append(pos)
	
	# 如果所有格子标识一致且没有碰撞，则放置有效
	result.is_valid = all_same_region and result.blocking_positions.size() == 0
	
	# 设置区域标识（如果有效）
	if result.is_valid and first_region_id != "":
		result.region_id = first_region_id
	
	return result

#* 在指定位置或范围内查找可放置位置
#* 若指定位置可放则直接返回；否则在 search_range 格范围内找离指定位置最近的空位
#* @param center_pos 指定位置（如鼠标指向的格子）
#* @param width 物体宽度（占几格）
#* @param height 物体高度（占几格）
#* @param search_range 搜索范围（格数，0 表示只检查 center_pos；1 表示中心周围 1 格范围内）
#* @return 放置结果：is_valid 为 true 时 rect 为可放置区域（可能是中心或范围内最近空位）
func can_place_or_find_nearby(center_pos: GridPos, width: int, height: int, search_range: int = 0) -> PlacementResult:
	var rect_at_center = GridRect.new(center_pos, width, height)
	var result_at_center = can_place(rect_at_center)
	
	if result_at_center.is_valid:
		return result_at_center
	
	if search_range <= 0:
		return result_at_center
	
	# 在 search_range 范围内枚举所有可能的左上角位置
	var best_result: PlacementResult = null
	var best_dist_sq: int = 0x7fffffff  # 用距离平方比较，避免开方
	
	for dy in range(-search_range, search_range + 1):
		for dx in range(-search_range, search_range + 1):
			var try_pos = GridPos.new(center_pos.x + dx, center_pos.y + dy)
			var try_rect = GridRect.new(try_pos, width, height)
			var try_result = can_place(try_rect)
			
			if not try_result.is_valid:
				continue
			
			# 用矩形中心到目标中心的距离平方比较（最近）
			var try_center_x = try_pos.x + (width - 1) / 2.0
			var try_center_y = try_pos.y + (height - 1) / 2.0
			var target_center_x = center_pos.x + (width - 1) / 2.0
			var target_center_y = center_pos.y + (height - 1) / 2.0
			var dist_sq = int(pow(try_center_x - target_center_x, 2) + pow(try_center_y - target_center_y, 2))
			
			if best_result == null or dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best_result = PlacementResult.new(true, try_rect, [], try_result.region_id)
	
	if best_result != null:
		return best_result
	
	# 范围内没有空位，返回原先中心位置的结果
	return result_at_center

#* 放置物体
#* @param rect 物体占用区域
#* @param data 要存储的物体数据
#* @param region_id 区域标识（可选，如果不提供则自动检测）
#* @return 是否放置成功
func place(rect: GridRect, data: Variant, region_id: String = "") -> bool:
	# 先检查是否可以放置
	var result = can_place(rect)
	if not result.is_valid:
		return false
	
	# 如果提供了 region_id，验证是否匹配
	if region_id != "" and result.region_id != region_id:
		push_warning("提供的区域标识 '%s' 与检测到的标识 '%s' 不匹配" % [region_id, result.region_id])
		return false
	
	# 执行放置
	for pos in rect.get_covered_positions():
		var key = _pos_to_key(pos)
		_grid_data[key] = data
	
	return true

#* 移除指定区域的物体
#* @param rect 要移除的区域
#* @param region_id 区域标识（可选，用于验证）
func remove(rect: GridRect, region_id: String = ""):
	for pos in rect.get_covered_positions():
		if _is_pos_in_bounds(pos):
			# 如果提供了 region_id，验证是否匹配
			if region_id != "":
				var cell_region_id = _get_cell_region_id(pos)
				if cell_region_id != region_id:
					push_warning("移除位置 %s 的区域标识 '%s' 与提供的标识 '%s' 不匹配" % [pos._to_string(), cell_region_id, region_id])
					continue
			
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

#* 清空整个网格（只清空数据，不清空区域）
func clear():
	_grid_data.clear()

#* 获取指定格子的区域标识
#* @param pos 格子坐标
#* @return 区域标识，如果不在任何区域内则返回空字符串
func get_cell_region_id(pos: GridPos) -> String:
	return _get_cell_region_id(pos)

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
#* # 2D场景示例 - 多区域网格系统
#* var grid = GridSystem.new()
#* 
#* # 添加区域A：从(0,0)开始，5x5大小，标识为"inventory_a"
#* grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 5, "inventory_a"))
#* 
#* # 添加区域B：从(3,3)开始，5x5大小，标识为"inventory_b"（与区域A有交集）
#* grid.add_region(GridRegion.new(GridPos.new(3, 3), 5, 5, "inventory_b"))
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
#*         # 使用检测到的区域标识进行放置
#*         grid.place(rect, object_data, result.region_id)
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
#* # 3D场景示例 - 多区域网格系统
#* var grid_3d = GridSystem.new()
#* 
#* # 添加区域
#* grid_3d.add_region(GridRegion.new(GridPos.new(0, 0), 10, 10, "storage"))
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
#*     var result = grid_3d.can_place(rect)
#*     if result.is_valid:
#*         grid_3d.place(rect, object_data, result.region_id)
#*         # 在3D场景中创建可视元素
#*         var object = preload("res://object_3d.tscn").instantiate()
#*         object.position = Vector3(
#*             grid_pos.x * cell_size,
#*             0,
#*             grid_pos.y * cell_size
#*         )
#*         get_tree().current_scene.add_child(object)
#* ```
