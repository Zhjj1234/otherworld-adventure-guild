extends Node2D
class_name PlayerManager

#* 玩家数据变量，存储从游戏数据管理器获取的玩家信息
# TODO 这里需要保存
var _player_data

#* 玩家UI管理器引用，用于更新玩家UI位置
@onready var player_ui_mamager: PlayerUIManager = %PlayerUIManager

#* 玩家移动速度常量，单位：格子/秒
const PLAYER_SPEED: float = 1 / 0.1
const MOVE_STEP: int = 30

#* 移动状态枚举
enum MOVE_STATUS {
	MOVING, # * 正在移动
	STOP # * 停止状态
}

#* 到达目标位置时发出的信号
#* @param coords: Vector2i - 到达的目标坐标
signal reach_target(coords: Vector2i)

#* 目标位置坐标
var _target_position: Vector2 = Vector2.ZERO
#* 当前位置坐标
var _current_position: Vector2 = Vector2.ZERO
#* 移动状态变量
var _move_status: MOVE_STATUS = MOVE_STATUS.STOP
#*var _is_move_interrupted: bool = false
var _final_position: Vector2i = Vector2i.ZERO

#* 初始化玩家管理器
#* 获取玩家初始数据并设置初始状态
func init() -> void:
	_player_data = GameDataManager.get_game_def_data_child("player_global_data", TYPE_DICTIONARY)
	_current_position = Vector2(_player_data["current_position"]["x"], _player_data["current_position"]["y"])
	_target_position = _current_position
	_final_position = _current_position
	_move_status = MOVE_STATUS.STOP
	#* 示例：移动到坐标(6,0)
	#*move_to(Vector2i(6,0))

#* 游戏主循环处理函数
#* 每帧更新玩家位置和UI显示
#* @param delta: float - 帧间隔时间
func _process(delta: float) -> void:
	_update_position(delta)
	#* 更新玩家UI位置
	player_ui_mamager.set_real_position(_current_position)

#* 更新玩家位置的内部函数
#* 根据移动状态和速度计算当前位置
#* @param delta: float - 帧间隔时间
func _update_position(delta: float):
	if _move_status == MOVE_STATUS.MOVING:
		#* 向目标位置移动
		_current_position = _current_position.move_toward(_target_position, PLAYER_SPEED * delta)
		if _current_position == _target_position:
			#* 到达目标位置，停止移动
			_move_status = MOVE_STATUS.STOP
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
	if _move_status == MOVE_STATUS.MOVING:
		await reach_target
	#* 使用A*算法寻找从当前位置到目标位置的路径
	#* 参数说明：
	#* - _current_position: 当前位置
	#* - coords: 目标位置
	#* - MOVE_STEP: 最大步长，限制路径搜索的范围
	#* - true: 是否允许对角线移动
	var path = GridManager.path_finder.find_path(_current_position, coords, MOVE_STEP, true)
	#* 保存最终目标位置，用于检测路径是否仍然有效
	_final_position = path.back()
	#* 循环处理路径中的每个点，直到到达终点
	#* 路径的第一个元素是当前位置，所以从第二个元素开始处理
	while path.size() > 1:
		#* 检查最终目标位置是否发生变化，如果变化则终止当前移动
		if _final_position != path.back():
			return
		#* 设置移动状态为移动中
		_move_status = MOVE_STATUS.MOVING
		#* 设置下一个目标位置为路径中的第二个点
		_target_position = path[1]
		#* 等待到达当前目标点的信号
		await reach_target
		#* 到达目标点后，移除路径中的第一个点，继续处理剩余路径
		path.pop_front()

#* 到达目标位置时的回调函数
func _on_reach_target():
	#* 发出到达目标位置信号
	reach_target.emit(_current_position)

func _on_player_input_manager_grid_clicked(grid_pos: Vector2i) -> void:
	move_to(grid_pos)
