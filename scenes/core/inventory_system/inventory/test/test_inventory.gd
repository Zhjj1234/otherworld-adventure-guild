#* 背包系统测试脚本
#* 用于测试 InventorySystem 和 InventoryGrid 的功能
extends Control

#* 背包网格（前端显示）
@onready var inventory_grid: InventoryGrid = $VBoxContainer/HBoxContainer/InventoryGrid

#* 添加物品按钮
@onready var add_item_button: Button = $VBoxContainer/ButtonContainer/AddItemButton

#* 移除物品按钮
@onready var remove_item_button: Button = $VBoxContainer/ButtonContainer/RemoveItemButton

#* 清空所有按钮
@onready var clear_button: Button = $VBoxContainer/ButtonContainer/ClearButton

#* 4个背包View的显示/隐藏按钮
@onready var toggle_backpack1_button: Button = $VBoxContainer/ViewToggleContainer/ToggleBackpack1
@onready var toggle_backpack2_button: Button = $VBoxContainer/ViewToggleContainer/ToggleBackpack2
@onready var toggle_backpack3_button: Button = $VBoxContainer/ViewToggleContainer/ToggleBackpack3
@onready var toggle_backpack4_button: Button = $VBoxContainer/ViewToggleContainer/ToggleBackpack4

#* 信息显示标签
@onready var info_label: Label = $VBoxContainer/InfoLabel

#* 4个背包的region_id
var backpack_region_ids: Array[String] = ["shop_pack", "character_pack", "backpack_3", "backpack_4"]

var pack_config: PackConfig = null

#* 背包系统（数据层）
var inventory_system: InventorySystem = null

#* 测试物品ID列表
var test_item_keys: Array[String] = [
	"shop_pack",
	"character_pack",
	"shield_wood",
	"key_gold",
	"gem_blue"
]

#* 槽位颜色列表
var slot_colors: Array[Color] = [
	Color(0.3, 0.5, 0.8, 0.8),  # 蓝色
	Color(0.8, 0.3, 0.3, 0.8),  # 红色
	Color(0.3, 0.8, 0.3, 0.8),  # 绿色
	Color(0.8, 0.8, 0.3, 0.8),  # 黄色
	Color(0.8, 0.3, 0.8, 0.8),  # 紫色
]

#* 初始化测试脚本
func _ready() -> void:
	pack_config = preload("res://scenes/core/inventory_system/inventory/pack/custom/tres/pack_config.tres")
	# 创建背包系统
	inventory_system = GameInventorySystem.new()
	for region_id: String in pack_config.base_pack_data_list:
		inventory_system.register_region_pack_type(region_id, pack_config.base_pack_data_list[region_id].pack_type)
	inventory_system.inventory_size = Vector2i(10, 8)
	
	# 连接背包系统信号
	inventory_system.item_added.connect(_on_inventory_item_added)
	inventory_system.item_removed.connect(_on_inventory_item_removed)
	inventory_system.item_moved.connect(_on_inventory_item_moved)
	inventory_system.slot_data_changed.connect(_on_inventory_slot_data_changed)
	
	# 设置背包网格
	if inventory_grid:
		inventory_grid.set_inventory_system(inventory_system)
		# 初始化4个背包区域（每个5x6格）
		if inventory_grid.grid_system == null or inventory_grid.grid_system.regions.size() == 0:
			var backpack_size = Vector2i(5, 3)
			var backpack_width = backpack_size.x
			var backpack_height = backpack_size.y
			# 背包1：左上 - 逻辑坐标(0, 0)
			inventory_grid.add_region(GridRegion.new(GridPos.new(0, 0), backpack_width, backpack_height, backpack_region_ids[0]))
			inventory_grid.set_region_base_point(backpack_region_ids[0], Vector2(10, 10))
			# 背包2：右上 - 逻辑坐标(5, 0)
			inventory_grid.add_region(GridRegion.new(GridPos.new(backpack_width, 0), backpack_width, backpack_height, backpack_region_ids[1]))
			inventory_grid.set_region_base_point(backpack_region_ids[1], Vector2(320, 10))
			# 背包3：左下 - 逻辑坐标(0, 3)
			inventory_grid.add_region(GridRegion.new(GridPos.new(0, backpack_height), backpack_width, backpack_height, backpack_region_ids[2]))
			inventory_grid.set_region_base_point(backpack_region_ids[2], Vector2(10, 240))
			# 背包4：右下 - 逻辑坐标(5, 3)
			inventory_grid.add_region(GridRegion.new(GridPos.new(backpack_width, backpack_height), backpack_width, backpack_height, backpack_region_ids[3]))
			inventory_grid.set_region_base_point(backpack_region_ids[3], Vector2(320, 240))
		
		# 连接网格信号
		inventory_grid.slot_added.connect(_on_grid_slot_added)
		inventory_grid.slot_moved.connect(_on_grid_slot_moved)
	
	# 连接按钮信号
	if add_item_button:
		add_item_button.pressed.connect(_on_add_item_button_pressed)
	if remove_item_button:
		remove_item_button.pressed.connect(_on_remove_item_button_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)
	
	# 连接View切换按钮
	if toggle_backpack1_button:
		toggle_backpack1_button.toggled.connect(_on_toggle_backpack1)
		toggle_backpack1_button.button_pressed = true
	if toggle_backpack2_button:
		toggle_backpack2_button.toggled.connect(_on_toggle_backpack2)
		toggle_backpack2_button.button_pressed = true
	if toggle_backpack3_button:
		toggle_backpack3_button.toggled.connect(_on_toggle_backpack3)
		toggle_backpack3_button.button_pressed = true
	if toggle_backpack4_button:
		toggle_backpack4_button.toggled.connect(_on_toggle_backpack4)
		toggle_backpack4_button.button_pressed = true
	
	# 更新初始信息
	update_info()

