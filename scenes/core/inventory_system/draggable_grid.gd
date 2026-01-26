#* 可拖拽表格控件
#* 提供一个网格表格，可以在其中拖拽槽位
extends Control
class_name DraggableGrid

signal slot_added(slot: DraggableSlot, position: Vector2i)
signal slot_moved(slot: DraggableSlot, old_position: Vector2i, new_position: Vector2i)
signal slot_removed(slot: DraggableSlot)

#* 表格大小（列数x行数）
@export var grid_size: Vector2i = Vector2i(10, 8)

#* 格子大小（像素）
@export var cell_size: int = 50

#* 格子间距
@export var cell_spacing: int = 2

#* 网格线颜色
@export var grid_line_color: Color = Color(0.3, 0.3, 0.3, 0.5)

#* 背景颜色
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)

#* 网格系统
var grid_system: GridSystem = null

#* 当前拖拽的槽位
var dragging_slot: DraggableSlot = null

#* 网格容器
var grid_container: Control = null

#* 背景
var bg_rect: ColorRect = null

func _ready() -> void:
	# 初始化网格系统
	grid_system = GridSystem.new(grid_size)
	
	# 创建背景
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = background_color
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)
	
	# 创建网格容器
	grid_container = Control.new()
	grid_container.name = "GridContainer"
	grid_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grid_container)
	
	# 设置最小大小
	custom_minimum_size = Vector2(
		grid_size.x * (cell_size + cell_spacing) + cell_spacing,
		grid_size.y * (cell_size + cell_spacing) + cell_spacing
	)
	
	# 绘制网格
	queue_redraw()

func _draw() -> void:
	# 绘制网格线
	for x in range(grid_size.x + 1):
		var x_pos = x * (cell_size + cell_spacing) + cell_spacing
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, grid_size.y * (cell_size + cell_spacing) + cell_spacing),
			grid_line_color,
			1.0
		)
	
	for y in range(grid_size.y + 1):
		var y_pos = y * (cell_size + cell_spacing) + cell_spacing
		draw_line(
			Vector2(0, y_pos),
			Vector2(grid_size.x * (cell_size + cell_spacing) + cell_spacing, y_pos),
			grid_line_color,
			1.0
		)

#* 将屏幕坐标转换为格子坐标
func screen_to_grid(screen_pos: Vector2) -> GridPos:
	var local_pos = screen_pos - grid_container.global_position
	var grid_x = int((local_pos.x - cell_spacing) / (cell_size + cell_spacing))
	var grid_y = int((local_pos.y - cell_spacing) / (cell_size + cell_spacing))
	return GridPos.new(grid_x, grid_y)

#* 将格子坐标转换为屏幕位置（左上角）
func grid_to_screen(grid_pos: GridPos) -> Vector2:
	return Vector2(
		grid_pos.x * (cell_size + cell_spacing) + cell_spacing,
		grid_pos.y * (cell_size + cell_spacing) + cell_spacing
	)

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
func is_position_occupied(slot_position: Vector2i, slot_size: Vector2i = Vector2i(1, 1), exclude_slot: DraggableSlot = null) -> bool:
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
	if grid_system.place(rect, null):
		# 创建槽位
		var new_slot = DraggableSlot.new()
		new_slot.slot_size = slot_size
		new_slot.grid_position = slot_position
		new_slot.set_slot_color(slot_color)
		new_slot.set_slot_size(slot_size)
		
		# 设置位置和大小
		var screen_pos = grid_to_screen(grid_pos)
		new_slot.position = screen_pos
		new_slot.size = Vector2(
			slot_size.x * cell_size + (slot_size.x - 1) * cell_spacing,
			slot_size.y * cell_size + (slot_size.y - 1) * cell_spacing
		)
		
		# 连接信号
		new_slot.slot_dragged.connect(_on_slot_dragged)
		new_slot.slot_clicked.connect(_on_slot_clicked)
		
		# 添加到容器
		grid_container.add_child(new_slot)
		
		slot_added.emit(new_slot, slot_position)
		return new_slot
	else:
		push_warning("位置已被占用或超出范围")
		return null

#* 移除槽位
#* @param slot 要移除的槽位对象
func remove_slot(slot: DraggableSlot) -> void:
	var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var rect = GridRect.new(grid_pos, slot.slot_size.x, slot.slot_size.y)
	grid_system.remove(rect)
	slot.queue_free()
	slot_removed.emit(slot)

