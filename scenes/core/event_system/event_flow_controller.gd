#* 事件流程控制器，用于管理事件节点之间的流转
#* 提供根据事件执行结果切换到下一个节点的功能
class_name EventFlowController

#* 根据EventNode执行结果切换到下一个EventNode
#* @param current_node 当前EventNode
#* @param result_map 结果映射，键为事件结果，值为下一个EventNode路径或节点
#* @return 下一个EventNode实例，如果没有则返回null
func set_next_node_by_result(current_node: EventNode, result_map: Dictionary) -> EventNode:
	# 获取当前节点的执行结果
	var result = await current_node.get_execution_result()
	var final_result = result["result"]
	
	# 根据结果映射获取下一个节点
	var next_node_ref = result_map.get(final_result, null)
	if not next_node_ref:
		return null
	
	# 处理不同类型的下一个节点引用
	var next_node: EventNode
	
	if typeof(next_node_ref) == TYPE_STRING:
		# 字符串路径，通过路径获取节点
		next_node = current_node.get_node_or_null(next_node_ref)
	elif next_node_ref is EventNode:
		# 直接是EventNode实例
		next_node = next_node_ref
	else:
		# 无效类型
		DebugPrint.print_simple("无效的下一个节点引用类型: {0}".format([typeof(next_node_ref)]), get_script().resource_path)
		return null
	
	# 检查是否是EventNode实例
	if not next_node is EventNode:
		DebugPrint.print_simple("下一个节点不是EventNode实例: {0}".format([next_node]), get_script().resource_path)
		return null
	
	return next_node