#* 处理添加物品按钮点击事件
func _on_add_item_button_pressed() -> void:
	if not inventory_grid or not inventory_system:
		return
	
	# 随机选择物品ID
	var item_key = test_item_keys[randi() % test_item_keys.size()]
	
	# 随机大小（1x1 到 3x2）
	var slot_size = Vector2i(randi_range(1, 3), randi_range(1, 2))
	
	# 随机颜色
	var slot_color = slot_colors[randi() % slot_colors.size()]
	
	# 添加物品（会自动寻找位置）
	var new_slot = inventory_grid.add_item(item_key, slot_size, Vector2i(-1, -1), slot_color)
	if new_slot:
		DebugPrint.print_simple("添加物品成功: %s 大小: %s" % [item_key, str(slot_size)], "test_inventory.gd", Color.YELLOW)
		update_info()
	else:
		DebugPrint.print_simple("添加物品失败：背包已满", "test_inventory.gd", Color.YELLOW)

#* 处理移除物品按钮点击事件
func _on_remove_item_button_pressed() -> void:
	if not inventory_grid or not inventory_system:
		return
	
	# 获取所有槽位
	if not inventory_grid.slot_container:
		DebugPrint.print_simple("slot_container 未初始化", "test_inventory.gd", Color.YELLOW)
		return
	
	var slots = inventory_grid.slot_container.get_children()
	if slots.size() == 0:
		DebugPrint.print_simple("没有可移除的物品", "test_inventory.gd", Color.YELLOW)
		return
	
	# 随机移除一个
	var slot_to_remove = slots[randi() % slots.size()]
	if slot_to_remove is DraggableSlot:
		var slot: DraggableSlot = slot_to_remove
		inventory_grid.remove_slot(slot)
		DebugPrint.print_simple("移除物品: 位置 %s" % str(slot.grid_position), "test_inventory.gd", Color.YELLOW)
		update_info()

#* 处理清空按钮点击事件
func _on_clear_button_pressed() -> void:
	if inventory_grid:
		inventory_grid.clear_all_slots()
		update_info()
		DebugPrint.print_simple("清空所有物品", "test_inventory.gd", Color.YELLOW)

#* 处理网格槽位添加事件
func _on_grid_slot_added(added_slot: DraggableSlot, slot_position: Vector2i, region_id: String) -> void:
	update_info()
	DebugPrint.print_simple("网格槽位已添加: 位置 %s 区域: %s" % [str(slot_position), region_id], "test_inventory.gd", Color.YELLOW)

