#* 物品槽位数据
#* 继承自 BaseSlotData，添加物品ID信息
extends BaseSlotData
class_name ItemSlotData

#* 物品ID（如果为空字符串则表示空槽）
@export var item_key: String = ""

#* 创建物品槽位数据
#* @param pos 位置
#* @param rotation 旋转状态
#* @param size 槽位大小
#* @param key 物品ID
static func create(pos: Vector2i, rotation: int, size: Vector2i, key: String = "") -> ItemSlotData:
	var data = ItemSlotData.new()
	data.position = pos
	data.rotation_index = rotation
	data.slot_size = size
	data.item_key = key
	return data

#* 判断是否为空槽
func is_empty() -> bool:
	return item_key == ""
