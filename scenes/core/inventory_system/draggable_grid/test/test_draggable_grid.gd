#* 可拖拽表格测试脚本
#* 用于测试DraggableGrid和DraggableSlot的功能
extends Control

#* 可拖拽网格对象（包含多个区域视图）
@onready var draggable_grid: DraggableGrid = $VBoxContainer/HBoxContainer/DraggableGrid

#* 添加槽位按钮
@onready var add_slot_button: Button = $VBoxContainer/ButtonContainer/AddSlotButton

#* 清空所有槽位按钮
@onready var clear_button: Button = $VBoxContainer/ButtonContainer/ClearButton

#* 信息显示标签
@onready var info_label: Label = $VBoxContainer/InfoLabel

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
	# 连接按钮信号
	if add_slot_button:
		add_slot_button.pressed.connect(_on_add_slot_button_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_button_pressed)
	# 连接网格信号
	if draggable_grid:
		draggable_grid.slot_added.connect(_on_slot_added)
		draggable_grid.slot_moved.connect(_on_slot_moved)
		draggable_grid.slot_removed.connect(_on_slot_removed)
		# 初始化区域（如果还没有区域）
		if draggable_grid.grid_system == null or draggable_grid.grid_system.regions.size() == 0:
			# 添加两个区域视图（共享同一个GridSystem）
			# 区域1：左侧
			draggable_grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 6, "region_left"))
			# 区域2：右侧（与区域1相邻）
			draggable_grid.add_region(GridRegion.new(GridPos.new(6, 0), 5, 6, "region_right"))
	
	# 更新初始信息
	update_info()

#* 处理添加槽位按钮点击事件
func _on_add_slot_button_pressed() -> void:
	if not draggable_grid:
		return
	
	# 随机大小（1x1 到 3x3）
	var slot_size = Vector2i(randi_range(1, 3), randi_range(1, 3))
	
	# 随机颜色
	var slot_color = slot_colors[randi() % slot_colors.size()]
	
	# 添加槽位
	var new_slot = draggable_grid.add_slot(slot_size, Vector2i(-1, -1), slot_color)
	if new_slot:
		new_slot.set_label_text("%dx%d" % [slot_size.x, slot_size.y])
		update_info()

#* 处理清空按钮点击事件
func _on_clear_button_pressed() -> void:
	if draggable_grid:
		draggable_grid.clear_all_slots()
		update_info()

#* 处理槽位添加事件
#* @param added_slot 被添加的槽位对象
#* @param slot_position 槽位位置（格子坐标）
#* @param region_id 区域标识
func _on_slot_added(added_slot: DraggableSlot, slot_position: Vector2i, region_id: String) -> void:
	update_info()
	print("槽位已添加: 位置 ", slot_position, " 大小 ", added_slot.slot_size, " 区域: ", region_id)

#* 处理槽位移动事件
#* @param moved_slot 被移动的槽位对象
#* @param old_slot_position 移动前的位置（格子坐标）
#* @param new_slot_position 移动后的位置（格子坐标）
#* @param old_region_id 旧区域标识
#* @param new_region_id 新区域标识
func _on_slot_moved(moved_slot: DraggableSlot, old_slot_position: Vector2i, new_slot_position: Vector2i, old_region_id: String, new_region_id: String) -> void:
	update_info()
	print("槽位已移动: ", old_slot_position, " -> ", new_slot_position, " 区域: ", old_region_id, " -> ", new_region_id)

#* 处理槽位移除事件
#* @param removed_slot 被移除的槽位对象
func _on_slot_removed(removed_slot: DraggableSlot) -> void:
	update_info()
	print("槽位已移除")

#* 更新信息显示
func update_info() -> void:
	if info_label and draggable_grid:
		var slot_count = draggable_grid.get_slot_count()
		var region_count = 0
		if draggable_grid.grid_system:
			region_count = draggable_grid.grid_system.regions.size()
		info_label.text = "槽位数: %d\n区域数: %d\n操作说明:\n• 左键点击并拖拽槽位移动\n• 可以在两个区域之间拖拽\n• 点击按钮添加新槽位" % [slot_count, region_count]
