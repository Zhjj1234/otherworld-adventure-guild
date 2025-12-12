extends Node

#* 游戏数据管理器 - 负责处理游戏配置数据的获取和管理
var _game_data: Dictionary = {}

# ==================== 业务专属获取接口（对外暴露，语义清晰） ====================
#* 获取地图配置（字典类型）
func get_map_config() -> Dictionary:
	return TypeUtil.get_valid_dict(_game_data.get("map_config", {}), "map_config")

#* 获取等级系统配置（字典类型）
func get_level_system_config() -> Dictionary:
	return TypeUtil.get_valid_dict(_game_data.get("level_system_config", {}), "level_system_config")

#* 获取技能配置（数组类型）
func get_skill_config() -> Array:
	return TypeUtil.get_valid_array(_game_data.get("skill_config", []), "skill_config")

#* 获取职业配置（数组类型）
func get_job_config() -> Array:
	return TypeUtil.get_valid_array(_game_data.get("job_config", []), "job_config")

#* 获取敌人配置（数组类型）
func get_enemy_config() -> Array:
	return TypeUtil.get_valid_array(_game_data.get("enemy_config", []), "enemy_config")

#* 获取游戏默认配置（字典类型）
func get_game_def_data() -> Dictionary:
	return TypeUtil.get_valid_dict(_game_data.get("game_def_data", {}), "game_def_data")

#* 新增：对外暴露的深层字段快捷获取接口
func get_map_config_child(child_key: String, expected_type: int) -> Variant:
	return TypeUtil.get_dict_child_from_config(_game_data, "map_config", child_key, expected_type)

#* 新增：对外暴露的深层字段快捷获取接口
func get_game_def_data_child(child_key: String, expected_type: int) -> Variant:
	return TypeUtil.get_dict_child_from_config(_game_data, "game_def_data", child_key, expected_type)

#* 新增：对外暴露的深层字段快捷获取接口
func get_level_system_config_child(child_key: String, expected_type: int) -> Variant:
	return TypeUtil.get_dict_child_from_config(_game_data, "level_system_config", child_key, expected_type)
