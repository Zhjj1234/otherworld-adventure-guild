#* 可拖拽表格控件 (基础类 - 仅包含鼠标逻辑)
#* 提供一个网格表格，可以在其中拖拽槽位，支持多区域管理
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

#* 放置搜索范围（格数）：0=仅精确放置或交换；>0 时在范围内找最近空位
@export var place_search_range: int = 0
#* 调试日志开关（用于排查放置/交换异常）
@export var debug_log: bool = true

#* 网格系统
var grid_system: GridSystem = null

#* 区域视图字典（region_id -> Control）
var region_views: Dictionary = {}

#* Slot容器（所有slot的容器，与区域视图同级）
var slot_container: Control = null

#* 当前拖拽的槽位
var dragging_slot: DraggableSlot = null

#* 当前手持是否来自交换（交换后失败不应恢复原位）
var hand_from_swap: bool = false

#* 拖拽开始时的信息（用于失败恢复）
var _drag_start_rotation: int = 0
var _drag_start_effective_size: Vector2i = Vector2i(1, 1)
var _drag_start_region_id: String = ""

const _DBG_CALLER := "res://scenes/core/inventory_system/draggable_grid/draggable_grid.gd"

func _dbg(message: String) -> void:
	if debug_log:
		DebugPrint.print_simple(message, _DBG_CALLER)

func _dbg_region_bounds() -> void:
	if not debug_log or grid_system == null:
		return
	var min_x := 999999
	var min_y := 999999
	var max_x := -999999
	var max_y := -999999
	for region in grid_system.regions:
		min_x = min(min_x, region.pos.x)
		min_y = min(min_y, region.pos.y)
		max_x = max(max_x, region.pos.x + region.width - 1)
		max_y = max(max_y, region.pos.y + region.height - 1)
	_dbg("REGION bounds: min=(%d,%d) max=(%d,%d)" % [min_x, min_y, max_x, max_y])

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
#* @param region 区域数据，包含逻辑坐标（GridPos）、尺寸和区域ID
#* 
#* 重要说明：
#* - region.pos 是逻辑坐标，用于 GridSystem 的碰撞检测和物品放置
#* - 多个区域必须使用不同的逻辑坐标，否则会在逻辑空间中重叠
#* - 视觉位置通过 set_region_base_point() 单独设置，不影响逻辑坐标
#* 
#* 示例：
#* add_region(GridRegion.new(GridPos.new(0, 0), 5, 3, "backpack_1"))  # 逻辑坐标 (0,0)
#* add_region(GridRegion.new(GridPos.new(5, 0), 5, 3, "backpack_2"))  # 逻辑坐标 (5,0)，不重叠
func add_region(region: GridRegion) -> void:
	if grid_system == null:
		grid_system = GridSystem.new()
	
	grid_system.add_region(region)
	
	# 该区域 View 的基准点（默认 = 逻辑 pos 对应的像素位置）
	var default_base: Vector2 = Vector2(
		region.pos.x * (cell_size + cell_spacing) + cell_spacing,
		region.pos.y * (cell_size + cell_spacing) + cell_spacing
	)
	
	# 创建区域视图（基准点在 View 上：view.position = 该区域左上角）
	var region_view = GridRegionViewClass.new(region, cell_size, cell_spacing)
	region_view.name = "RegionView_%s" % region.region_id
	region_view.position = default_base
	region_view.grid_line_color = grid_line_color
	region_view.background_color = background_color
	region_view.show_cell_background = show_cell_background
	region_view.cell_background_color = cell_background_color
	region_view.cell_background_texture = cell_background_texture
	region_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_view.z_index = 0
	add_child(region_view)
	
	region_views[region.region_id] = region_view
	
	_update_total_size()

#* 移除一个区域
func remove_region(region_id: String) -> void:
	if grid_system:
		grid_system.remove_region(region_id)
	
	if region_views.has(region_id):
		var view = region_views[region_id]
		region_views.erase(region_id)
		if is_instance_valid(view):
			view.queue_free()
	
	_update_total_size()

#* 根据 region_id 获取区域数据
func get_region_by_id(region_id: String) -> GridRegion:
	if grid_system == null:
		return null
	for r in grid_system.regions:
		if r.region_id == region_id:
			return r
	return null

