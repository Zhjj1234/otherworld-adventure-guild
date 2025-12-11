#* InputManager.gd（AutoLoad全局节点，命名为InputManager）
extends Node2D

#* 定义核心信号：对接外部逻辑
signal grid_hovered(grid_pos: Vector2i) # * 鼠标悬停到某格子
signal grid_clicked(grid_pos: Vector2i) # * 鼠标点击某格子

#* 缓存当前悬停的格子（避免重复触发信号）
var current_hover_grid: Vector2i = Vector2i(-1, -1)

#* 1. 检测鼠标位置变化
func _process(_delta: float) -> void:
	#* 1. 实时检测鼠标位置，转换为格子坐标
	var mouse_world_pos = get_global_mouse_position() # * 获取鼠标世界坐标
	var current_grid = GridManager.world_to_grid(mouse_world_pos) # * 转格子行列

	#* 2. 仅当格子变化时，触发悬停信号+更新高亮
	if current_grid != current_hover_grid:
		current_hover_grid = current_grid
		emit_signal("grid_hovered", current_grid) # * 发送悬停信号
		#*print(current_grid)
		update_grid_highlight(current_grid) # * 更新高亮位置

#* 2. 检测鼠标左键点击
func _input(event: InputEvent) -> void:
	#* 3. 检测鼠标左键点击（仅按下时触发，避免重复）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_world_pos = get_global_mouse_position()
		var click_grid = GridManager.world_to_grid(mouse_world_pos)
		emit_signal("grid_clicked", click_grid) # * 发送点击信号

#* 更新格子高亮提示的位置和显示状态
func update_grid_highlight(grid_pos: Vector2i) -> void:
	if grid_pos.x < 0 or grid_pos.y < 0: # * 超出网格范围则隐藏
		#*grid_highlight.visible = false
		return
	
	#* 转换格子坐标到世界中心位置，设置高亮节点位置
	#*var world_center = GridManager.grid_to_world_center(grid_pos)
	#*grid_highlight.global_position = world_center
	#*grid_highlight.visible = true  #* 显示高亮

#* 可选：隐藏高亮（比如鼠标移出网格）
func hide_grid_highlight() -> void:
	#*grid_highlight.visible = false
	current_hover_grid = Vector2i(-1, -1)
