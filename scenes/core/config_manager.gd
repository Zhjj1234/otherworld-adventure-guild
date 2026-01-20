extends Node

var _map_config: MapConfig
var _item_config: ItemConfig

func _ready() -> void:
	_map_config = preload("res://res/config/map_config/tres/map_config.tres")
	_item_config = preload("res://res/config/item/tres/item_config.tres")

# ==================== MapConfig专属接口 ====================
func get_map_config() -> MapConfig:
	return _map_config

func get_map_info_list() -> Array[MapInfo]:
	return _map_config.map_info_list

func get_map_info_by_id(map_id: String) -> MapInfo:
	for map_info in _map_config.map_info_list:
		if map_info.map_id == map_id:
			return map_info
	return null

# ==================== ItemConfig专属接口 ====================
func get_item_config() -> ItemConfig:
	return _item_config

func get_normal_item_by_id(item_id: String) -> NormalItem:
	for item_key in _item_config.normal_item_list.keys():
		if item_key.item_id == item_id:
			return _item_config.normal_item_list[item_key]
	return null

func get_special_item_by_id(item_id: String) -> SpecialItem:
	for item_key in _item_config.special_item_list.keys():
		if item_key.item_id == item_id:
			return _item_config.special_item_list[item_key]
	return null