#* 获取区域尺寸（格数：宽×高）
func get_region_size(region_id: String) -> Vector2i:
	var r: GridRegion = get_region_by_id(region_id)
	if r == null:
		return Vector2i.ZERO
	return Vector2i(r.width, r.height)

#* 设置区域的视觉基准点（该区域 View 的左上角在本 DraggableGrid 内的本地像素坐标）
#* @param region_id 区域ID
#* @param local_position 视觉位置（像素坐标）
#* 
#* 重要说明：
#* - 此方法只设置视觉显示位置，不影响逻辑坐标
#* - 逻辑坐标在 add_region() 时通过 GridRegion.pos 设置
#* - 可以自由调整视觉位置而不影响物品放置逻辑
#* 
#* 示例：
#* add_region(GridRegion.new(GridPos.new(0, 0), 5, 3, "backpack_1"))  # 逻辑坐标 (0,0)
#* set_region_base_point("backpack_1", Vector2(10, 10))  # 视觉位置 (10,10)
#* set_region_base_point("backpack_1", Vector2(100, 100))  # 改变视觉位置，逻辑坐标不变
func set_region_base_point(region_id: String, local_position: Vector2) -> void:
	if region_views.has(region_id):
		region_views[region_id].position = local_position
		_update_total_size()

#* 获取区域的视觉基准点（即该区域 View 的 position，本地像素坐标）
func get_region_base_point(region_id: String) -> Vector2:
	if region_views.has(region_id):
		return region_views[region_id].position
	return Vector2.ZERO

#* 更新整体大小（为所有区域 View 的基准点+尺寸的包围盒）
func _update_total_size() -> void:
	if grid_system == null or grid_system.regions.size() == 0:
		return
	
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	
	for region in grid_system.regions:
		if not region_views.has(region.region_id):
			continue
		var view: Control = region_views[region.region_id]
		var base: Vector2 = view.position
		var w_px: int = region.width * (cell_size + cell_spacing) + cell_spacing
		var h_px: int = region.height * (cell_size + cell_spacing) + cell_spacing
		min_x = min(min_x, base.x)
		min_y = min(min_y, base.y)
		max_x = max(max_x, base.x + w_px)
		max_y = max(max_y, base.y + h_px)
	
	if min_x != INF:
		custom_minimum_size = Vector2(max_x - min_x, max_y - min_y)
	clip_contents = true

func _process(_delta: float) -> void:
	# 基础类仅处理鼠标跟随
	if dragging_slot != null:
		dragging_slot.global_position = get_global_mouse_position() - dragging_slot.drag_offset
		# 确保拖拽中的 slot 始终在最上层
		if slot_container and dragging_slot.get_parent() == slot_container:
			slot_container.move_child(dragging_slot, slot_container.get_child_count() - 1)

func _input(event: InputEvent) -> void:
	if dragging_slot == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# 鼠标右键旋转
			dragging_slot.rotate_clockwise_90()
			_apply_slot_visual_size(dragging_slot)
			# 旋转后更新 drag_offset，使 slot 中心与鼠标对齐
			dragging_slot.drag_offset = dragging_slot.size / 2.0
			# 同时更新 click_grid_offset
			var eff = dragging_slot.get_effective_size()
			dragging_slot.click_grid_offset = Vector2i(int(floor(eff.x / 2.0)), int(floor(eff.y / 2.0)))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 鼠标左键放下
			var result = _try_place_held_slot_at(dragging_slot, get_global_mouse_position())
			if result[0] and not result[1]:
				dragging_slot.is_dragging = false
				dragging_slot.z_index = 10  # 恢复正常的 z_index
				dragging_slot = null
			get_viewport().set_input_as_handled()

#* 根据槽位当前有效尺寸更新其显示大小（像素）
func _apply_slot_visual_size(slot: DraggableSlot) -> void:
	var eff = slot.get_effective_size()
	var width_px = eff.x * cell_size + (eff.x - 1) * cell_spacing
	var height_px = eff.y * cell_size + (eff.y - 1) * cell_spacing
	slot.set_custom_minimum_size(Vector2(width_px, height_px))
	slot.size = Vector2(width_px, height_px)

