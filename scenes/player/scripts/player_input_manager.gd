#* InputManager.gd（AutoLoad全局节点，命名为InputManager）
extends Node2D

#* 定义核心信号：对接外部逻辑
signal grid_clicked(grid_pos: Vector2i) # * 鼠标点击某格子

#* 2. 检测鼠标左键点击
func handle_ui_input(event: InputEvent) -> void:
	#* 3. 检测鼠标左键点击（仅按下时触发，避免重复）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world_pos = get_global_mouse_position()
		var click_grid = GridManager.world_to_grid(mouse_world_pos)
		emit_signal("grid_clicked", click_grid) # * 发送点击信号

#* 更新格子高亮提示的位置和显示状态
func update_grid_highlight(_grid_pos: Vector2i) -> void:
	return Vector2i(0, 0)

#* 可选：隐藏高亮（比如鼠标移出网格）
func hide_grid_highlight() -> void:
	return
