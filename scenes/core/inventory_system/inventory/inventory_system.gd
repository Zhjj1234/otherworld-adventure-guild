#* 背包系统 - 数据层
#* 负责管理背包中的所有物品数据
extends Node
class_name InventorySystem

#* 物品数据变更信号
signal slot_data_changed(position: Vector2i, slot_data: ItemSlotData)
signal item_added(position: Vector2i, slot_data: ItemSlotData)
signal item_removed(position: Vector2i)
signal item_moved(old_position: Vector2i, new_position: Vector2i, slot_data: ItemSlotData)

#* 背包大小（格子数，宽x高）
@export var inventory_size: Vector2i = Vector2i(10, 10)

#* Slot 数据字典（按区域分组）
#* 结构：{region_id: {slot_id: ItemSlotData}}
#* 外层key: region_id（区域标识）
#* 内层key: 位置字符串 "x,y" (左上角位置)
#* 内层value: ItemSlotData 物品槽位数据
var slots_by_region: Dictionary = {}

#* 区域到背包类型的映射
#* 结构：{region_id: BasePackData.PACK_TYPE}
var region_pack_type_map: Dictionary = {}

#* 背包逻辑实例缓存
#* 结构：{pack_type: BasePackLogic}
var pack_logic_cache: Dictionary = {}

#* 添加物品到指定位置
#* @param position 左上角位置
#* @param rotation_index 旋转状态 (0-3)
#* @param item_key 物品ID
#* @param slot_size 槽位大小（占几格）
#* @param region_id 区域标识（必需）
func add_item(position: Vector2i, rotation_index: int, item_key: String, slot_size: Vector2i = Vector2i(1, 1), region_id: String = "") -> bool:
	if region_id == "":
		DebugPrint.print_simple("添加物品失败：region_id 不能为空", "inventory_system.gd", Color.YELLOW)
		return false
	
	var pos_key = _position_to_key(position)
	
	# 检查位置是否有效
	if not _is_position_valid(position, slot_size):
		DebugPrint.print_simple("添加物品失败：位置无效 %s" % str(position), "inventory_system.gd", Color.YELLOW)
		return false
	
	# 确保区域字典存在
	if not slots_by_region.has(region_id):
		slots_by_region[region_id] = {}
	
	var region_slots: Dictionary = slots_by_region[region_id]
	
	# 检查是否已被占用
	if region_slots.has(pos_key):
		DebugPrint.print_simple("添加物品失败：位置已被占用 %s" % str(position), "inventory_system.gd", Color.YELLOW)
		return false
	
	# 创建 slot 数据
	var slot_data = ItemSlotData.create(position, rotation_index, slot_size, item_key)
	
	region_slots[pos_key] = slot_data
	_print_slots_dict("添加物品后")
	
	# 发出信号
	item_added.emit(position, slot_data)
	slot_data_changed.emit(position, slot_data)
	
	DebugPrint.print_simple("添加物品成功：位置=%s, item_key=%s, region=%s" % [str(position), item_key, region_id], "inventory_system.gd", Color.YELLOW)
	return true

#* 移除指定位置的物品
#* @param position 左上角位置
#* @param region_id 区域标识（必需）
func remove_item(position: Vector2i, region_id: String = "") -> bool:
	if region_id == "":
		DebugPrint.print_simple("移除物品失败：region_id 不能为空", "inventory_system.gd", Color.YELLOW)
		return false
	
	var pos_key = _position_to_key(position)
	
	if not slots_by_region.has(region_id):
		DebugPrint.print_simple("移除物品失败：区域不存在 %s" % region_id, "inventory_system.gd", Color.YELLOW)
		return false
	
	var region_slots: Dictionary = slots_by_region[region_id]
	if not region_slots.has(pos_key):
		DebugPrint.print_simple("移除物品失败：位置不存在 %s" % str(position), "inventory_system.gd", Color.YELLOW)
		return false
	
	var old_slot_data = region_slots[pos_key]
	region_slots.erase(pos_key)
	_print_slots_dict("移除物品后")
	
	item_removed.emit(position)
	# 发送空的 ItemSlotData 表示清空
	var empty_slot = ItemSlotData.create(position, 0, Vector2i(1, 1), "")
	slot_data_changed.emit(position, empty_slot)
	
	DebugPrint.print_simple("移除物品成功：位置=%s, region=%s" % [str(position), region_id], "inventory_system.gd", Color.YELLOW)
	return true