#* 将屏幕坐标转换为格子坐标
#* 按每个区域 View 的基准点（view.position）+ 尺寸判断落在哪个区域；多区域重叠时优先“在前面”的 View（z_index 高、子节点顺序靠后）
func screen_to_grid(screen_pos: Vector2) -> GridPos:
	var local_pos: Vector2 = screen_pos - global_position
	var candidates: Array = []
	for region_id in region_views:
		var view: Control = region_views[region_id]
		var reg_data: GridRegion = get_region_by_id(region_id)
		if reg_data == null:
			continue
		var base: Vector2 = view.position
		var w_px: int = reg_data.width * (cell_size + cell_spacing) + cell_spacing
		var h_px: int = reg_data.height * (cell_size + cell_spacing) + cell_spacing
		var rect: Rect2 = Rect2(base, Vector2(w_px, h_px))
		if rect.has_point(local_pos):
			candidates.append({ "region_id": region_id, "view": view, "region": reg_data })
	if candidates.is_empty():
		var grid_x: int = int((local_pos.x - cell_spacing) / (cell_size + cell_spacing))
		var grid_y: int = int((local_pos.y - cell_spacing) / (cell_size + cell_spacing))
		return GridPos.new(grid_x, grid_y)
	candidates.sort_custom(func(a, b):
		if a.view.z_index != b.view.z_index:
			return a.view.z_index > b.view.z_index
		return a.view.get_index() > b.view.get_index()
	)
	var chosen: Dictionary = candidates[0] as Dictionary
	var reg: GridRegion = chosen.region as GridRegion
	var base_vec: Vector2 = (chosen.view as Control).position
	var local_in_region: Vector2 = local_pos - base_vec
	var cell_off_x: int = int((local_in_region.x - cell_spacing) / (cell_size + cell_spacing))
	var cell_off_y: int = int((local_in_region.y - cell_spacing) / (cell_size + cell_spacing))
	cell_off_x = clampi(cell_off_x, 0, reg.width - 1)
	cell_off_y = clampi(cell_off_y, 0, reg.height - 1)
	return GridPos.new(reg.pos.x + cell_off_x, reg.pos.y + cell_off_y)

#* 将格子坐标转换为屏幕位置（本地坐标）
#* 根据格子所在区域，用该区域 View 的基准点（view.position）换算
func grid_to_screen(grid_pos: GridPos) -> Vector2:
	if grid_system == null:
		return Vector2(
			grid_pos.x * (cell_size + cell_spacing) + cell_spacing,
			grid_pos.y * (cell_size + cell_spacing) + cell_spacing
		)
	var region_id: String = grid_system.get_cell_region_id(grid_pos)
	if "&" in region_id:
		region_id = region_id.split("&")[0]
	var region: GridRegion = get_region_by_id(region_id)
	if region == null or not region_views.has(region_id):
		return Vector2(
			grid_pos.x * (cell_size + cell_spacing) + cell_spacing,
			grid_pos.y * (cell_size + cell_spacing) + cell_spacing
		)
	var base: Vector2 = region_views[region_id].position
	var off_x: int = grid_pos.x - region.pos.x
	var off_y: int = grid_pos.y - region.pos.y
	return base + Vector2(
		off_x * (cell_size + cell_spacing) + cell_spacing,
		off_y * (cell_size + cell_spacing) + cell_spacing
	)

#* 获取格子所在的区域视图
func get_region_view_at(grid_pos: GridPos) -> Control:
	if grid_system == null: return null
	var region_id = grid_system.get_cell_region_id(grid_pos)
	if region_id == "": return null
	if "&" in region_id: region_id = region_id.split("&")[0]
	if region_views.has(region_id): return region_views[region_id]
	return null

#* 将Vector2i转换为GridPos
func _vec2i_to_grid_pos(vec: Vector2i) -> GridPos:
	return GridPos.new(vec.x, vec.y)

#* 将GridPos转换为Vector2i
func _grid_pos_to_vec2i(grid_pos: GridPos) -> Vector2i:
	return grid_pos.to_vector2i()

#* 检查位置是否有效
func is_position_valid(slot_position: Vector2i, slot_size: Vector2i = Vector2i(1, 1)) -> bool:
	var grid_pos = _vec2i_to_grid_pos(slot_position)
	var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
	var result = grid_system.can_place(rect)
	return result.is_valid

