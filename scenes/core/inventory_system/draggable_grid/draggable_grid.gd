#* 可拖拽表格控件
#* 提供一个网格表格，可以在其中拖拽槽位，支持多区域管理
#* 
#* ## 架构设计说明
#* 
#* **核心架构：一个 DraggableGrid = 一个 GridSystem + 多个 GridRegionView + 一个 SlotContainer**
#* 
#* - **GridSystem（逻辑层）**：一个实例，管理所有区域的数据和放置规则
#*   - 所有区域共享同一个 GridSystem 实例
#*   - 负责区域标识管理、碰撞检测、放置验证等逻辑
#* 
#* - **GridRegionView（视图层）**：多个实例，每个区域对应一个视图
#*   - 负责显示单个区域的背景、格子、网格线
#*   - 设置 mouse_filter = MOUSE_FILTER_IGNORE，不拦截鼠标事件
#*   - z_index = 0，在底层显示
#* 
#* - **SlotContainer（容器层）**：一个实例，包含所有可拖拽的 slot
#*   - 在区域视图之后创建，确保在它们上方
#*   - z_index = 10，确保 slot 显示在区域视图之上
#*   - mouse_filter = MOUSE_FILTER_PASS，允许鼠标事件传递
#* 
#* **节点层级结构：**
#* ```
#* DraggableGrid
#* ├── GridRegionView (region_left)    # 区域视图1，z_index=0
#* ├── GridRegionView (region_right)   # 区域视图2，z_index=0
#* └── SlotContainer                   # Slot容器，z_index=10
#*     └── DraggableSlot (所有slot)
#* ```
#* 
#* **重要设计原则：**
#* - 一个 DraggableGrid 只对应一个 GridSystem 实例
#* - 多个区域视图共享同一个 GridSystem，实现统一的数据管理
#* - Slot 可以在不同区域之间拖拽移动，因为它们共享同一个 GridSystem
#* - 区域视图只负责显示，不处理交互（mouse_filter=IGNORE）
#* - Slot 容器负责所有交互逻辑（mouse_filter=PASS）
#* 
#* **使用示例：**
#* ```gdscript
#* var grid = DraggableGrid.new()
#* 
#* # 添加两个区域（共享同一个 GridSystem）
#* grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 6, "region_left"))
#* grid.add_region(GridRegion.new(GridPos.new(6, 0), 5, 6, "region_right"))
#* 
#* # 添加 slot（可以在两个区域之间移动）
#* grid.add_slot(Vector2i(2, 2), Vector2i(0, 0))
#* ```
extends Control
class_name DraggableGrid

# 预加载 GridRegionView 类
const GridRegionViewClass = preload("res://scenes/core/inventory_system/draggable_grid/grid_region_view.gd")

signal slot_added(slot: DraggableSlot, position: Vector2i, region_id: String)
signal slot_moved(slot: DraggableSlot, old_position: Vector2i, new_position: Vector2i, old_region_id: String, new_region_id: String)
signal slot_removed(slot: DraggableSlot)

# 全局注册的实例列表，用于查找拖拽目标
static var INSTANCES: Array = []

#* 区域列表（用于初始化，运行时通过 add_region 添加）
@export var initial_regions: Array[Dictionary] = []

#* 格子大小（像素）
@export var cell_size: int = 50

#* 格子间距
@export var cell_spacing: int = 2

#* 网格线颜色
@export var grid_line_color: Color = Color(0.3, 0.3, 0.3, 0.5)

#* 背景颜色
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)

#* 是否为每个格子绘制背景（如果为 false 则只绘制网格线）
@export var show_cell_background: bool = true

#* 每格的背景颜色（在没有贴图时使用）
@export var cell_background_color: Color = Color(0.08, 0.08, 0.08, 1.0)

#* 可选的格子背景贴图（会平铺到每个格子）
@export var cell_background_texture: Texture2D

