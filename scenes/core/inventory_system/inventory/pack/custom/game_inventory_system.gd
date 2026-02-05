#* 游戏背包系统 - InventorySystem 子类
#* 实现具体的背包逻辑和验证规则
extends InventorySystem
class_name GameInventorySystem

#* 获取或创建背包逻辑实例（重写父类方法）
#* @param pack_type 背包类型
#* @return 背包逻辑实例
func _get_pack_logic(pack_type: BasePackData.PACK_TYPE) -> BasePackLogic:
	if pack_logic_cache.has(pack_type):
		return pack_logic_cache[pack_type]
	
	var logic: BasePackLogic
	match pack_type:
		BasePackData.PACK_TYPE.SHOP:
			logic = ShopPackLogic.new()
		_:
			logic = BasePackLogic.new()
	
	pack_logic_cache[pack_type] = logic
	return logic
