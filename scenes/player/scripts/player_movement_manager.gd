extends Node2D

class_name PlayerMovementManager
@onready var test: Label = $"../CanvasLayer/Test"

#* 玩家数据变量，存储从游戏数据管理器获取的玩家信息
# TODO 这里需要保存
var _player_data

#* 玩家UI管理器引用，用于更新玩家UI位置
@onready var player_ui_mamager: PlayerUIManager = %PlayerUIManager
@onready var player_core: PlayerCore = %PlayerCore

#* 玩家移动速度常量，单位：格子/秒
const PLAYER_SPEED: float = 1 / 0.2
const MOVE_STEP: int = 30

#* 移动状态枚举
enum MOVE_STATUS {
	MOVING, # * 正在移动
	STOP, # * 停止状态
}
enum INPUT_DIR {
	NONE,
	UP,
	DOWN,
	RIGHT,
	LEFT
}


#* 到达目标位置时发出的信号
#* @param coords: Vector2i - 到达的目标坐标
# signal button_coords_changed(path: Array, passable_path: Array)
signal move_status_changed(status: MOVE_STATUS)
signal player_movement_manager_registered(player_movement_manager: PlayerMovementManager)
#signal reach_end_target

#* 目标位置坐标
var _target_position: Vector2 = Vector2.ZERO
#* 当前位置坐标
var _current_position: Vector2 = Vector2.ZERO
var can_input_new_target: bool = true:
	get:
		return can_input_new_target
	set(value):
		if can_input_new_target != value:
			can_input_new_target = value
			if test != null:
				if can_input_new_target:
					test.text = "YES"
				else:
					test.text = "NO"

#* 移动状态变量
# var _move_status: MOVE_STATUS = MOVE_STATUS.STOP
var input_dir: INPUT_DIR = INPUT_DIR.NONE:
	get:
		return input_dir
	set(value):
		if input_dir != value:
			input_dir = value

var move_status: MOVE_STATUS = MOVE_STATUS.STOP:
	get:
		return move_status
	
	set(status):
		if status != move_status:
			move_status = status
			# if test!= null:
			# 	if move_status == MOVE_STATUS.MOVING:
			# 		test.text = "MOVING"
			# 	else:
			# 		test.text = "STOP"
			# move_status_changed.emit(status)

#*var _is_move_interrupted: bool = false
var _final_position: Vector2i = Vector2i.ZERO

#* 初始化玩家管理器
#* 获取玩家初始数据并设置初始状态
func _ready() -> void:
	player_movement_manager_registered.connect(PlayerManager._on_player_movement_manager_registered)
	
	player_movement_manager_registered.emit(self)

#* 游戏主循环处理函数
#* 每帧更新玩家位置和UI显示
#* @param delta: float - 帧间隔时间
func _process(delta: float) -> void:
	_handle_movement_input()
	_update_position(delta)
	#* 更新玩家UI位置
	player_ui_mamager.set_real_position(_current_position)

func _handle_movement_input():
	if input_dir != INPUT_DIR.NONE and can_input_new_target:# and move_status == MOVE_STATUS.STOP:
		can_input_new_target = false
		if input_dir == INPUT_DIR.UP:
			move_to(_current_position + Vector2(0, -1))
		if input_dir == INPUT_DIR.DOWN:
			move_to(_current_position + Vector2(0, 1))
		if input_dir == INPUT_DIR.RIGHT:
			move_to(_current_position + Vector2(1, 0))
		if input_dir == INPUT_DIR.LEFT:
			move_to(_current_position + Vector2(-1, 0))

#* 更新玩家位置的内部函数
#* 根据移动状态和速度计算当前位置
#* @param delta: float - 帧间隔时间
func _update_position(delta: float):
	if move_status == MOVE_STATUS.MOVING:
		#* 向目标位置移动
		_current_position = _current_position.move_toward(_target_position, PLAYER_SPEED * delta)
		# if _current_position == _target_position:
		if _current_position.is_equal_approx(_target_position):
			#* 到达目标位置，停止移动
			move_status = MOVE_STATUS.STOP
			#* 触发到达目标位置事件
			_on_reach_target()