#* 放置搜索范围（格数）：拖拽松手时若指定格不可放，则在此范围内找离指定位置最近的空位；0 表示只允许精确放置
@export var place_search_range: int = 1

#* 网格系统
var grid_system: GridSystem = null

#* 区域视图字典（region_id -> Control）
var region_views: Dictionary = {}

#* Slot容器（所有slot的容器，与区域视图同级）
var slot_container: Control = null

#* 当前拖拽的槽位
var dragging_slot: DraggableSlot = null

#* 拖拽开始时的信息（用于失败恢复）
var _drag_start_rotation: int = 0
var _drag_start_effective_size: Vector2i = Vector2i(1, 1)
var _drag_start_region_id: String = ""

func _ready() -> void:
	# 设置鼠标过滤，允许接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 初始化网格系统
	grid_system = GridSystem.new()
	
	# 从初始区域列表创建区域（先创建区域视图）
	if initial_regions.size() > 0:
		for region_data in initial_regions:
			var pos = GridPos.new(region_data.get("x", 0), region_data.get("y", 0))
			var width = region_data.get("width", 1)
			var height = region_data.get("height", 1)
			var region_id = region_data.get("region_id", "")
			add_region(GridRegion.new(pos, width, height, region_id))
	else:
		# 如果没有初始区域，创建一个默认区域（向后兼容）
		push_warning("DraggableGrid: 没有指定初始区域，请使用 add_region() 方法添加区域")
	
	# 创建Slot容器（在区域视图之后，确保在它们上方）
	slot_container = Control.new()
	slot_container.name = "SlotContainer"
	slot_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_container.mouse_filter = Control.MOUSE_FILTER_PASS  # 允许鼠标事件传递
	slot_container.z_index = 10  # 确保在区域视图上方
	add_child(slot_container)
	
	# 注册实例
	INSTANCES.append(self)

func _exit_tree() -> void:
	if self in INSTANCES:
		INSTANCES.erase(self)

#* 添加一个区域
#* @param region 区域数据
func add_region(region: GridRegion) -> void:
	if grid_system == null:
		grid_system = GridSystem.new()
	
	grid_system.add_region(region)
	
	# 创建区域视图
	var region_view = GridRegionViewClass.new(region, cell_size, cell_spacing)
	region_view.name = "RegionView_%s" % region.region_id
	region_view.grid_line_color = grid_line_color
	region_view.background_color = background_color
	region_view.show_cell_background = show_cell_background
	region_view.cell_background_color = cell_background_color
	region_view.cell_background_texture = cell_background_texture
	region_view.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 区域视图不拦截鼠标事件，让slot可以接收
	region_view.z_index = 0  # 区域视图在底层
	add_child(region_view)
	
	region_views[region.region_id] = region_view
	
	# 更新整体大小
	_update_total_size()

#* 移除一个区域
#* @param region_id 区域标识
func remove_region(region_id: String) -> void:
	if grid_system:
		grid_system.remove_region(region_id)
	
	if region_views.has(region_id):
		var view = region_views[region_id]
		region_views.erase(region_id)
		if is_instance_valid(view):
			view.queue_free()
	
	_update_total_size()

#* 更新整体大小（基于所有区域）
func _update_total_size() -> void:
	if grid_system == null or grid_system.regions.size() == 0:
		return
	
	var min_x = 0
	var min_y = 0
	var max_x = 0
	var max_y = 0
	
	for region in grid_system.regions:
		var region_max_x = region.pos.x + region.width
		var region_max_y = region.pos.y + region.height
		if region.pos.x < min_x:
			min_x = region.pos.x
		if region.pos.y < min_y:
			min_y = region.pos.y
		if region_max_x > max_x:
			max_x = region_max_x
		if region_max_y > max_y:
			max_y = region_max_y
	
	var total_width = max_x * (cell_size + cell_spacing) + cell_spacing
	var total_height = max_y * (cell_size + cell_spacing) + cell_spacing
	
	custom_minimum_size = Vector2(total_width, total_height)
	clip_contents = true

