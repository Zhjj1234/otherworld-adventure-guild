extends TileMapLayer
class_name LayerManager

#* 初始化函数

#* 获取指定层和坐标的瓦片自定义数据
#* @param layer_name 层名称
#* @param coords 网格坐标
#* @return 包含自定义数据的字典
func get_tile_data(layer_name: String, coords: Vector2i) -> Dictionary:
	var tile_data = get_cell_tile_data(coords)
	if tile_data is TileData:
		var custom_data = tile_data.get_custom_data(layer_name)
		if custom_data is Dictionary:
			return custom_data
	return {}
	
