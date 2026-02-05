#* 支持手柄/键盘导航的拖拽槽控件
extends DraggableSlot
class_name ControllerDraggableSlot

#* 是否获得焦点（手柄/键盘选择）
var is_focused: bool = false:
	set(value):
		is_focused = value
		_update_focus_visual()

#* 是否正在被抓取移动
var is_moving: bool = false:
	set(value):
		is_moving = value
		_update_focus_visual()

#* 焦点边框
var focus_border: ReferenceRect = null

func _ready() -> void:
	super._ready()
	
	# 创建焦点边框
	focus_border = ReferenceRect.new()
	focus_border.name = "FocusBorder"
	focus_border.border_color = Color.WHITE
	focus_border.border_width = 3.0
	focus_border.editor_only = false
	focus_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_border.hide()
	add_child(focus_border)
	focus_border.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _update_focus_visual() -> void:
	if focus_border:
		focus_border.visible = is_focused
		if is_moving:
			# 移动时：偏灰色的白（没那么亮）
			focus_border.border_color = Color(0.6, 0.6, 0.6, 1.0)
		else:
			# 正常选中时：亮白色
			focus_border.border_color = Color.WHITE