func _input(event: InputEvent) -> void:
	# 拖拽过程中按右键：顺时针旋转 90°
	if dragging_slot and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			dragging_slot.rotate_clockwise_90()
			_apply_slot_visual_size(dragging_slot)
			get_viewport().set_input_as_handled()

#* 根据槽位当前有效尺寸更新其显示大小（像素）
#* eff.x = 占格宽度，eff.y = 占格高度，旋转后 1×3 → 3×1 会正确显示为横条
func _apply_slot_visual_size(slot: DraggableSlot) -> void:
	var eff = slot.get_effective_size()
	var width_px = eff.x * cell_size + (eff.x - 1) * cell_spacing
	var height_px = eff.y * cell_size + (eff.y - 1) * cell_spacing
	slot.set_custom_minimum_size(Vector2(width_px, height_px))
	slot.size = Vector2(width_px, height_px)

#* 将屏幕坐标转换为格子坐标
func screen_to_grid(screen_pos: Vector2) -> GridPos:
	var local_pos = screen_pos - global_position
	var grid_x = int((local_pos.x - cell_spacing) / (cell_size + cell_spacing))
	var grid_y = int((local_pos.y - cell_spacing) / (cell_size + cell_spacing))
	return GridPos.new(grid_x, grid_y)

#* 将格子坐标转换为屏幕位置（左上角，相对于DraggableGrid）
func grid_to_screen(grid_pos: GridPos) -> Vector2:
	return Vector2(
		grid_pos.x * (cell_size + cell_spacing) + cell_spacing,
		grid_pos.y * (cell_size + cell_spacing) + cell_spacing
	)

#* 获取格子所在的区域视图
#* @param grid_pos 格子坐标
#* @return 区域视图，如果不在任何区域内则返回null
func get_region_view_at(grid_pos: GridPos) -> Control:
	if grid_system == null:
		return null
	
	var region_id = grid_system.get_cell_region_id(grid_pos)
	if region_id == "":
		return null
	
	# 如果是交集区域，取第一个区域
	if "&" in region_id:
		region_id = region_id.split("&")[0]
	
	if region_views.has(region_id):
		return region_views[region_id]
	return null

#* 将Vector2i转换为GridPos
func _vec2i_to_grid_pos(vec: Vector2i) -> GridPos:
	return GridPos.new(vec.x, vec.y)

#* 将GridPos转换为Vector2i
func _grid_pos_to_vec2i(grid_pos: GridPos) -> Vector2i:
	return grid_pos.to_vector2i()

#* 检查位置是否在表格范围内
#* @param slot_position 要检查的位置（格子坐标）
#* @param slot_size 槽位大小（宽x高，占几格）
#* @return 位置是否有效（在表格范围内且未被占用）
func is_position_valid(slot_position: Vector2i, slot_size: Vector2i = Vector2i(1, 1)) -> bool:
	var grid_pos = _vec2i_to_grid_pos(slot_position)
	var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
	var result = grid_system.can_place(rect)
	return result.is_valid

#* 检查位置是否被占用
#* @param slot_position 要检查的位置（格子坐标）
#* @param slot_size 槽位大小（宽x高，占几格）
#* @param exclude_slot 排除的槽位（可选，用于移动槽位时检查）
#* @return 位置是否被占用
func is_position_occupied(slot_position: Vector2i, slot_size: Vector2i = Vector2i(1, 1), _exclude_slot: DraggableSlot = null) -> bool:
	var grid_pos = _vec2i_to_grid_pos(slot_position)
	var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
	var result = grid_system.can_place(rect)
	return not result.is_valid