#* 添加槽位
func add_slot(slot_size: Vector2i = Vector2i(1, 1), slot_position: Vector2i = Vector2i(-1, -1), slot_color: Color = Color(0.3, 0.5, 0.8, 0.8), region_id: String = "") -> DraggableSlot:
	if slot_position == Vector2i(-1, -1):
		slot_position = find_available_position(slot_size, region_id)
		if slot_position == Vector2i(-1, -1):
			push_warning("区域空间已满")
			return null
	
	var grid_pos = _vec2i_to_grid_pos(slot_position)
	var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
	var place_result = grid_system.can_place(rect)
	if place_result.is_valid and (region_id == "" or place_result.region_id == region_id) and grid_system.place(rect, null, place_result.region_id):
		var new_slot = _create_slot_instance()
		new_slot.slot_size = slot_size
		new_slot.grid_position = slot_position
		new_slot.set_slot_color(slot_color)
		new_slot.set_slot_size(slot_size)
		new_slot.position = grid_to_screen(grid_pos)
		_apply_slot_visual_size(new_slot)
		new_slot.slot_dragged.connect(Callable(self, "_on_slot_dragged"))
		new_slot.slot_clicked.connect(Callable(self, "_on_slot_clicked"))
		slot_container.add_child(new_slot)
		slot_added.emit(new_slot, slot_position, place_result.region_id)
		return new_slot
	return null

#* 创建 Slot 实例的工厂方法，子类可以覆盖以创建 ControllerDraggableSlot
func _create_slot_instance() -> DraggableSlot:
	return DraggableSlot.new()

#* 移除槽位
func remove_slot(slot: DraggableSlot) -> void:
	var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var eff = slot.get_effective_size()
	var rect = GridRect.new(grid_pos, eff.x, eff.y)
	grid_system.remove(rect)
	slot.queue_free()
	slot_removed.emit(slot)

#* 获取与指定矩形相交的槽位列表
func get_overlapping_slots(rect: GridRect, exclude: DraggableSlot = null) -> Array[DraggableSlot]:
	var slots: Array[DraggableSlot] = []
	if slot_container == null: return slots
	for child in slot_container.get_children():
		if child is DraggableSlot:
			var s: DraggableSlot = child
			if exclude != null and s == exclude: continue
			var eff = s.get_effective_size()
			var s_left = s.grid_position.x
			var s_top = s.grid_position.y
			var s_right = s_left + eff.x
			var s_bottom = s_top + eff.y
			var r_left = rect.pos.x
			var r_top = rect.pos.y
			var r_right = r_left + rect.width
			var r_bottom = r_top + rect.height
			var intersects = r_left < s_right and r_right > s_left and r_top < s_bottom and r_bottom > s_top
			if intersects: slots.append(s)
	return slots

#* 交换拾取
func _pick_up_slot_for_swap(slot: DraggableSlot, _mouse_pos: Vector2) -> void:
	dragging_slot = slot
	hand_from_swap = true
	slot.is_dragging = true
	slot.drag_offset = slot.size / 2.0
	var eff = slot.get_effective_size()
	slot.click_grid_offset = Vector2i(int(floor(eff.x / 2.0)), int(floor(eff.y / 2.0)))
	_drag_start_rotation = slot.rotation_index
	_drag_start_effective_size = slot.get_effective_size()
	if slot_container: slot_container.move_child(slot, slot_container.get_child_count() - 1)
	slot.z_index = 100  # 设置更高的 z_index 确保在最上层

