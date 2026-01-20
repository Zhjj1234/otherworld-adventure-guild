extends Node2D
#* 瓦片地图图层管理器类，负责管理地图的多个图层以及寻路功能
class_name TileMapLayersManager

#* 图层管理器注册信号
signal tile_map_layers_manager_registered(tile_map_layers_manager: TileMapLayersManager)

#* 存储所有图层管理器的数组
var layers: Array[LayerManager] = []

#* 初始化函数，设置瓦片数据、图层和寻路功能
func _ready():
	#_set_tile_datas()
	_set_layers()
	_set_path_finder_func()
	tile_map_layers_manager_registered.connect(MapManager.on_tile_map_layers_manager_registered)
	tile_map_layers_manager_registered.emit(self)
	

#* 设置图层管理器数组
#* 遍历所有子节点，找出LayerManager类型的节点并初始化
func _set_layers():
	var arr: Array[Node] = get_children()
	for node in arr:
		if node is LayerManager:
			layers.append(node)
	#* 倒序遍历，保证检测上层至下层顺序检测
	layers.reverse()
			#(node as LayerManager).init()

#* 设置寻路功能函数
#* 配置A*算法中的可通过性判断逻辑
func _set_path_finder_func():
	
	GridManager.path_finder.set_is_passable_grid_inner(
		func(coords: Vector2i) -> bool:
			#* 遍历地面图层检查是否可通过
			for layer: LayerManager in layers:
				var custom_data = layer.get_tile_data("is_passable", coords)
				#* 如果没有移动权限，则返回false
				if custom_data is bool:
					if not custom_data:
						return false
					else:
						return true
			return false
	)

func _exit_tree():
	tile_map_layers_manager_registered.disconnect(MapManager.on_tile_map_layers_manager_registered)