#* 添加槽位
#* @param slot_size 槽位大小（宽x高，占几格）
#* @param slot_position 槽位位置（格子坐标，默认为-1,-1表示自动查找可用位置）
#* @param slot_color 槽位颜色
#* @return 创建的槽位对象，如果创建失败则返回null
func add_slot(slot_size: Vector2i = Vector2i(1, 1), slot_position: Vector2i = Vector2i(-1, -1), slot_color: Color = Color(0.3, 0.5, 0.8, 0.8)) -> DraggableSlot:
	# 如果没有指定位置，自动查找可用位置
	if slot_position == Vector2i(-1, -1):
		slot_position = find_available_position(slot_size)
		if slot_position == Vector2i(-1, -1):
			push_warning("无法找到可用位置")
			return null
	
	# 转换为GridPos
	var grid_pos = _vec2i_to_grid_pos(slot_position)
	var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
	
	# 使用GridSystem检查并放置槽位
	var place_result = grid_system.can_place(rect)
	if place_result.is_valid and grid_system.place(rect, null, place_result.region_id):
		# 创建槽位
		var new_slot = DraggableSlot.new()
		new_slot.slot_size = slot_size
		new_slot.grid_position = slot_position
		new_slot.set_slot_color(slot_color)
		new_slot.set_slot_size(slot_size)
		
		# 设置位置和显示大小（按当前有效尺寸）
		var screen_pos = grid_to_screen(grid_pos)
		new_slot.position = screen_pos
		_apply_slot_visual_size(new_slot)
		
		# 连接信号
		new_slot.slot_dragged.connect(Callable(self, "_on_slot_dragged"))
		new_slot.slot_clicked.connect(Callable(self, "_on_slot_clicked"))
		
		# 添加到容器
		slot_container.add_child(new_slot)
		
		slot_added.emit(new_slot, slot_position, place_result.region_id)
		return new_slot
	else:
		push_warning("位置已被占用或超出范围")
		return null

#* 移除槽位
#* @param slot 要移除的槽位对象
func remove_slot(slot: DraggableSlot) -> void:
	var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var eff = slot.get_effective_size()
	var rect = GridRect.new(grid_pos, eff.x, eff.y)
	grid_system.remove(rect)
	slot.queue_free()
	slot_removed.emit(slot)

#* 移动槽位到新位置（使用当前旋转后的占位；若指定位置不可放则在 place_search_range 内找最近空位）
#* @param slot 要移动的槽位对象
#* @param new_slot_position 目标位置（格子坐标）
#* @param old_effective_size 拖拽前的占位大小，用于移除/恢复；若为 (-1,-1) 则用 slot.get_effective_size()
#* @return 是否移动成功
func move_slot(slot: DraggableSlot, new_slot_position: Vector2i, old_effective_size: Vector2i = Vector2i(-1, -1)) -> bool:
	var eff_old = old_effective_size if old_effective_size.x >= 0 else slot.get_effective_size()
	var eff_cur = slot.get_effective_size()

	# 先按拖拽前占位移除旧位置
	var old_grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var old_rect = GridRect.new(old_grid_pos, eff_old.x, eff_old.y)
	grid_system.remove(old_rect)

	# 按当前旋转后的占位在目标位置或范围内找可放置位置
	var center_pos = _vec2i_to_grid_pos(new_slot_position)
	var result = grid_system.can_place_or_find_nearby(center_pos, eff_cur.x, eff_cur.y, place_search_range)

	if result.is_valid:
		var new_rect = result.rect
		grid_system.place(new_rect, null, result.region_id)
		var old_slot_position = slot.grid_position
		var final_position = Vector2i(new_rect.pos.x, new_rect.pos.y)
		slot.grid_position = final_position
		slot.position = grid_to_screen(new_rect.pos)
		
		# 获取旧区域标识
		var old_region_id = grid_system.get_cell_region_id(old_grid_pos)
		slot_moved.emit(slot, old_slot_position, final_position, old_region_id, result.region_id)
		return true
	else:
		# 恢复旧位置（用拖拽前的占位）
		var restore_result = grid_system.can_place(old_rect)
		if restore_result.is_valid:
			grid_system.place(old_rect, null, restore_result.region_id)
		return false