#* 移动到指定坐标
#* 该函数使用A*寻路算法计算从当前位置到目标位置的路径，并沿着路径逐步移动
#* 如果在移动过程中目标位置发生变化，则会中断当前移动并重新规划路径
#* @param coords: Vector2i - 目标网格坐标
#* @example 
#*   move_to(Vector2i(5, 3))  #* 移动到网格坐标(5,3)
func move_to(coords: Vector2i):
	#* 如果当前正在移动，则等待到达目标后再执行新的移动指令
	#if move_status == MOVE_STATUS.MOVING:
		#await EventBus.reach_target
	#* 使用A*算法寻找从当前位置到目标位置的路径
	#* 参数说明：
	#* - _current_position: 当前位置
	#* - coords: 目标位置
	#* - MOVE_STEP: 最大步长，限制路径搜索的范围
	#* - true: 是否允许对角线移动
	var path = _get_passable_path(_current_position, coords)
	if path.size() == 1:
		_reach_final_target(false)
		return
	DebugPrint.print_simple("📝 总移动路径: {}".format(path), get_script().resource_path, Color.GREEN)
	#* 保存最终目标位置，用于检测路径是否仍然有效
	_final_position = path.back()
	#* 循环处理路径中的每个点，直到到达终点
	#* 路径的第一个元素是当前位置，所以从第二个元素开始处理
	while path.size() > 1:
		#* 检查最终目标位置是否发生变化，如果变化则终止当前移动
		if _final_position != path.back():
			_reach_final_target(false)
			return
		#* 设置移动状态为移动中
		move_status = MOVE_STATUS.MOVING
		#* 设置下一个目标位置为路径中的第二个点
		_target_position = path[1]
		DebugPrint.print_simple("🗺️  移动路径: {0} → {1}".format([_current_position, _target_position]), get_script().resource_path, Color.GREEN)
		#* 等待到达当前目标点的信号
		#await EventBus.reach_target
		var is_interacted = await EventBus.cell_interacted
		if is_interacted:
			#* 如果和格子发生了交互，则中断当前移动
			DebugPrint.print_simple("🛑 已在 {0} 发生了交互，中断移动".format([_current_position]), get_script().resource_path, Color.GREEN)
			#move_status = MOVE_STATUS.STOP
			path.clear()
			#reach_end_target.emit()
			_reach_final_target(true)
			return
		#* 到达目标点后，移除路径中的第一个点，继续处理剩余路径
		path.pop_front()
	_reach_final_target(true)
	
func _reach_final_target(is_moved: bool):
	if is_moved:	
		can_input_new_target = true
		DebugPrint.print_simple("🏁  已到达最终目标: {0} ✅".format([_final_position]), get_script().resource_path, Color.GREEN)
	else:
		can_input_new_target = true
		DebugPrint.print_simple("未成功移动", get_script().resource_path, Color.GREEN)

#* 到达目标位置时的回调函数
func _on_reach_target():
	GameDataManager.set_player_current_position(_current_position)
	DebugPrint.print_simple("已到达: {0} ✅".format([_current_position]), get_script().resource_path, Color.GREEN)
	#* 发出到达目标位置信号
	EventBus.reach_target.emit(_current_position)


#* 玩家输入管理器点击网格的回调函数
func _on_player_input_manager_grid_clicked(grid_pos: Vector2i) -> void:
	if can_input_new_target:
	#if move_status == MOVE_STATUS.MOVING:
		#return
		can_input_new_target = false
		move_to(grid_pos)
		

#* 设置玩家位置
func _set_player_position(coords: Vector2i) -> void:
	GameDataManager.set_player_current_position(Vector2(coords.x, coords.y))
	_current_position = Vector2(coords.x, coords.y)
	_target_position = _current_position
	_final_position = coords
	move_status = MOVE_STATUS.STOP

#* 从游戏数据中获取玩家位置
func get_player_position_from_game_data() -> Vector2:
	return Vector2(_player_data["current_position"]["x"], _player_data["current_position"]["y"])

#* 从游戏数据中获取玩家当前地图
func get_player_current_map() -> String:
	return _player_data["current_map_id"]

#* 获取可通行路径
func _get_passable_path(start: Vector2i, end: Vector2i) -> Array:
	return GridManager.path_finder.find_path(start, end, MOVE_STEP, true)

#* @deprecated 获取可移动路径
# func _get_costable_path(passable_path: Array) -> Array:
# 	var costable_path = []
# 	# TODO 计算可移动路径长度
# 	var current_stamina = player_core.get_player_current_stamina()
# 	for i in range(passable_path.size()):
# 		var position_info = {"position": passable_path[i], "data": {}}
# 		if i == 0:
# 			costable_path.append(position_info)
# 			continue
# 		var cost_stamina = MapManager.get_tile_stamina_cost(passable_path[i])
# 		# TODO 这里获取其他道路上的信息，存入position_info中的data
# 		if current_stamina >= cost_stamina:
# 			costable_path.append(position_info)
# 			current_stamina -= cost_stamina
# 	return costable_path

#* @deprecated 玩家输入管理器移动网格的回调函数
# func _on_player_input_manager_grid_moved(grid_pos: Vector2i) -> void:
# 	if move_status == MOVE_STATUS.MOVING:
# 		return
# 	var passable_path = _get_passable_path(_current_position, grid_pos)
# 	var costable_path = _get_costable_path(passable_path)
# 	button_coords_changed.emit(passable_path, costable_path)

func _exit_tree():
	player_movement_manager_registered.disconnect(PlayerManager._on_player_movement_manager_registered)
	 #reach_target.disconnect(PlayerManager._on_reach_target)
	# button_coords_changed.disconnect(MapManager.layer_grid_path.rend_directional)
	# move_status_changed.disconnect(MapManager.layer_grid_path._on_player_movement_manager_move_status_changed)
