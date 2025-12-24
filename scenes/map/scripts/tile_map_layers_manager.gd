extends Node2D
#* 瓦片地图图层管理器类，负责管理地图的多个图层以及寻路功能
class_name TileMapLayersManager

#* 图层管理器注册信号
signal tile_map_layers_manager_registered(tile_map_layers_manager: TileMapLayersManager)

#* 存储所有图层管理器的数组
var layers: Array[LayerManager] = []

#* 初始化函数，设置瓦片数据、图层和寻路功能
func _ready():
	_set_tile_datas()
	_set_layers()
	_set_path_finder_func()
	tile_map_layers_manager_registered.connect(get_parent().on_tile_map_layers_manager_registered)
	tile_map_layers_manager_registered.emit(self)
	

#* 设置图层管理器数组
#* 遍历所有子节点，找出LayerManager类型的节点并初始化
func _set_layers():
	var arr: Array[Node] = get_children()
	for node in arr:
		if node is LayerManager:
			layers.append(node)
			#(node as LayerManager).init()

#* 设置寻路功能函数
#* 配置A*算法中的可通过性判断逻辑
func _set_path_finder_func():
	GridManager.path_finder.set_is_passable_grid_inner(
		func(coords: Vector2i) -> bool:
			var has_passable = false
			#* 遍历地面图层检查是否可通过
			for layer: LayerManager in layers:
				var is_passable_data: Dictionary = layer.get_tile_data("move", coords)
				#* 如果没有移动权限，则返回false
				if is_passable_data.has("is_passable"):
					if not is_passable_data.get("is_passable"):
						return false
					else:
						has_passable = true
			if has_passable:
				return true
			return false
	)

#* 设置所有瓦片的自定义数据
#* 从游戏数据管理器获取图集信息，并设置到瓦片集中
func _set_tile_datas():
	var atlas_infos = GameDataManager.get_map_config_child("atlas_info", TYPE_ARRAY) as Array
	for atlas in atlas_infos:
		var source_id = atlas["source_id"]
		var atlas_info = atlas["tile_infos"]
		for tile_data in atlas_info:
			var atlas_coords = tile_data["atlas_coords"]
			var layer_name = tile_data["layer_name"]
			var custom_data = tile_data["custom_data"]
			var layer_position = tile_data["layer_position"]
			#* 检查是否存在同名的自定义数据层，如果不存在则创建
			if not GridManager.TILE_SET.has_custom_data_layer_by_name(layer_name):
				GridManager.TILE_SET.add_custom_data_layer(layer_position)
				GridManager.TILE_SET.set_custom_data_layer_name(layer_position, layer_name)
				GridManager.TILE_SET.set_custom_data_layer_type(layer_position, typeof(custom_data))
			var tile_set_atlas_source: TileSetAtlasSource = GridManager.TILE_SET.get_source(source_id) as TileSetAtlasSource
			var data: TileData = tile_set_atlas_source.get_tile_data(Vector2i(atlas_coords["x"], atlas_coords["y"]), 0)
			data.set_custom_data(layer_name, custom_data)

#* 获取指定坐标的移动成本
#* @param coords 坐标向量
#* @return 移动成本值
func get_tile_move_cost(coords: Vector2i) -> float:
	var move_cost = 0  #* 初始化移动成本为0
	for layer: LayerManager in layers:
		var is_passable_data: Dictionary = layer.get_tile_data("move", coords)  #* 获取移动相关数据
		if is_passable_data.has("move_cost"):
			move_cost = move_cost + is_passable_data.get("move_cost")  #* 累加移动成本
	return move_cost  #* 返回总移动成本

func _exit_tree():
	tile_map_layers_manager_registered.disconnect(get_parent().on_tile_map_layers_manager_registered)