#* 查找可用位置
#* @param slot_size 要查找的槽位大小（宽x高，占几格）
#* @param region_id 可选，指定在哪个区域查找
#* @return 找到的可用位置（格子坐标），如果没有可用位置则返回Vector2i(-1, -1)
func find_available_position(slot_size: Vector2i, region_id: String = "") -> Vector2i:
	if grid_system == null:
		return Vector2i(-1, -1)
	
	# 如果指定了区域，只在该区域查找
	if region_id != "":
		var region = null
		for r in grid_system.regions:
			if r.region_id == region_id:
				region = r
				break
		if region == null:
			return Vector2i(-1, -1)
		
		for grid_y in range(region.pos.y, region.pos.y + region.height - slot_size.y + 1):
			for grid_x in range(region.pos.x, region.pos.x + region.width - slot_size.x + 1):
				var slot_position = Vector2i(grid_x, grid_y)
				var grid_pos = _vec2i_to_grid_pos(slot_position)
				var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
				var result = grid_system.can_place(rect)
				if result.is_valid and result.region_id == region_id:
					return slot_position
	else:
		# 在所有区域中查找
		for region in grid_system.regions:
			for grid_y in range(region.pos.y, region.pos.y + region.height - slot_size.y + 1):
				for grid_x in range(region.pos.x, region.pos.x + region.width - slot_size.x + 1):
					var slot_position = Vector2i(grid_x, grid_y)
					var grid_pos = _vec2i_to_grid_pos(slot_position)
					var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
					var result = grid_system.can_place(rect)
					if result.is_valid:
						return slot_position
	
	return Vector2i(-1, -1)

#* 对齐到网格
#* @param screen_pos 屏幕坐标
#* @return 对齐后的格子坐标
func snap_to_grid(screen_pos: Vector2) -> Vector2i:
	var grid_pos = screen_to_grid(screen_pos)
	return Vector2i(grid_pos.x, grid_pos.y)

#* 处理槽位拖拽结束事件
#* @param slot 拖拽的槽位对象
#* @param old_slot_position 拖拽前的位置（格子坐标）
#* @param click_offset 点击位置相对于槽位左上角的格子偏移
func _on_slot_dragged(slot: DraggableSlot, old_slot_position: Vector2i, click_offset: Vector2i) -> void:
	# 处理拖拽结束：支持同一网格内移动或跨网格移动
	var mouse_pos = get_global_mouse_position()
	# 计算目标网格相对坐标（基于当前 grid）
	var mouse_grid_pos = screen_to_grid(mouse_pos)
	var target_position = Vector2i(
		mouse_grid_pos.x - click_offset.x,
		mouse_grid_pos.y - click_offset.y
	)

	# 先查找鼠标下的目标网格（可能是自己或其他网格）
	var target_grid: DraggableGrid = null
	for g in INSTANCES:
		if not g:
			continue
		var rect = Rect2(g.get_global_position(), g.size)
		if rect.has_point(mouse_pos):
			target_grid = g
			break

	if target_grid == null or target_grid == self:
		# 同一网格内
		if move_slot(slot, target_position, _drag_start_effective_size):
			pass
		else:
			# 放置失败：恢复原位置和原旋转
			slot.rotation_index = _drag_start_rotation
			_apply_slot_visual_size(slot)
			var old_grid_pos = _vec2i_to_grid_pos(old_slot_position)
			slot.position = grid_to_screen(old_grid_pos)
			slot.grid_position = old_slot_position
	else:
		# 跨网格
		if target_grid.accept_external_slot(slot, target_position, self):
			# Slot已被移动到目标网格，如果还在当前容器中则移除
			if slot.get_parent() == slot_container:
				slot_container.remove_child(slot)
		else:
			# 接收失败：恢复原位置和原旋转
			slot.rotation_index = _drag_start_rotation
			_apply_slot_visual_size(slot)
			var old_grid_pos = _vec2i_to_grid_pos(old_slot_position)
			slot.position = grid_to_screen(old_grid_pos)
			slot.grid_position = old_slot_position
	# 结束拖拽
	dragging_slot = null


