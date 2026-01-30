#* 放置结果数据结构
extends RefCounted
class_name PlacementResult

var is_valid: bool = false
var rect: GridRect = GridRect.new()
var blocking_positions: Array[GridPos] = []
#* 区域标识（如果放置有效，表示该区域属于哪个区域或区域交集）
var region_id: String = ""

#* 构造函数
func _init(p_is_valid: bool = false, p_rect: GridRect = GridRect.new(), p_blocking_positions: Array[GridPos] = [], p_region_id: String = ""):
	self.is_valid = p_is_valid
	self.rect = p_rect
	self.blocking_positions = p_blocking_positions
	self.region_id = p_region_id

#* 字符串表示
func _to_string() -> String:
	return "PlacementResult(is_valid: %s, rect: %s, blocking_count: %d, region_id: %s)" % [is_valid, rect._to_string(), blocking_positions.size(), region_id]
