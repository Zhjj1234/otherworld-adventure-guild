#* 背包网格 - 背包系统的前端显示
#* 继承自 ControllerDraggableGrid，专门用于背包系统
extends "res://scenes/core/inventory_system/draggable_grid/controller_draggable_grid.gd"
class_name InventoryGrid

#* 绑定的背包系统（数据层）
var inventory_system: InventorySystem = null

#* 位置到 Slot 的映射（用于快速查找）
#* key: 位置字符串 "x,y"
#* value: DraggableSlot
#* 注意：由于GridSystem管理逻辑位置，不同区域的相同逻辑位置对应不同slot，但这里只存储一个
#* 实际查找时通过grid_system.get_cell_region_id确定region_id
var position_to_slot: Dictionary = {}

#* 临时存储待添加的 item_key（用于 add_item 方法）
var _pending_item_keys: Dictionary = {}

func _ready() -> void:
	super._ready()
	
	# 连接父类的信号，监听 slot 的添加和移动
	slot_added.connect(_on_slot_added)
	slot_moved.connect(_on_slot_moved)
	slot_removed.connect(_on_slot_removed)

#* 重写父类的 _apply_slot_visual_size，在更新视觉大小后重新更新显示文本
func _apply_slot_visual_size(slot: DraggableSlot) -> void:
	super._apply_slot_visual_size(slot)
	
	# 如果绑定了 InventorySystem，重新更新显示文本
	if inventory_system != null:
		# 获取slot所在的region_id
		var region_id = _get_slot_region_id(slot)
		if region_id != "":
			var slot_data = inventory_system.get_item(slot.grid_position, region_id)
			if slot_data:
				_update_slot_display(slot, slot_data)

#* 重写父类的 _input，在旋转后更新 InventorySystem 和显示
func _input(event: InputEvent) -> void:
	if dragging_slot != null:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				# 记录旋转前的状态
				var old_rotation = dragging_slot.rotation_index
				var slot_position = dragging_slot.grid_position
				
				# 调用父类处理旋转
				super._input(event)
				
				# 如果旋转成功，更新 InventorySystem
				if inventory_system != null and dragging_slot.rotation_index != old_rotation:
					var new_rotation = dragging_slot.rotation_index
					var region_id = _get_slot_region_id(dragging_slot)
					if region_id != "":
						var slot_data = inventory_system.get_item(slot_position, region_id)
						if slot_data:
							slot_data.rotation_index = new_rotation
							# 重新更新显示
							_update_slot_display(dragging_slot, slot_data)
							DebugPrint.print_simple("旋转更新: 位置=%s 旋转=%d region=%s" % [str(slot_position), new_rotation, region_id], "inventory_grid.gd", Color.YELLOW)
				return
		elif event.is_action_pressed("ui_game_alt_action"):
			# 手柄旋转（来自 ControllerDraggableGrid）
			if dragging_slot != null:
				var old_rotation = dragging_slot.rotation_index
				var slot_position = dragging_slot.grid_position
				
				# 调用父类处理旋转
				super._input(event)
				
				# 如果旋转成功，更新 InventorySystem
				if inventory_system != null and dragging_slot.rotation_index != old_rotation:
					var new_rotation = dragging_slot.rotation_index
					var region_id = _get_slot_region_id(dragging_slot)
					if region_id != "":
						var slot_data = inventory_system.get_item(slot_position, region_id)
						if slot_data:
							slot_data.rotation_index = new_rotation
							# 重新更新显示
							_update_slot_display(dragging_slot, slot_data)
							DebugPrint.print_simple("手柄旋转更新: 位置=%s 旋转=%d region=%s" % [str(slot_position), new_rotation, region_id], "inventory_grid.gd", Color.YELLOW)
				return
	
	# 其他输入事件交给父类处理
	super._input(event)