# 目标网格尝试接收来自其它网格的槽位（占位按当前旋转；使用 place_search_range 找最近空位）
func accept_external_slot(slot: DraggableSlot, target_slot_position: Vector2i, old_grid: DraggableGrid) -> bool:
	var eff = slot.get_effective_size()
	var old_grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var old_rect = GridRect.new(old_grid_pos, eff.x, eff.y)
	if old_grid and old_grid.grid_system:
		old_grid.grid_system.remove(old_rect)

	var center_pos = _vec2i_to_grid_pos(target_slot_position)
	var result = grid_system.can_place_or_find_nearby(center_pos, eff.x, eff.y, place_search_range)
	if result.is_valid:
		var new_rect = result.rect
		grid_system.place(new_rect, null, result.region_id)
		# 断开与原网格的信号连接（如果存在）
		if old_grid:
			var old_drag_callable = Callable(old_grid, "_on_slot_dragged")
			var old_click_callable = Callable(old_grid, "_on_slot_clicked")
			if slot.is_connected("slot_dragged", old_drag_callable):
				slot.disconnect("slot_dragged", old_drag_callable)
			if slot.is_connected("slot_clicked", old_click_callable):
				slot.disconnect("slot_clicked", old_click_callable)
		# 连接到当前网格的信号（使用 Callable）
		var self_drag_callable = Callable(self, "_on_slot_dragged")
		var self_click_callable = Callable(self, "_on_slot_clicked")
		if not slot.is_connected("slot_dragged", self_drag_callable):
			slot.slot_dragged.connect(self_drag_callable)
		if not slot.is_connected("slot_clicked", self_click_callable):
			slot.slot_clicked.connect(self_click_callable)

		if slot.get_parent():
			slot.get_parent().remove_child(slot)
		slot_container.add_child(slot)
		var final_position = Vector2i(new_rect.pos.x, new_rect.pos.y)
		slot.grid_position = final_position
		slot.position = grid_to_screen(new_rect.pos)
		_apply_slot_visual_size(slot)
		
		# 获取旧区域标识
		var old_region_id = ""
		if old_grid and old_grid.grid_system:
			old_region_id = old_grid.grid_system.get_cell_region_id(old_grid_pos)
		slot_moved.emit(slot, old_grid_pos.to_vector2i(), final_position, old_region_id, result.region_id)
		return true
	else:
		if old_grid and old_grid.grid_system:
			var restore_result = old_grid.grid_system.can_place(old_rect)
			if restore_result.is_valid:
				old_grid.grid_system.place(old_rect, null, restore_result.region_id)
		return false

#* 处理槽位点击事件（开始拖拽时记录旋转与占位，用于失败恢复）
func _on_slot_clicked(slot: DraggableSlot) -> void:
	dragging_slot = slot
	_drag_start_rotation = slot.rotation_index
	_drag_start_effective_size = slot.get_effective_size()
	# 记录拖拽开始时的区域标识
	if grid_system:
		var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
		_drag_start_region_id = grid_system.get_cell_region_id(grid_pos)

#* 清空所有槽位
func clear_all_slots() -> void:
	# 清空网格系统
	if grid_system:
		grid_system.clear()
	
	# 移除所有slot
	if slot_container:
		for child in slot_container.get_children():
			child.queue_free()
	slot_removed.emit(null)

#* 获取槽位数量
#* @return 当前网格中的槽位数量
func get_slot_count() -> int:
	if slot_container:
		return slot_container.get_child_count()
	return 0
