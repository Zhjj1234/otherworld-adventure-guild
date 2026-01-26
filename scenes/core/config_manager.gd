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

## 根据item_id获取物品
func get_item_by_id(item_id: StringName) -> ItemData:
	if _item_config.item_data_list.has(item_id):
		return _item_config.item_data_list[item_id].item_data
	push_warning("item_id: {0} not found".format([item_id]))
	return null
