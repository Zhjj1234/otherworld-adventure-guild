#* 支持手柄/键盘导航的拖拽表格控件
extends DraggableGrid
class_name ControllerDraggableGrid

#* 手柄/键盘选中的槽位
var focused_slot: ControllerDraggableSlot = null

#* 虚拟光标位置（格子坐标）
var virtual_cursor_pos: Vector2i = Vector2i(0, 0)

#* 是否处于手柄控制模式
var is_controller_mode: bool = false

#* 覆盖工厂方法，创建支持手柄的 Slot
func _create_slot_instance() -> DraggableSlot:
	return ControllerDraggableSlot.new()

func _process(delta: float) -> void:
	if dragging_slot != null and is_controller_mode:
		# 手柄模式：让物品的“左上格中心”对齐“目标格中心”
		var target_cell_center = global_position + grid_to_screen(_vec2i_to_grid_pos(virtual_cursor_pos)) + Vector2(cell_size/2.0, cell_size/2.0)
		var first_cell_offset = Vector2(cell_size/2.0, cell_size/2.0)
		dragging_slot.global_position = target_cell_center - first_cell_offset
	else:
		super._process(delta)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	
	_handle_controller_input(event)
	
	# 如果是鼠标事件，调用父类处理
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		super._input(event)

func _handle_controller_input(event: InputEvent) -> void:
	var dir = Vector2i.ZERO
	if event.is_action_pressed("ui_up"): dir.y = -1
	elif event.is_action_pressed("ui_down"): dir.y = 1
	elif event.is_action_pressed("ui_left"): dir.x = -1
	elif event.is_action_pressed("ui_right"): dir.x = 1
	
	if dir != Vector2i.ZERO:
		is_controller_mode = true
		_move_virtual_cursor(dir)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_game_confirm"):
		is_controller_mode = true
		_handle_controller_confirm()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_game_alt_action"):
		is_controller_mode = true
		if dragging_slot != null:
			dragging_slot.rotate_clockwise_90()
			_apply_slot_visual_size(dragging_slot)
			DebugPrint.print_simple("手柄旋转槽位", _DBG_CALLER)
			get_viewport().set_input_as_handled()
	
	if event is InputEventMouseMotion:
		is_controller_mode = false

#* 移动虚拟光标 (包含跳过空白区域和边缘碰撞检测)
func _move_virtual_cursor(dir: Vector2i) -> void:
	if dragging_slot != null:
		var eff_size = dragging_slot.get_effective_size()
		var next_pos = virtual_cursor_pos + dir
		
		# 1. 尝试寻找下一个有效的区域位置（跳过空白间隙）
		var found_valid = false
		var search_pos = next_pos
		
		# 获取所有区域构成的总边界，防止无限循环
		var total_bounds = _get_total_grid_bounds()
		
		while total_bounds.has_point(search_pos):
			if _is_shape_within_regions(search_pos, eff_size):
				found_valid = true
				next_pos = search_pos
				break
			# 如果当前位置不合法，继续沿方向寻找
			search_pos += dir
		
		# 2. 如果找到了有效位置，则更新坐标；否则保持不动（边缘阻挡）
		if found_valid:
			virtual_cursor_pos = next_pos
			DebugPrint.print_simple("【手柄移动】当前基准点格子: %s" % str(virtual_cursor_pos), _DBG_CALLER)
			_update_focused_slot()
	else:
		_jump_to_next_slot(dir)

#* 检查整个形状是否都在有效区域内
func _is_shape_within_regions(pos: Vector2i, shape_size: Vector2i) -> bool:
	if grid_system == null: return false
	var rect = GridRect.new(_vec2i_to_grid_pos(pos), shape_size.x, shape_size.y)
	
	# can_place 内部会检查所有覆盖的格子是否在 bounds 内且 region_id 一致
	# 这里我们只需要知道它是否在“合法区域”内
	# 注意：我们这里不考虑碰撞（是否被占用），只考虑“地皮”是否存在
	for p in rect.get_covered_positions():
		if grid_system.get_cell_region_id(p) == "":
			return false
	return true

#* 获取所有区域构成的矩形范围索引
func _get_total_grid_bounds() -> Rect2i:
	if grid_system == null or grid_system.regions.size() == 0:
		return Rect2i(0, 0, 0, 0)
	
	var min_pos = Vector2i(9999, 9999)
	var max_pos = Vector2i(-9999, -9999)
	
	for region in grid_system.regions:
		min_pos.x = min(min_pos.x, region.pos.x)
		min_pos.y = min(min_pos.y, region.pos.y)
		max_pos.x = max(max_pos.x, region.pos.x + region.width)
		max_pos.y = max(max_pos.y, region.pos.y + region.height)
	
	return Rect2i(min_pos, max_pos - min_pos)

