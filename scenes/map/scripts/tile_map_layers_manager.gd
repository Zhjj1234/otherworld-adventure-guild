extends Node2D
class_name TileMapLayersManager

#* 预加载瓦片集资源
const TILESET = preload("uid://ctykftisdiffi")

#* 存储所有图层管理器的数组
var layers: Array[LayerManager] = []

#* 初始化函数，设置瓦片数据、图层和寻路功能
func init():
	_set_tile_datas()
	_set_layers()
	_set_path_finder_func()

#* 设置图层管理器数组
#* 遍历所有子节点，找出LayerManager类型的节点并初始化
func _set_layers():
	var arr: Array[Node] = get_children()
	for node in arr:
		if node is LayerManager:
			layers.append(node)
			(node as LayerManager).init()

#* 设置寻路功能函数
#* 配置A*算法中的可通过性判断逻辑
func _set_path_finder_func():
	GridManager.path_finder.set_is_passable_grid_inner(
		func(coords: Vector2i) -> bool:
			#* 遍历地面图层检查是否可通过
			for layer: LayerManager in layers:
				var is_passable_data: Dictionary = layer.get_tile_data("move", coords)
				#* 如果没有移动权限，则返回false
				if is_passable_data.has("is_passable") and is_passable_data.get("is_passable"):
					pass
				else:
					return false
			return true
	)

#* 设置所有瓦片的自定义数据
#* 从游戏数据管理器获取图集信息，并设置到瓦片集中
func _set_tile_datas():
	var atlas_infos = GameDataManager.get_map_data("atlas_info")
	for atlas in atlas_infos:
		var source_id = atlas["source_id"]
		var atlas_info = atlas["tile_infos"]
		for tile_data in atlas_info:
			var atlas_coords = tile_data["atlas_coords"]
			var layer_name = tile_data["layer_name"]
			var custom_data = tile_data["custom_data"]
			var layer_position = tile_data["layer_position"]
			#* 检查是否存在同名的自定义数据层，如果不存在则创建
			if not TILESET.has_custom_data_layer_by_name(layer_name):
				TILESET.add_custom_data_layer(layer_position)
				TILESET.set_custom_data_layer_name(layer_position, layer_name)
				TILESET.set_custom_data_layer_type(layer_position, typeof(custom_data))
			var tile_set_atlas_source: TileSetAtlasSource = TILESET.get_source(source_id) as TileSetAtlasSource
			var data: TileData = tile_set_atlas_source.get_tile_data(Vector2i(atlas_coords["x"], atlas_coords["y"]), 0)
			data.set_custom_data(layer_name, custom_data)
