extends CanvasLayer

@onready var debug_terminal_panel: Panel = $Panel
@onready var command_input: LineEdit = %CommandInput
@onready var game_manager: GameManager = get_node("/root/GameManager")  #* 全局节点路径
@onready var ui_input_blocker: UIInputBlocker = $UiInputBlocker

var is_active: bool = false

func _ready():
	#* 初始隐藏终端
	_deactivate_terminal()
	#* 监听输入框回车事件
	command_input.text_submitted.connect(_on_command_submitted)
	apply_gradient_style()

func _input(event: InputEvent):
	#* 按下 Tab 切换终端状态
	if event.is_action_pressed("ui_debug_terminal"):
		is_active = !is_active
		if is_active:
			_activate_terminal()
		else:
			_deactivate_terminal()
		# 只有当终端激活且事件是键盘事件时才拦截输入
		if is_active and (event is InputEventKey or event.is_action_pressed("ui_debug_terminal")):
			get_viewport().set_input_as_handled()

func _activate_terminal():
	debug_terminal_panel.show()
	command_input.grab_focus()
	#* 隐藏鼠标并锁定（可选，根据游戏类型调整）
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	ui_input_blocker.push_to_ui_manager_stack()

func _deactivate_terminal():
	debug_terminal_panel.hide()
	command_input.clear()
	#* 恢复鼠标和输入
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_active = false
	ui_input_blocker.pop_from_ui_manager_stack()

func _on_command_submitted(command: String):
	#* 分割命令和参数（如 "move_to 100 200" → ["move_to", "100", "200"]）
	var parts = command.strip_edges().split(" ", false, 1)
	if parts.size() == 0:
		return
	
	var cmd = parts[0].to_lower()
	var args = []
	if parts.size() > 1:
		args = parts[1].split(" ")
	
	print(cmd, args, game_manager)
	
	#* 调用 GameManager 的命令处理方法
	if game_manager.has_method("execute_debug_command"):
		game_manager.execute_debug_command(cmd, args)
		print("Executed command:", cmd, "with args:", args)
	else:
		# TODO: 这里可以考虑用终端实现
		print("Unknown command:", cmd)
	
	#* 执行后自动隐藏终端（可选）
	_deactivate_terminal()

func apply_gradient_style():
	var stylebox = StyleBoxFlat.new()

	# 设置背景颜色
	stylebox.bg_color = Color.BLACK

	# 设置圆角（可选）
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.corner_radius_bottom_left = 5

	# 使用阴影模拟边缘渐变
	stylebox.shadow_size = 10
	stylebox.shadow_color = Color(0, 0, 0, 0.8)  # 边缘透明度

	# 设置内容边距（让文字不贴边）
	stylebox.content_margin_left = 10
	stylebox.content_margin_top = 10
	stylebox.content_margin_right = 10
	stylebox.content_margin_bottom = 10

	# 应用到 LineEdit
	command_input.add_theme_stylebox_override("normal", stylebox)
	command_input.add_theme_stylebox_override("focus", stylebox)

	# 也可以为焦点状态设置不同的样式
	var focus_style = stylebox.duplicate()
	focus_style.shadow_color = Color(0.3, 0.3, 0.8, 0.6)  # 焦点时蓝色边缘
	command_input.add_theme_stylebox_override("focus", focus_style)
