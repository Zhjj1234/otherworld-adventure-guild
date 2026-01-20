extends IInteractor
class_name DefaultInteracter

func _can_interact(_initiator: Node) -> bool:
	return true

func _execute_interact(_initiator: Node, _interact_type: InteractType = InteractType.NONE) -> void:
	pass