#* 在 Slot 之间跳转 (选择模式)
func _jump_to_next_slot(dir: Vector2i) -> void:
	if slot_container == null: return
	var all_slots = slot_container.get_children()
	if all_slots.size() == 0: return
	
	if focused_slot == null:
		focused_slot = all_slots[0]
		focused_slot.is_focused = true
		virtual_cursor_pos = focused_slot.grid_position
		return

	var best_next = null
	var min_dist = 999999.0
	var current_center = focused_slot.global_position + focused_slot.size / 2.0
	
	for child in all_slots:
		if not child is ControllerDraggableSlot: continue
		var s: ControllerDraggableSlot = child
		if s == focused_slot: continue
		
		var target_center = s.global_position + s.size / 2.0
		var diff = target_center - current_center
		
		var is_match = false
		if dir.x > 0: # 右
			if diff.x > 10 and abs(diff.y) <= abs(diff.x): is_match = true
		elif dir.x < 0: # 左
			if diff.x < -10 and abs(diff.y) <= abs(diff.x): is_match = true
		elif dir.y > 0: # 下
			if diff.y > 10 and abs(diff.x) <= abs(diff.y): is_match = true
		elif dir.y < 0: # 上
			if diff.y < -10 and abs(diff.x) <= abs(diff.y): is_match = true
		
		if is_match:
			var dist = diff.length()
			if dist < min_dist:
				min_dist = dist
				best_next = s
	
	if best_next:
		if focused_slot: focused_slot.is_focused = false
		best_next.is_focused = true
		focused_slot = best_next
		virtual_cursor_pos = focused_slot.grid_position
		DebugPrint.print_simple("手柄跳转到槽位: %s" % str(virtual_cursor_pos), _DBG_CALLER)

#* 更新选中状态
func _update_focused_slot() -> void:
	if dragging_slot != null:
		if focused_slot and focused_slot != dragging_slot:
			focused_slot.is_focused = false
			focused_slot = null
		if dragging_slot is ControllerDraggableSlot:
			dragging_slot.is_focused = true
		return

	if focused_slot:
		focused_slot.is_focused = false
		focused_slot = null
	
	var grid_pos = _vec2i_to_grid_pos(virtual_cursor_pos)
	var rect = GridRect.new(grid_pos, 1, 1)
	var overlaps = get_overlapping_slots(rect)
	
	if overlaps.size() > 0:
		focused_slot = overlaps[0]
		focused_slot.is_focused = true

#* 手柄确认逻辑
func _handle_controller_confirm() -> void:
	if dragging_slot == null:
		if focused_slot:
			virtual_cursor_pos = focused_slot.grid_position
			var slot_to_drag = focused_slot
			slot_to_drag.is_moving = true
			slot_to_drag.is_focused = true
			_on_slot_clicked(slot_to_drag)
			DebugPrint.print_simple("手柄抓取槽位: %s" % str(virtual_cursor_pos), _DBG_CALLER)
	else:
		var slot_to_place = dragging_slot
		var result = execute_place_at_grid(slot_to_place, virtual_cursor_pos, self)
		if result[0]:
			if not result[1]:
				slot_to_place.is_dragging = false
				if slot_to_place is ControllerDraggableSlot:
					slot_to_place.is_moving = false
					slot_to_place.is_focused = false
				dragging_slot = null
				_update_focused_slot()
			else:
				DebugPrint.print_simple("手柄交换成功", _DBG_CALLER)
		else:
			DebugPrint.print_simple("手柄放置失败", _DBG_CALLER)

#* 交换拾取
func _pick_up_slot_for_swap(slot: DraggableSlot, _mouse_pos: Vector2) -> void:
	super._pick_up_slot_for_swap(slot, _mouse_pos)
	if is_controller_mode and slot is ControllerDraggableSlot:
		slot.is_focused = true
		slot.is_moving = true
		focused_slot = slot

#* 放置成功后的清理
func execute_place_at_grid(slot: DraggableSlot, target_position: Vector2i, target_grid: DraggableGrid) -> Array:
	var ret = super.execute_place_at_grid(slot, target_position, target_grid)
	if ret[0]:
		if slot is ControllerDraggableSlot:
			slot.is_moving = false
			slot.is_focused = false
		if focused_slot == slot:
			focused_slot = null
	return ret