#* 移动槽位
func move_slot(slot: DraggableSlot, new_slot_position: Vector2i, _old_eff_size: Vector2i = Vector2i(-1, -1)) -> Array:
	var eff_cur = slot.get_effective_size()
	var old_grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var center_pos = _vec2i_to_grid_pos(new_slot_position)
	var my_rect = GridRect.new(center_pos, eff_cur.x, eff_cur.y)
	var overlaps = get_overlapping_slots(my_rect, slot)
	
	if overlaps.size() == 1:
		var other_slot = overlaps[0]
		var other_eff = other_slot.get_effective_size()
		var other_rect = GridRect.new(_vec2i_to_grid_pos(other_slot.grid_position), other_eff.x, other_eff.y)
		grid_system.remove(other_rect)
		var place_result = grid_system.can_place(my_rect)
		if place_result.is_valid:
			grid_system.place(my_rect, null, place_result.region_id)
			var old_pos = slot.grid_position
			slot.grid_position = Vector2i(my_rect.pos.x, my_rect.pos.y)
			slot.position = grid_to_screen(my_rect.pos)
			slot_moved.emit(slot, old_pos, slot.grid_position, grid_system.get_cell_region_id(old_grid_pos), place_result.region_id)
			slot.is_dragging = false
			slot.z_index = 10  # 恢复正常的 z_index
			_pick_up_slot_for_swap(other_slot, get_global_mouse_position())
			return [true, true]
		else:
			grid_system.place(other_rect, null, grid_system.get_cell_region_id(other_rect.pos))
			return [false, false]

	if overlaps.size() > 1: return [false, false]

	var result = grid_system.can_place_or_find_nearby(center_pos, eff_cur.x, eff_cur.y, place_search_range)
	if result.is_valid:
		var new_rect = result.rect
		grid_system.place(new_rect, null, result.region_id)
		var old_pos = slot.grid_position
		slot.grid_position = Vector2i(new_rect.pos.x, new_rect.pos.y)
		slot.position = grid_to_screen(new_rect.pos)
		slot_moved.emit(slot, old_pos, slot.grid_position, grid_system.get_cell_region_id(old_grid_pos), result.region_id)
		slot.z_index = 10  # 恢复正常的 z_index
		return [true, false]
	return [false, false]

#* 查找可用位置
func find_available_position(slot_size: Vector2i, region_id: String = "") -> Vector2i:
	if grid_system == null: return Vector2i(-1, -1)
	for region in grid_system.regions:
		if region_id != "" and region.region_id != region_id: continue
		for grid_y in range(region.pos.y, region.pos.y + region.height - slot_size.y + 1):
			for grid_x in range(region.pos.x, region.pos.x + region.width - slot_size.x + 1):
				var pos = Vector2i(grid_x, grid_y)
				if is_position_valid(pos, slot_size): return pos
	return Vector2i(-1, -1)

#* 鼠标点击放置
func _try_place_held_slot_at(slot: DraggableSlot, mouse_pos: Vector2) -> Array:
	var target_grid: DraggableGrid = null
	for g in INSTANCES:
		if not g: continue
		if Rect2(g.get_global_position(), g.size).has_point(mouse_pos):
			target_grid = g
			break
	
	var mouse_global_pos = mouse_pos
	var current_eff_size = slot.get_effective_size()
	var to_first_cell_center = Vector2(
		(current_eff_size.x - 1) / 2.0 * (cell_size + cell_spacing),
		(current_eff_size.y - 1) / 2.0 * (cell_size + cell_spacing)
	)
	var first_cell_center_global = mouse_global_pos - to_first_cell_center
	var target_grid_to_use = target_grid if target_grid != null else self
	var target_grid_pos_obj = target_grid_to_use.screen_to_grid(first_cell_center_global)
	var target_position = Vector2i(target_grid_pos_obj.x, target_grid_pos_obj.y)
	
	DebugPrint.print_simple("鼠标放置: 目标格子 %s" % str(target_position), _DBG_CALLER)
	return execute_place_at_grid(slot, target_position, target_grid_to_use)

#* 统一放置逻辑
func execute_place_at_grid(slot: DraggableSlot, target_position: Vector2i, target_grid: DraggableGrid) -> Array:
	if target_grid == null or target_grid == self:
		var ret = move_slot(slot, target_position, _drag_start_effective_size)
		if ret[0]:
			slot.is_dragging = false
			slot.z_index = 10  # 恢复正常的 z_index
			if not ret[1]: hand_from_swap = false
			return ret
		return [false, false]
	else:
		var ret = target_grid.accept_external_slot(slot, target_position, self)
		if ret[0]:
			slot.z_index = 10  # 恢复正常的 z_index
			if slot.get_parent() == slot_container: slot_container.remove_child(slot)
			hand_from_swap = false
			return ret
		return [false, false]

