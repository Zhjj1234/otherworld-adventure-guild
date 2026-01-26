#* 网格矩形数据结构（表示物体占用区域）
extends RefCounted
class_name GridRect

var pos: GridPos = GridPos.new()
var width: int = 1
var height: int = 1

#* 构造函数
func _init(p_pos: GridPos = GridPos.new(), p_width: int = 1, p_height: int = 1):
	self.pos = p_pos
	self.width = p_width
	self.height = p_height

#* 获取所有覆盖的格子坐标
func get_covered_positions() -> Array[GridPos]:
	var positions: Array[GridPos] = []
	for grid_y in range(height):
		for grid_x in range(width):
			positions.append(GridPos.new(pos.x + grid_x, pos.y + grid_y))
	return positions

#* 检查是否包含某个格子
func contains(p_pos: GridPos) -> bool:
	return p_pos.x >= pos.x and p_pos.x < pos.x + width and \
		   p_pos.y >= pos.y and p_pos.y < pos.y + height

#* 字符串表示
func _to_string() -> String:
	return "GridRect(%s, %dx%d)" % [pos._to_string(), width, height]