#* 处理网格槽位移动事件
func _on_grid_slot_moved(moved_slot: DraggableSlot, old_position: Vector2i, new_position: Vector2i, old_region_id: String, new_region_id: String) -> void:
	update_info()
	DebugPrint.print_simple("网格槽位已移动: %s -> %s" % [str(old_position), str(new_position)], "test_inventory.gd", Color.YELLOW)

#* 处理背包系统物品添加事件
func _on_inventory_item_added(position: Vector2i, slot_data: ItemSlotData) -> void:
	DebugPrint.print_simple("背包系统：物品已添加 位置=%s item_key=%s" % [str(position), slot_data.item_key], "test_inventory.gd", Color.YELLOW)
	update_info()

#* 处理背包系统物品移除事件
func _on_inventory_item_removed(position: Vector2i) -> void:
	DebugPrint.print_simple("背包系统：物品已移除 位置=%s" % str(position), "test_inventory.gd", Color.YELLOW)
	update_info()

#* 处理背包系统物品移动事件
func _on_inventory_item_moved(old_position: Vector2i, new_position: Vector2i, slot_data: ItemSlotData) -> void:
	DebugPrint.print_simple("背包系统：物品已移动 %s -> %s item_key=%s" % [str(old_position), str(new_position), slot_data.item_key], "test_inventory.gd", Color.YELLOW)
	update_info()

#* 处理背包系统数据变更事件
func _on_inventory_slot_data_changed(position: Vector2i, slot_data: ItemSlotData) -> void:
	# 这个信号主要用于更新显示，已经在 InventoryGrid 中处理了
	pass

#* 切换背包1的显示
func _on_toggle_backpack1(toggled: bool) -> void:
	_toggle_region_view(backpack_region_ids[0], toggled)

#* 切换背包2的显示
func _on_toggle_backpack2(toggled: bool) -> void:
	_toggle_region_view(backpack_region_ids[1], toggled)

#* 切换背包3的显示
func _on_toggle_backpack3(toggled: bool) -> void:
	_toggle_region_view(backpack_region_ids[2], toggled)

#* 切换背包4的显示
func _on_toggle_backpack4(toggled: bool) -> void:
	_toggle_region_view(backpack_region_ids[3], toggled)

#* 切换区域View的显示
func _toggle_region_view(region_id: String, visible: bool) -> void:
	if inventory_grid and inventory_grid.region_views.has(region_id):
		inventory_grid.region_views[region_id].visible = visible

#* 更新信息显示
func update_info() -> void:
	if not info_label or not inventory_system:
		return
	
	var total_slot_count = 0
	var total_item_count = 0
	for region_id in inventory_system.slots_by_region:
		var region_slots: Dictionary = inventory_system.slots_by_region[region_id]
		total_slot_count += region_slots.size()
		for pos_key in region_slots:
			var slot_data: ItemSlotData = region_slots[pos_key]
			if not slot_data.is_empty():
				total_item_count += 1
	
	var info_text = "背包信息:\n"
	info_text += "• 背包数量: 4\n"
	info_text += "• 每个背包大小: 5x6\n"
	info_text += "• 槽位总数: %d\n" % total_slot_count
	info_text += "• 物品数量: %d\n" % total_item_count
	info_text += "\n操作说明:\n"
	info_text += "• 左键点击并拖拽物品移动\n"
	info_text += "• 右键旋转物品\n"
	info_text += "• 点击'添加物品'按钮添加新物品\n"
	info_text += "• 点击'移除物品'按钮随机移除一个物品\n"
	info_text += "• 使用4个按钮切换背包显示/隐藏\n"
	info_text += "• 物品显示为物品ID（如 sword_001）\n"
	info_text += "\n物品列表:\n"
	
	# 显示所有物品（按区域分组）
	for region_id in inventory_system.slots_by_region:
		var region_slots: Dictionary = inventory_system.slots_by_region[region_id]
		if region_slots.size() > 0:
			info_text += "\n[%s]:\n" % region_id
			for pos_key in region_slots:
				var slot_data: ItemSlotData = region_slots[pos_key]
				if not slot_data.is_empty():
					info_text += "  %s @ %s\n" % [slot_data.item_key, str(slot_data.position)]
	
	info_label.text = info_text
