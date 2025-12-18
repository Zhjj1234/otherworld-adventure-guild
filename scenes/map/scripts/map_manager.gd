extends Node2D
class_name MapManager

#* 地图管理器 - 负责管理地图相关的功能
var _tile_map_layers_manager: TileMapLayersManager = null

#* 初始化地图管理器
func init(map: Node) -> void:
	if map is TileMapLayersManager:
		_tile_map_layers_manager = map as TileMapLayersManager
		_tile_map_layers_manager.init()

func _register_to_game_manager() -> void:
	GameManager._map_manager = self
