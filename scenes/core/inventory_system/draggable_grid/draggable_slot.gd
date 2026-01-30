#* 可拖拽的槽控件
#* 可以在表格中拖拽移动
extends Control
class_name DraggableSlot

#* 当槽位被拖拽时发出
#* @param slot 被拖拽的槽位对象
#* @param new_position 新位置（格子坐标）
#* @param click_offset 点击位置相对于槽位左上角的格子偏移
signal slot_dragged(slot: DraggableSlot, new_position: Vector2i, click_offset: Vector2i)

#* 当槽位被点击时发出
#* @param slot 被点击的槽位对象
signal slot_clicked(slot: DraggableSlot)

#* 槽在表格中的位置（格子坐标）
var grid_position: Vector2i = Vector2i(0, 0)

#* 槽的原始大小（占几格，宽x高），不随旋转改变
var slot_size: Vector2i = Vector2i(1, 1)

#* 旋转状态：0=0°，1=90°，2=180°，3=270°（顺时针）
var rotation_index: int = 0

#* 是否正在拖拽
var is_dragging: bool = false

#* 拖拽偏移（鼠标点击位置相对于槽位左上角的像素偏移）
var drag_offset: Vector2 = Vector2.ZERO

#* 点击位置相对于槽位左上角的格子偏移
var click_grid_offset: Vector2i = Vector2i(0, 0)

#* 背景颜色
var slot_color: Color = Color(0.3, 0.5, 0.8, 0.8)

#* 背景
var background: ColorRect = null

#* 标签（显示内容）
var label: Label = null

#* 初始化槽位
func _ready() -> void:
	# 创建背景
	background = ColorRect.new()
	background.name = "Background"
	background.color = slot_color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	
	# 创建标签
	label = Label.new()
	label.name = "Label"
	label.text = "%dx%d" % [slot_size.x, slot_size.y]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE	
	
	# 设置鼠标事件
	mouse_filter = Control.MOUSE_FILTER_PASS
	gui_input.connect(_on_gui_input)

#* 处理鼠标输入事件
#* @param input_event 输入事件
func _on_gui_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton:
		if input_event.button_index == MOUSE_BUTTON_LEFT:
			if input_event.pressed:
				# 开始拖拽
				is_dragging = true
				drag_offset = input_event.position
				
				# 计算点击位置相对于槽位的格子偏移量（按当前有效尺寸）
				var grid = get_parent().get_parent()
				if grid is DraggableGrid:
					var cell_total_size = grid.cell_size + grid.cell_spacing
					var eff = get_effective_size()
					click_grid_offset.x = int(input_event.position.x / cell_total_size)
					click_grid_offset.y = int(input_event.position.y / cell_total_size)
					click_grid_offset.x = clamp(click_grid_offset.x, 0, eff.x - 1)
					click_grid_offset.y = clamp(click_grid_offset.y, 0, eff.y - 1)
				
				slot_clicked.emit(self)
				# 提升到最上层
				get_parent().move_child(self, get_parent().get_child_count() - 1)
			else:
				# 结束拖拽
				if is_dragging:
					is_dragging = false
					# 通知父节点更新位置，传递点击偏移量
					slot_dragged.emit(self, grid_position, click_grid_offset)
	
	elif input_event is InputEventMouseMotion and is_dragging:
		# 拖拽中，实时更新位置
		var new_global_pos = get_global_mouse_position() - drag_offset
		global_position = new_global_pos

#* 获取旋转后的占位大小（用于放置/碰撞判断）
#* 0°/180° 为 slot_size，90°/270° 为 (height, width)
func get_effective_size() -> Vector2i:
	if rotation_index % 2 == 0:
		return slot_size
	return Vector2i(slot_size.y, slot_size.x)

#* 顺时针旋转 90°
func rotate_clockwise_90() -> void:
	rotation_index = (rotation_index + 1) % 4
	_update_rotation_label()

func _update_rotation_label() -> void:
	if label:
		var eff = get_effective_size()
		label.text = "%dx%d" % [eff.x, eff.y]

#* 设置槽位大小
#* @param new_size 新大小（宽x高，占几格）
func set_slot_size(new_size: Vector2i) -> void:
	slot_size = new_size
	_update_rotation_label()

#* 设置槽位颜色
#* @param new_color 新颜色
func set_slot_color(new_color: Color) -> void:
	slot_color = new_color
	if background:
		background.color = new_color

#* 设置标签文本
#* @param new_text 新文本
func set_label_text(new_text: String) -> void:
	if label:
		label.text = new_text
