extends Node2D
#* 玩家管理器类，负责管理玩家相关的功能和状态
class_name PlayerManager

#* 玩家移动管理器，用于控制玩家角色的移动
@onready var player_movement_manager: PlayerMovementManager = $PlayerMovementManager

#* 玩家管理器注册信号
signal player_manager_registered(player_manager: PlayerManager)

#* 玩家数据变量，存储从游戏数据管理器获取的玩家信息
# TODO 这里需要保存
#var _player_data  #* 临时注释掉的玩家数据变量

#* 初始化函数，连接玩家管理器到游戏管理器
func _ready() -> void:
	#_player_data = GameDataManager.get_game_def_data_child("player_global_data", TYPE_DICTIONARY)  #* 从游戏数据管理器获取玩家全局数据
	player_manager_registered.connect(GameManager.on_player_manager_registered)  #* 连接到游戏管理器的玩家注册函数
	player_manager_registered.emit(self)  #* 发出玩家管理器注册信号

#* 节点从场景树中移除时清理连接
func _exit_tree() -> void:
	player_manager_registered.disconnect(GameManager.on_player_manager_registered)  #* 断开与游戏管理器的连接
