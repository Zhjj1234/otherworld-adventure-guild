#* 网格区域数据结构（表示一个矩形区域及其标识）
extends RefCounted
class_name GridRegion

#* 区域起始位置
var pos: GridPos = GridPos.new()
#* 区域宽度（占几格）
var width: int = 1
#* 区域高度（占几格）
var height: int = 1
#* 区域标识（ID）
var region_id: String = ""

#* 构造函数
#* @param p_pos 区域起始位置
#* @param p_width 区域宽度
#* @param p_height 区域高度
#* @param p_region_id 区域标识
func _init(p_pos: GridPos = GridPos.new(), p_width: int = 1, p_height: int = 1, p_region_id: String = ""):
	self.pos = p_pos
	self.width = p_width
	self.height = p_height
	self.region_id = p_region_id

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
	return "GridRegion(id: %s, %s, %dx%d)" % [region_id, pos._to_string(), width, height]
