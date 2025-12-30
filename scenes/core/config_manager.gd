extends Node

var _map_config: MapConfig

func _ready() -> void:
	_map_config = ResourceLoader.load("res://res/config/map_config/tres/map_config.tres")

# ==================== MapConfig专属接口 ====================
func get_map_config() -> MapConfig:
	return _map_config

func get_atlas_info_list() -> Array[AtlasInfo]:
	return _map_config.atlas_info_list

func get_map_info_list() -> Array[MapInfo]:
	return _map_config.map_info_list

func get_map_info_by_id(map_id: String) -> MapInfo:
	for map_info in _map_config.map_info_list:
		if map_info.map_id == map_id:
			return map_info
	return null
