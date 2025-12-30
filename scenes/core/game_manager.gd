extends Node

#* 切换到指定地图并设置玩家位置
func switch_map(map_id: String, player_position: Vector2):
	MapManager.switch_map(map_id)  #* 切换当前地图
	PlayerManager.player_movement_manager.set_player_position(player_position)  #* 设置玩家在新地图中的位置

#* 初始化游戏状态，从存档数据中恢复玩家位置和地图
func initizalize_game_state():
	var current_map_id = GameDataManager.get_player_current_map_id()  #* 获取当前地图ID
	var current_player_position = GameDataManager.get_player_current_position()  #* 获取玩家当前位置
	switch_map(current_map_id, current_player_position)  #* 切换到存档时的地图和位置