#* 设置绑定的背包系统
#* @param inventory 背包系统实例
func set_inventory_system(inventory: InventorySystem) -> void:
	if inventory_system != null:
		# 断开旧连接
		inventory_system.slot_data_changed.disconnect(_on_inventory_data_changed)
		inventory_system.item_added.disconnect(_on_inventory_item_added)
		inventory_system.item_removed.disconnect(_on_inventory_item_removed)
		inventory_system.item_moved.disconnect(_on_inventory_item_moved)
	
	inventory_system = inventory
	
	if inventory_system != null:
		# 连接新信号
		inventory_system.slot_data_changed.connect(_on_inventory_data_changed)
		inventory_system.item_added.connect(_on_inventory_item_added)
		inventory_system.item_removed.connect(_on_inventory_item_removed)
		inventory_system.item_moved.connect(_on_inventory_item_moved)
		
		# 同步现有数据
		_sync_from_inventory()

#* Slot 添加时的回调（来自 DraggableGrid）
func _on_slot_added(slot: DraggableSlot, position: Vector2i, region_id: String) -> void:
	if inventory_system == null:
		return
	
	# 记录位置到 slot 的映射
	var pos_key = _position_to_key(position)
	position_to_slot[pos_key] = slot
	
	# 检查是否有待添加的 item_key（通过 add_item 方法设置的）
	var item_key = _pending_item_keys.get(pos_key, "")
	if _pending_item_keys.has(pos_key):
		_pending_item_keys.erase(pos_key)
	
	# 通知 InventorySystem 添加物品
	var slot_size = slot.slot_size
	var rotation_index = slot.rotation_index
	inventory_system.add_item(position, rotation_index, item_key, slot_size, region_id)

#* Slot 移动时的回调（来自 DraggableGrid）
func _on_slot_moved(slot: DraggableSlot, old_position: Vector2i, new_position: Vector2i, old_region_id: String, new_region_id: String) -> void:
	if inventory_system == null:
		return
	
	# 更新位置映射
	var old_key = _position_to_key(old_position)
	var new_key = _position_to_key(new_position)
	
	if position_to_slot.has(old_key):
		position_to_slot.erase(old_key)
	position_to_slot[new_key] = slot
	
	# 通知 InventorySystem 移动物品
	var new_rotation = slot.rotation_index
	inventory_system.move_item(old_position, new_position, new_rotation, old_region_id, new_region_id)

#* Slot 移除时的回调（来自 DraggableGrid）
func _on_slot_removed(slot: DraggableSlot) -> void:
	if inventory_system == null or slot == null:
		return
	
	# 查找并移除位置映射
	var pos_key_to_remove = null
	for key in position_to_slot:
		if position_to_slot[key] == slot:
			pos_key_to_remove = key
			break
	
	if pos_key_to_remove:
		var position = _key_to_position(pos_key_to_remove)
		var region_id = _get_slot_region_id(slot)
		position_to_slot.erase(pos_key_to_remove)
		if region_id != "":
			inventory_system.remove_item(position, region_id)

#* InventorySystem 数据变更时的回调
func _on_inventory_data_changed(position: Vector2i, slot_data: ItemSlotData) -> void:
	# 需要找到对应的slot（可能在不同区域）
	var slot = null
	for pos_key in position_to_slot:
		var s = position_to_slot[pos_key]
		if s.grid_position == position:
			slot = s
			break
	
	if slot == null:
		return
	
	# 更新 slot 显示
	_update_slot_display(slot, slot_data)

#* InventorySystem 添加物品时的回调
func _on_inventory_item_added(position: Vector2i, slot_data: ItemSlotData) -> void:
	# 数据变更信号已经处理了显示更新，这里可以做一些额外处理
	pass

#* InventorySystem 移除物品时的回调
func _on_inventory_item_removed(position: Vector2i) -> void:
	# 需要找到对应的slot（可能在不同区域）
	var slot = null
	for pos_key in position_to_slot:
		var s = position_to_slot[pos_key]
		if s.grid_position == position:
			slot = s
			break
	
	if slot:
		# 清空显示（传入空的 ItemSlotData）
		var empty_slot = ItemSlotData.create(position, 0, Vector2i(1, 1), "")
		_update_slot_display(slot, empty_slot)

