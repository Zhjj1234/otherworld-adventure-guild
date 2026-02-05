#* 基础槽位数据
#* 包含槽位的基本信息：位置、旋转、大小
extends Resource
class_name BaseSlotData

#* 槽位在网格中的位置（左上角位置）
@export var position: Vector2i = Vector2i(0, 0)

#* 旋转状态：0=0°，1=90°，2=180°，3=270°（顺时针）
@export var rotation_index: int = 0

#* 槽位大小（占几格，宽x高）
@export var slot_size: Vector2i = Vector2i(1, 1)

#* 创建基础槽位数据
#* @param pos 位置
#* @param rotation 旋转状态
#* @param size 槽位大小
static func create(pos: Vector2i, rotation: int, size: Vector2i) -> BaseSlotData:
	var data = BaseSlotData.new()
	data.position = pos
	data.rotation_index = rotation
	data.slot_size = size
	return data