#* 处理跨网格
func accept_external_slot(slot: DraggableSlot, target_slot_position: Vector2i, old_grid: DraggableGrid) -> Array:
	var eff = slot.get_effective_size()
	var old_grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var center_pos = _vec2i_to_grid_pos(target_slot_position)
	var my_rect = GridRect.new(center_pos, eff.x, eff.y)
	var overlaps = get_overlapping_slots(my_rect, slot)
	
	if overlaps.size() == 1:
		var other_slot = overlaps[0]
		var other_eff = other_slot.get_effective_size()
		var other_rect = GridRect.new(_vec2i_to_grid_pos(other_slot.grid_position), other_eff.x, other_eff.y)
		grid_system.remove(other_rect)
		var place_result = grid_system.can_place(my_rect)
		if place_result.is_valid:
			grid_system.place(my_rect, null, place_result.region_id)
			if old_grid:
				slot.disconnect("slot_dragged", Callable(old_grid, "_on_slot_dragged"))
				slot.disconnect("slot_clicked", Callable(old_grid, "_on_slot_clicked"))
			slot.slot_dragged.connect(Callable(self, "_on_slot_dragged"))
			slot.slot_clicked.connect(Callable(self, "_on_slot_clicked"))
			if slot.get_parent(): slot.get_parent().remove_child(slot)
			slot_container.add_child(slot)
			var old_pos = slot.grid_position
			slot.grid_position = Vector2i(my_rect.pos.x, my_rect.pos.y)
			slot.position = grid_to_screen(my_rect.pos)
			_apply_slot_visual_size(slot)
			var old_reg = old_grid.grid_system.get_cell_region_id(old_grid_pos) if old_grid else ""
			slot_moved.emit(slot, old_pos, slot.grid_position, old_reg, place_result.region_id)
			slot.is_dragging = false
			slot.z_index = 10  # 恢复正常的 z_index
			_pick_up_slot_for_swap(other_slot, get_global_mouse_position())
			return [true, true]
		else:
			grid_system.place(other_rect, null, grid_system.get_cell_region_id(other_rect.pos))
			return [false, false]

	var result = grid_system.can_place_or_find_nearby(center_pos, eff.x, eff.y, place_search_range)
	if result.is_valid:
		grid_system.place(result.rect, null, result.region_id)
		if old_grid:
			slot.disconnect("slot_dragged", Callable(old_grid, "_on_slot_dragged"))
			slot.disconnect("slot_clicked", Callable(old_grid, "_on_slot_clicked"))
		slot.slot_dragged.connect(Callable(self, "_on_slot_dragged"))
		slot.slot_clicked.connect(Callable(self, "_on_slot_clicked"))
		if slot.get_parent(): slot.get_parent().remove_child(slot)
		slot_container.add_child(slot)
		var old_pos = slot.grid_position
		slot.grid_position = Vector2i(result.rect.pos.x, result.rect.pos.y)
		slot.position = grid_to_screen(result.rect.pos)
		_apply_slot_visual_size(slot)
		var old_reg = old_grid.grid_system.get_cell_region_id(old_grid_pos) if old_grid else ""
		slot_moved.emit(slot, old_pos, slot.grid_position, old_reg, result.region_id)
		slot.z_index = 10  # 恢复正常的 z_index
		return [true, false]
	return [false, false]

func _on_slot_clicked(slot: DraggableSlot) -> void:
	dragging_slot = slot
	hand_from_swap = false
	_drag_start_rotation = slot.rotation_index
	_drag_start_effective_size = slot.get_effective_size()
	if grid_system:
		var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
		_drag_start_region_id = grid_system.get_cell_region_id(grid_pos)
		grid_system.remove(GridRect.new(grid_pos, _drag_start_effective_size.x, _drag_start_effective_size.y))
	# 确保拖拽中的 slot 在最上层
	if slot_container and slot.get_parent() == slot_container:
		slot_container.move_child(slot, slot_container.get_child_count() - 1)
	slot.z_index = 100  # 设置更高的 z_index 确保在最上层

func _on_slot_dragged(slot: DraggableSlot, _old_pos: Vector2i, _offset: Vector2i) -> void:
	var result = _try_place_held_slot_at(slot, get_global_mouse_position())
	if result[0] and not result[1]: dragging_slot = null

func clear_all_slots() -> void:
	if grid_system: grid_system.clear()
	if slot_container:
		for child in slot_container.get_children(): child.queue_free()
	slot_removed.emit(null)

func get_slot_count() -> int:
	return slot_container.get_child_count() if slot_container else 0
