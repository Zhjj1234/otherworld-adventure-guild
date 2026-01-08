extends Node

# var new_game_cache: GameData

signal current_game_cache_updated

var _current_game_cache: GameData

var _default_game_cache: GameData

#* 游戏数据管理器 - 负责处理游戏配置数据的获取和管理
var _game_data: Dictionary = {}

func _ready() -> void:
	_default_game_cache = preload("res://res/game_data/tres/game_data_new_game.tres")

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



#* 新增：对外暴露的深层字段快捷获取接口
func get_map_config_child(child_key: String, expected_type: int) -> Variant:
	return TypeUtil.get_dict_child_from_config(_game_data, "map_config", child_key, expected_type)

#* 新增：对外暴露的深层字段快捷获取接口
# func get_game_def_data_child(child_key: String, expected_type: int) -> Variant:
# 	return TypeUtil.get_dict_child_from_config(_game_data, "game_def_data", child_key, expected_type)

#* 新增：对外暴露的深层字段快捷获取接口
func get_level_system_config_child(child_key: String, expected_type: int) -> Variant:
	return TypeUtil.get_dict_child_from_config(_game_data, "level_system_config", child_key, expected_type)


# ==================== GameData专属接口 ======================

#* 获取游戏默认配置（字典类型）
func get_current_game_data() -> GameData:
	return _current_game_cache

#* 当前游戏数据更新时，通知外部
func set_current_game_data(new_game_data: GameData) -> void:
	_current_game_cache = new_game_data
	current_game_cache_updated.emit()

func get_default_game_data_duplicate() -> GameData:
	return _default_game_cache.duplicate(true)

# ==================== PlayerData专属接口 ====================

#* 获取当前玩家位置
func get_player_current_position() -> Vector2:
	return get_current_game_data().player_global_data.current_position

func set_player_current_position(position: Vector2) -> void:
	get_current_game_data().player_global_data.current_position = position

#* 获取当前玩家地图ID
func get_player_current_map_id() -> String:
	return get_current_game_data().player_global_data.current_map_id

func set_player_current_map_id(map_id: String) -> void:
	get_current_game_data().player_global_data.current_map_id = map_id

#* 获取当前玩家体力
func get_player_current_stamina() -> float:
	return get_current_game_data().player_global_data.current_stamina

func set_player_current_stamina(stamina: float) -> void:
	get_current_game_data().player_global_data.current_stamina = stamina