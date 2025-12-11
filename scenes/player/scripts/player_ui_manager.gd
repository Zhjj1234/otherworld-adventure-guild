extends Sprite2D
class_name PlayerUIManager

#* 玩家UI管理器 - 控制玩家UI元素的位置更新

#? 设置玩家UI的真实位置
#todo 需要考虑不同分辨率下的适配问题
func set_real_position(player_coords: Vector2) -> void:
	#!! 获取网格大小用于坐标转换
	var tile_size = GridManager.get_tile_size()
	#* 将网格坐标转换为实际像素坐标并居中显示
	position = player_coords * tile_size + tile_size / 2
