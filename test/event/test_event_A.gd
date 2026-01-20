class_name TestEventA extends BaseEvent

func _execute() -> StringName:
	print("TestEventA 执行")
	await get_tree().create_timer(2).timeout
	return "TestEventA"