#* 注册区域的背包类型
#* @param region_id 区域标识
#* @param pack_type 背包类型
func register_region_pack_type(region_id: String, pack_type: BasePackData.PACK_TYPE) -> void:
	region_pack_type_map[region_id] = pack_type
	DebugPrint.print_simple("注册区域背包类型: %s -> %s" % [region_id, BasePackData.PACK_TYPE.keys()[pack_type]], "inventory_system.gd", Color.YELLOW)

#* 获取区域的背包类型
#* @param region_id 区域标识
#* @return 背包类型，未注册返回默认类型
func get_region_pack_type(region_id: String) -> BasePackData.PACK_TYPE:
	if region_pack_type_map.has(region_id):
		return region_pack_type_map[region_id]
	return BasePackData.PACK_TYPE.PACK

#* 获取或创建背包逻辑实例（虚拟方法，子类可重写）
#* @param pack_type 背包类型
#* @return 背包逻辑实例
func _get_pack_logic(pack_type: BasePackData.PACK_TYPE) -> BasePackLogic:
	return BasePackLogic.new()

#* 验证物品移动是否允许（跨背包类型时调用 Logic 验证）
#* @param old_region_id 原区域标识
#* @param new_region_id 新区域标识
#* @param old_slot_data 原物品槽数据
#* @param old_position 原位置
#* @param new_position 新位置
#* @return ValidationResult 验证结果
func validate_move_item(old_region_id: String, new_region_id: String, old_slot_data: ItemSlotData, old_position: Vector2i, new_position: Vector2i) -> ValidationResult:
	var old_pack_type = get_region_pack_type(old_region_id)
	var new_pack_type = get_region_pack_type(new_region_id)
	
	# 同一背包类型，直接通过
	if old_pack_type == new_pack_type:
		return ValidationResult.ok()
	
	# 获取源背包逻辑，验证移出
	var old_logic = _get_pack_logic(old_pack_type)
	var out_result = old_logic.validate_out(old_slot_data, old_position, new_pack_type)
	if not out_result.success:
		return ValidationResult.fail("移出验证失败: %s" % out_result.error_message)
	
	# 获取目标背包逻辑，验证移入
	var new_logic = _get_pack_logic(new_pack_type)
	var in_result = new_logic.validate_in(old_slot_data, new_position, old_pack_type)
	if not in_result.success:
		return ValidationResult.fail("移入验证失败: %s" % in_result.error_message)
	
	# 合并额外数据
	var extra_data = {}
	extra_data.merge(out_result.extra_data)
	extra_data.merge(in_result.extra_data)
	
	return ValidationResult.ok(extra_data)

