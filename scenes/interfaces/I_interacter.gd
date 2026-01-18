extends RefCounted
class_name IInteractor

enum InteractType {
	NONE,
	GROUND
}

# ===================== 强制重写的抽象方法 =====================
# 【接口1】检测是否满足交互条件
# 参数: initiator 交互发起者（如玩家节点）
# 返回: bool  是否可交互
func _can_interact(_initiator: Node) -> bool:
	push_error("IInteractor: 子类必须实现 _can_interact 方法")
	return false

# 【接口2】执行具体交互逻辑
# 参数1: initiator 交互发起者
# 参数2: interact_type 交互类型（适配多类型交互目标）
func _execute_interact(_initiator: Node, _interact_type: InteractType = InteractType.NONE) -> void:
	push_error("IInteractor: 子类必须实现 _execute_interact 方法")

# ===================== 对外暴露的公共方法 =====================
# 交互入口（封装检测+执行逻辑，子类无需修改）
func interact(initiator: Node, interact_type: InteractType = InteractType.NONE) -> void:
	if _can_interact(initiator):
		_execute_interact(initiator, interact_type)
	else:
		print_debug("[IInteractor] 交互失败: 不满足条件 (发起者: {initiator.name})")
