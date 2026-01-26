#* 格子坐标数据结构
extends RefCounted
class_name GridPos

var x: int = 0
var y: int = 0

#* 构造函数
func _init(p_x: int = 0, p_y: int = 0):
	self.x = p_x
	self.y = p_y

#* 转换为Vector2i
func to_vector2i() -> Vector2i:
	return Vector2i(x, y)

#* 从Vector2i创建
static func from_vector2i(vec: Vector2i) -> GridPos:
	return GridPos.new(vec.x, vec.y)

#* 字符串表示
func _to_string() -> String:
	return "GridPos(%d, %d)" % [x, y]

#* 相等比较
func _operator_equal(other: Object) -> bool:
	if other is GridPos:
		return x == other.x and y == other.y
	return false