#* 移动物品
#* @param old_position 原位置
#* @param new_position 新位置
#* @param new_rotation 新旋转状态
#* @param old_region_id 原区域标识（必需）
#* @param new_region_id 新区域标识（可选，默认同原区域）
func move_item(old_position: Vector2i, new_position: Vector2i, new_rotation: int = -1, old_region_id: String = "", new_region_id: String = "") -> bool:
	if old_region_id == "":
		DebugPrint.print_simple("移动物品失败：old_region_id 不能为空", "inventory_system.gd", Color.YELLOW)
		return false
	
	if new_region_id == "":
		new_region_id = old_region_id
	
	var old_key = _position_to_key(old_position)
	
	if not slots_by_region.has(old_region_id):
		DebugPrint.print_simple("移动物品失败：原区域不存在 %s" % old_region_id, "inventory_system.gd", Color.YELLOW)
		return false
	
	var old_region_slots: Dictionary = slots_by_region[old_region_id]
	if not old_region_slots.has(old_key):
		DebugPrint.print_simple("移动物品失败：原位置不存在 %s" % str(old_position), "inventory_system.gd", Color.YELLOW)
		return false
	
	var old_slot_data: ItemSlotData = old_region_slots[old_key]
	var slot_size = old_slot_data.slot_size
	
	# 验证物品移动是否允许（跨背包、商店等逻辑）
	var validation_result = validate_move_item(old_region_id, new_region_id, old_slot_data, old_position, new_position)
	if not validation_result.success:
		DebugPrint.print_simple("移动物品失败：%s" % validation_result.error_message, "inventory_system.gd", Color.YELLOW)
		return false
	
	# 检查新位置是否有效
	if not _is_position_valid(new_position, slot_size):
		DebugPrint.print_simple("移动物品失败：新位置无效 %s" % str(new_position), "inventory_system.gd", Color.YELLOW)
		return false
	
	# 确保新区域字典存在
	if not slots_by_region.has(new_region_id):
		slots_by_region[new_region_id] = {}
	
	var new_region_slots: Dictionary = slots_by_region[new_region_id]
	
	# 检查新位置是否已被占用（排除自己）
	var new_key = _position_to_key(new_position)
	if new_region_slots.has(new_key) and (new_position != old_position or new_region_id != old_region_id):
		DebugPrint.print_simple("移动物品失败：新位置已被占用 %s" % str(new_position), "inventory_system.gd", Color.YELLOW)
		return false
	
	# 创建新的 slot 数据
	var rotation = new_rotation if new_rotation >= 0 else old_slot_data.rotation_index
	var new_slot_data = ItemSlotData.create(new_position, rotation, slot_size, old_slot_data.item_key)
	
	# 更新数据
	old_region_slots.erase(old_key)
	new_region_slots[new_key] = new_slot_data
	_print_slots_dict("移动物品后")
	
	# 发出信号
	item_moved.emit(old_position, new_position, new_slot_data)
	# 旧位置清空
	var empty_slot = ItemSlotData.create(old_position, 0, Vector2i(1, 1), "")
	slot_data_changed.emit(old_position, empty_slot)
	# 新位置更新
	slot_data_changed.emit(new_position, new_slot_data)
	
	DebugPrint.print_simple("移动物品成功：%s -> %s (region: %s -> %s)" % [str(old_position), str(new_position), old_region_id, new_region_id], "inventory_system.gd", Color.YELLOW)
	return true

#* 获取指定位置的物品数据
#* @param position 位置
#* @param region_id 区域标识（必需）
#* @return ItemSlotData 或 null
func get_item(position: Vector2i, region_id: String = "") -> ItemSlotData:
	if region_id == "":
		return null
	
	var pos_key = _position_to_key(position)
	if slots_by_region.has(region_id):
		var region_slots: Dictionary = slots_by_region[region_id]
		if region_slots.has(pos_key):
			return region_slots[pos_key]
	return null

#* 检查位置是否有效（在背包范围内）
func _is_position_valid(position: Vector2i, slot_size: Vector2i) -> bool:
	if position.x < 0 or position.y < 0:
		return false
	if position.x + slot_size.x > inventory_size.x:
		return false
	if position.y + slot_size.y > inventory_size.y:
		return false
	return true

#* 将位置转换为字典 key
func _position_to_key(position: Vector2i) -> String:
	return "%d,%d" % [position.x, position.y]

#* 清空所有物品
func clear_all() -> void:
	slots_by_region.clear()
	_print_slots_dict("清空所有物品后")
	DebugPrint.print_simple("清空所有物品", "inventory_system.gd", Color.YELLOW)

#* 清空指定区域的所有物品
func clear_region(region_id: String) -> void:
	if slots_by_region.has(region_id):
		slots_by_region[region_id].clear()
		_print_slots_dict("清空区域后: " + region_id)
		DebugPrint.print_simple("清空区域: %s" % region_id, "inventory_system.gd", Color.YELLOW)

#* 打印 slots Dictionary 的状态（调试用）
func _print_slots_dict(operation: String) -> void:
	var total_count = 0
	for region_id in slots_by_region:
		total_count += slots_by_region[region_id].size()
	DebugPrint.print_simple("【Dictionary更新】%s 总slots数量=%d" % [operation, total_count], "inventory_system.gd")
	for region_id in slots_by_region:
		var region_slots: Dictionary = slots_by_region[region_id]
		if region_slots.size() > 0:
			DebugPrint.print_simple("  [区域 %s] slots数量=%d" % [region_id, region_slots.size()], "inventory_system.gd")
			for pos_key in region_slots:
				var slot_data: ItemSlotData = region_slots[pos_key]
				DebugPrint.print_simple("    [%s] position=%s rotation=%d size=%s item_key='%s'" % [
					pos_key,
					str(slot_data.position),
					slot_data.rotation_index,
					str(slot_data.slot_size),
					slot_data.item_key
				], "inventory_system.gd")
