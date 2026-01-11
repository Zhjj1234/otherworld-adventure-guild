extends Node

#* 切换到指定地图并设置玩家位置
func switch_map(map_id: String, player_position: Vector2):
	MapManager.switch_map(map_id)  #* 切换当前地图
	PlayerManager.set_player_position(player_position)  #* 设置玩家在新地图中的位置