#* 移动槽位到新位置
#* @param slot 要移动的槽位对象
#* @param new_slot_position 新位置（格子坐标）
#* @return 是否移动成功
func move_slot(slot: DraggableSlot, new_slot_position: Vector2i) -> bool:
	# 先移除旧位置
	var old_grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var old_rect = GridRect.new(old_grid_pos, slot.slot_size.x, slot.slot_size.y)
	grid_system.remove(old_rect)
	
	# 检查新位置是否可用
	var new_grid_pos = _vec2i_to_grid_pos(new_slot_position)
	var new_rect = GridRect.new(new_grid_pos, slot.slot_size.x, slot.slot_size.y)
	
	var result = grid_system.can_place(new_rect)
	if result.is_valid:
		# 放置到新位置
		grid_system.place(new_rect, null)
		
		# 更新槽位位置
		var old_slot_position = slot.grid_position
		slot.grid_position = new_slot_position
		
		# 更新屏幕位置
		var screen_pos = grid_to_screen(new_grid_pos)
		slot.position = screen_pos
		
		slot_moved.emit(slot, old_slot_position, new_slot_position)
		return true
	else:
		# 恢复旧位置
		grid_system.place(old_rect, null)
		return false

#* 查找可用位置
#* @param slot_size 要查找的槽位大小（宽x高，占几格）
#* @return 找到的可用位置（格子坐标），如果没有可用位置则返回Vector2i(-1, -1)
func find_available_position(slot_size: Vector2i) -> Vector2i:
	for grid_y in range(grid_size.y - slot_size.y + 1):
		for grid_x in range(grid_size.x - slot_size.x + 1):
			var slot_position = Vector2i(grid_x, grid_y)
			var grid_pos = _vec2i_to_grid_pos(slot_position)
			var rect = GridRect.new(grid_pos, slot_size.x, slot_size.y)
			if grid_system.can_place(rect).is_valid:
				return slot_position
	return Vector2i(-1, -1)

#* 对齐到网格
#* @param screen_pos 屏幕坐标
#* @return 对齐后的格子坐标
func snap_to_grid(screen_pos: Vector2) -> Vector2i:
	var grid_pos = screen_to_grid(screen_pos)
	# 确保在范围内
	var clamped_x = clamp(grid_pos.x, 0, grid_size.x - 1)
	var clamped_y = clamp(grid_pos.y, 0, grid_size.y - 1)
	return Vector2i(clamped_x, clamped_y)

#* 处理槽位拖拽结束事件
#* @param slot 拖拽的槽位对象
#* @param old_slot_position 拖拽前的位置（格子坐标）
#* @param click_offset 点击位置相对于槽位左上角的格子偏移
func _on_slot_dragged(slot: DraggableSlot, old_slot_position: Vector2i, click_offset: Vector2i) -> void:
	# 获取鼠标位置对应的格子坐标
	var mouse_pos = get_global_mouse_position()
	var mouse_grid_pos = screen_to_grid(mouse_pos)
	
	# 根据点击偏移量调整最终位置
	# 期望：鼠标点击的格子（相对于槽位）应该对应到目标位置的格子
	# 例如：1×3的槽位，点击中间格子（offset x=1），则槽位的左上角应该是 mouse_grid_pos.x - 1
	var target_position = Vector2i(
		mouse_grid_pos.x - click_offset.x,
		mouse_grid_pos.y - click_offset.y
	)
	
	# 尝试移动到新位置
	if move_slot(slot, target_position):
		# 移动成功
		pass
	else:
		# 移动失败，恢复原位置
		var old_grid_pos = _vec2i_to_grid_pos(old_slot_position)
		var screen_pos = grid_to_screen(old_grid_pos)
		slot.position = screen_pos
		slot.grid_position = old_slot_position

#* 处理槽位点击事件
#* @param slot 被点击的槽位对象
func _on_slot_clicked(slot: DraggableSlot) -> void:
	# 可以在这里添加点击处理逻辑
	pass

#* 清空所有槽位
func clear_all_slots() -> void:
	# 清空网格系统
	grid_system.clear()
	
	# 移除所有子节点
	for child in grid_container.get_children():
		child.queue_free()
	slot_removed.emit(null)

#* 获取槽位数量
#* @return 当前网格中的槽位数量
func get_slot_count() -> int:
	return grid_container.get_child_count()
