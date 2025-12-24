extends Node

#* 游戏管理器节点，负责协调地图和玩家管理器
var _map_manager: MapManager = null  #* 地图管理器实例引用
var _player_manager: PlayerManager = null  #* 玩家管理器实例引用

#* 当玩家管理器注册时调用
func on_player_manager_registered(player_manager: PlayerManager):
	_player_manager = player_manager

#* 当地图管理器注册时调用
func on_map_manager_registered(map_manager: MapManager):
	_map_manager = map_manager

#* 切换到指定地图并设置玩家位置
func switch_map(map_id: String, player_position: Vector2):
	_map_manager.switch_map(map_id)  #* 切换当前地图
	_player_manager.player_movement_manager.set_player_position(player_position)  #* 设置玩家在新地图中的位置

#* 初始化游戏状态，从存档数据中恢复玩家位置和地图
func initizalize_game_state():
	var player_global_data = GameDataManager.\
		get_game_def_data_child("player_global_data", TYPE_DICTIONARY)  #* 获取玩家全局数据
	var current_map_id = player_global_data.current_map_id  #* 获取当前地图ID
	var current_player_position = player_global_data.current_position  #* 获取玩家当前位置
	switch_map(current_map_id, Vector2(current_player_position.x, current_player_position.y))  #* 切换到存档时的地图和位置
