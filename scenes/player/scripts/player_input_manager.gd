#* InputManager.gd（AutoLoad全局节点，命名为InputManager）
extends Node2D
class_name PlayerInputManager

#* 定义核心信号：对接外部逻辑
signal grid_clicked(grid_pos: Vector2i) # * 鼠标点击某格子
signal grid_moved(grid_pos: Vector2i) # * 鼠标移动到某格子

var _last_grid_pos: Vector2i = Vector2i(-1, -1)

#* 2. 检测鼠标左键点击
func handle_ui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var mouse_world_pos = get_global_mouse_position()
		var click_grid = GridManager.world_to_grid(mouse_world_pos)
		if click_grid != _last_grid_pos:
			if event is InputEventMouseMotion:
				grid_moved.emit(click_grid)
		#* 3. 检测鼠标左键点击（仅按下时触发，避免重复）
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			grid_clicked.emit(click_grid) # * 发送点击信号
		_last_grid_pos = click_grid

#* 更新格子高亮提示的位置和显示状态
func update_grid_highlight(_grid_pos: Vector2i) -> void:
	return Vector2i(0, 0)

#* 可选：隐藏高亮（比如鼠标移出网格）
func hide_grid_highlight() -> void:
	return
