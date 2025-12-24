extends Node

#* 网格管理器 - 负责网格坐标与世界坐标的转换及路径寻路
const A_Star = preload("res://scripts/algorithm/A_star.gd")

#* 瓦片集资源
const TILE_SET: TileSet = preload("uid://cyme1i4riv63q")

#* A*寻路算法实例
var path_finder: A_Star

#* 节点初始化
func _ready() -> void:
	path_finder = A_Star.new()

#* 网格原点位置，用于坐标转换
var grid_origin: Vector2 = Vector2.ZERO

#* 获取瓦片尺寸的静态方法
#* @return 包含瓦片宽高的Vector2对象
func get_tile_size() -> Vector2:
	return Vector2( TILE_SET.tile_size.x,  TILE_SET.tile_size.y)

#* 世界坐标转网格坐标
#* @param world_pos 世界坐标位置
#* @return 对应的网格坐标
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - grid_origin
	var grid_x = floor(local_pos.x / TILE_SET.tile_size.x)
	var grid_y = floor(local_pos.y / TILE_SET.tile_size.y)
	#* 限制格子范围（可选，避免负数/超出地图）
	#* grid_x = max(0, min(grid_x, 地图最大列数-1))
	#* grid_y = max(0, min(grid_y, 地图最大行数-1))
	return Vector2i(grid_x, grid_y)

#* 网格坐标转世界中心坐标
#* @param grid_pos 网格坐标
#* @return 对应的世界坐标中心点
func grid_to_world_center(grid_pos: Vector2i) -> Vector2:
	var world_pos = grid_origin + Vector2(
		grid_pos.x *  TILE_SET.tile_size.x +  TILE_SET.tile_size.x / 2.0,
		grid_pos.y *  TILE_SET.tile_size.y +  TILE_SET.tile_size.y / 2.0
	)
	return world_pos