#* InventorySystem 移动物品时的回调
func _on_inventory_item_moved(old_position: Vector2i, new_position: Vector2i, slot_data: ItemSlotData) -> void:
	# 数据变更信号已经处理了显示更新
	pass

#* 更新 Slot 的显示
func _update_slot_display(slot: DraggableSlot, slot_data: ItemSlotData) -> void:
	if slot == null:
		return
	
	if slot_data == null or slot_data.is_empty():
		# 空槽：显示尺寸
		var eff = slot.get_effective_size()
		slot.set_label_text("%dx%d" % [eff.x, eff.y])
	else:
		# 有物品：显示物品ID
		var item_key = slot_data.item_key
		if item_key != "":
			slot.set_label_text(item_key)
		else:
			# 如果没有 item_key，显示尺寸
			var eff = slot.get_effective_size()
			slot.set_label_text("%dx%d" % [eff.x, eff.y])

#* 从 InventorySystem 同步数据（初始化时调用）
func _sync_from_inventory() -> void:
	if inventory_system == null:
		return
	
	# 遍历所有 slot，更新显示
	for pos_key in position_to_slot:
		var slot = position_to_slot[pos_key]
		if slot:
			var region_id = _get_slot_region_id(slot)
			if region_id != "":
				var slot_data = inventory_system.get_item(slot.grid_position, region_id)
				if slot_data:
					_update_slot_display(slot, slot_data)

#* 添加物品（外部接口，用于添加带 item_key 的物品）
#* @param item_key 物品ID
#* @param slot_size 槽位大小
#* @param slot_position 位置（可选，-1 表示自动寻找）
#* @param slot_color 颜色（可选）
func add_item(item_key: String, slot_size: Vector2i = Vector2i(1, 1), slot_position: Vector2i = Vector2i(-1, -1), slot_color: Color = Color(0.3, 0.5, 0.8, 0.8)) -> DraggableSlot:
	# 如果指定了位置，先设置待添加的 item_key
	if slot_position != Vector2i(-1, -1):
		var pos_key = _position_to_key(slot_position)
		_pending_item_keys[pos_key] = item_key
	
	# 添加 slot（会触发 _on_slot_added）
	var slot = add_slot(slot_size, slot_position, slot_color)
	
	if slot == null:
		# 如果添加失败，清理待添加的 item_key
		if slot_position != Vector2i(-1, -1):
			var pos_key = _position_to_key(slot_position)
			_pending_item_keys.erase(pos_key)
		return null
	
	# 如果是自动寻找位置，_on_slot_added 已经处理了
	# 但我们需要确保 item_key 被正确设置（因为信号可能先于 _pending_item_keys 设置）
	if inventory_system != null and slot:
		var region_id = _get_slot_region_id(slot)
		if region_id != "":
			var slot_data = inventory_system.get_item(slot.grid_position, region_id)
			if slot_data and slot_data.item_key != item_key:
				# 更新 item_key（可能是通过 add_slot 直接添加的空槽）
				slot_data.item_key = item_key
				# 触发 Dictionary 更新打印
				inventory_system._print_slots_dict("add_item 更新 item_key 后")
				_update_slot_display(slot, slot_data)
	
	return slot

#* 将位置转换为字典 key
func _position_to_key(position: Vector2i) -> String:
	return "%d,%d" % [position.x, position.y]

#* 将字典 key 转换为位置
func _key_to_position(key: String) -> Vector2i:
	var parts = key.split(",")
	if parts.size() == 2:
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)

#* 获取slot所在的region_id
func _get_slot_region_id(slot: DraggableSlot) -> String:
	if grid_system == null or slot == null:
		return ""
	var grid_pos = _vec2i_to_grid_pos(slot.grid_position)
	var region_id = grid_system.get_cell_region_id(grid_pos)
	if "&" in region_id:
		region_id = region_id.split("&")[0]
	return region_id
