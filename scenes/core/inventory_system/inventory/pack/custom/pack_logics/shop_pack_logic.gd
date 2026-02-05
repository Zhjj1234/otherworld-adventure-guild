#* 商店背包逻辑
#* 实现商店的出入验证规则
extends BasePackLogic
class_name ShopPackLogic

#* 获取背包类型标识
func get_pack_type() -> BasePackData.PACK_TYPE:
	return BasePackData.PACK_TYPE.SHOP

#* 验证物品是否可以从商店移出（购买）
#* 商店逻辑：检查玩家是否有足够金币
func validate_out(slot_data: ItemSlotData, position: Vector2i, target_pack_type: BasePackData.PACK_TYPE) -> ValidationResult:
	# 只有玩家背包可以购买商店物品
	if target_pack_type != BasePackData.PACK_TYPE.INVENTORY:
		return ValidationResult.fail("商店物品只能购买至玩家背包")
	
	# TODO: 实现金币检查逻辑
	# var item_price = get_item_price(slot_data.item_key)
	# if not player_has_enough_gold(item_price):
	#     return ValidationResult.fail("金币不足")
	
	return ValidationResult.ok({"price": 100})  # 示例：返回价格信息

#* 验证物品是否可以移入商店（出售）
#* 商店逻辑：检查商店是否有空位、物品是否可出售
func validate_in(slot_data: ItemSlotData, position: Vector2i, source_pack_type: BasePackData.PACK_TYPE) -> ValidationResult:
	# 只有玩家背包可以向商店出售
	if source_pack_type != BasePackData.PACK_TYPE.CHARACTER_PACK:
		return ValidationResult.fail("只有玩家背包可以向商店出售物品")
	
	# TODO: 实现物品可出售性检查
	# if not is_item_sellable(slot_data.item_key):
	#     return ValidationResult.fail("该物品不可出售")
	
	# TODO: 实现商店空位检查
	# if not shop_has_empty_slot():
	#     return ValidationResult.fail("商店没有空位")
	
	return ValidationResult.ok({"sell_price": 50})  # 示例：返回出售价格
