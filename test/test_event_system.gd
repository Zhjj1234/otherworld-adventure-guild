#* 测试事件系统的脚本
class_name TestEventSystem extends Label


#* 测试事件系统
func _ready() -> void:
	print("=== 开始测试事件系统 ===")
	
	#print("创建的事件A名称: %s" % event_a.event_name)
	#print("创建的事件B名称: %s" % event_b.event_name)
	
	# 创建EventNode节点
	var event_node:EventNode = $EventNode
	## 打印调试信息
	#print("事件表达式: %s" % event_node.event_expression)
	#print("绑定事件数量: %d" % event_node.bound_events.size())
	#print("事件字典内容: %s" % event_node._event_dict)
	
	# 执行并获取结果
	var result = await event_node.get_execution_result()
	print("执行结果: %s" % result)
	
	print("=== 测试结束 ===")
