extends Label

func _ready() -> void:
		# 创建事件实例
	var event_a = TestEventA.new("EventA", 1.0)
	var event_b = TestEventB.new("EventB", 2.0)

	# 获取 EventNode 节点
	var event_node: EventNode = $EventNode

	# 设置事件表达式和绑定事件
	event_node.event_expression = "EventA|EventB"
	event_node.bound_events = []
	event_node.bound_events.append(event_a)
	event_node.bound_events.append(event_b)

	# 执行并获取结果
	var result = event_node.get_execution_result()
	print("执行结果: %s" % result)
