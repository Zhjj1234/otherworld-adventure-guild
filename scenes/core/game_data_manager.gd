extends Node

#* 游戏数据管理器 - 负责处理游戏配置数据的获取和管理
var _game_data: Dictionary = {}

#? 获取地图图集信息
#! 返回值可能是空数组，调用方需要注意处理
func get_map_data(key: String) -> Array:
	var atlas_info: Array = get_game_data_by_key("map_config").get(key)
	#!! 检查atlas_info字段是否存在且为数组类型
	if not atlas_info is Array:
		push_warning("atlas_info 字段格式错误")
		return []
	
	#* 直接返回目标数组（需深拷贝则改为 atlas_info.duplicate(true)）
	return atlas_info

#? 获取玩家数据
#! 返回值可能是空字典，调用方需要注意处理
func get_player_data(key: String) -> Dictionary:
	var player_data: Dictionary = get_game_data_by_key("game_def_data").get(key) as Dictionary
	#!! 检查player_data是否为有效字典
	if not player_data is Dictionary:
		push_warning("缺失 player 字段或格式错误")
		return {}
	
	return player_data

#? 获取默认配置数据
#! 返回值可能是空字典，调用方需要注意处理
func get_game_data_by_key(key: String) -> Dictionary:
	#* 安全校验：确保游戏数据和嵌套字段格式正确
	if not _game_data is Dictionary:
		push_warning("游戏数据格式错误")
		return {}
	
	var def_data: JSON = _game_data.get(key) as JSON
	#!! 检查def字段是否存在且为JSON对象
	if not def_data is JSON:
		push_warning("缺失 def 字段或格式错误")
		return {}
	
	return def_data.data
