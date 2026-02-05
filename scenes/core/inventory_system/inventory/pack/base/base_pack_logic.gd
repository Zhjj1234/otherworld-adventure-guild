#* 背包逻辑基类
#* 定义背包的出入验证接口，子类实现具体的验证逻辑
extends RefCounted
class_name BasePackLogic

#* 验证物品是否可以从此背包移出
#* @param slot_data 物品槽数据（包含 item_key、slot_size、rotation_index 等）
#* @param position 物品位置
#* @param target_pack_type 目标背包类型（用于判断跨背包规则）
#* @return ValidationResult 验证结果
func validate_out(slot_data: ItemSlotData, position: Vector2i, target_pack_type: BasePackData.PACK_TYPE) -> ValidationResult:
	return ValidationResult.ok()

#* 验证物品是否可以移入此背包
#* @param slot_data 物品槽数据（包含 item_key、slot_size、rotation_index 等）
#* @param position 目标位置
#* @param source_pack_type 源背包类型（用于判断跨背包规则）
#* @return ValidationResult 验证结果
func validate_in(slot_data: ItemSlotData, position: Vector2i, source_pack_type: BasePackData.PACK_TYPE) -> ValidationResult:
	return ValidationResult.ok()

#* 获取背包类型标识（子类必须实现）
#* @return 背包类型枚举
func get_pack_type() -> BasePackData.PACK_TYPE:
	push_error("BasePackLogic.get_pack_type() 必须在子类中实现")
	return BasePackData.PACK_TYPE.PACK
