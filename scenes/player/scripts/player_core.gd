#* 玩家核心数据管理器
#* 负责管理玩家的基础数据，如体力、属性等
extends Node2D

class_name PlayerCore

#* 获取玩家当前体力值
#* 从游戏数据管理器中获取玩家当前的体力值
#* @return float - 玩家当前体力值
func get_player_current_stamina() -> float:
	return GameDataManager.get_game_def_data_child("player_global_data", TYPE_DICTIONARY)["current_stamina"]
