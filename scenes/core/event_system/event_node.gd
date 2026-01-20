#* 事件节点，作为场景节点容器，管理事件表达式和绑定的事件实例
#* Godot 4.5.1 兼容，可直接挂载到场景中使用
class_name EventNode extends Node

#* 事件表达式，如 "A|B"、"A->B"
@export var event_expression: String = ""

#* 绑定的事件实例数组
@export var bound_events: Array[BaseEvent] = []

#* 事件字典，键为事件名称，值为BaseEvent实例
var _event_dict: Dictionary[StringName, BaseEvent] = {}

#* 初始化方法
func _ready() -> void:
	# 初始化事件字典
	_rebuild_event_dict()

#* 重新构建事件字典（每次执行前调用）
func _rebuild_event_dict() -> void:
	_event_dict.clear()
	
	for event in bound_events:
		if event is BaseEvent:
			# 确保事件名称是StringName类型
			var event_name: StringName
			if typeof(event.event_name) == TYPE_STRING:
				event_name = StringName(event.event_name)
			else:
				event_name = event.event_name
			
			# 添加到事件字典
			_event_dict[event_name] = event

#* 当绑定事件数组变化时调用
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	
	# 检查重复事件名称
	var event_names = []
	for event in bound_events:
		if event is BaseEvent:
			if event.event_name in event_names:
				warnings.append("重复的事件名称: %s" % event.event_name)
			else:
				event_names.append(event.event_name)
		else:
			warnings.append("绑定的不是BaseEvent实例: %s" % event)
	
	return warnings

#* 获取执行结果
#* @return 执行结果字典，包含执行的事件列表和最终状态
func get_execution_result() -> Dictionary:
	print("=== EventNode执行开始 ===")
	
	# 每次执行前重新构建事件字典，确保最新
	_rebuild_event_dict()
	
	print("事件表达式: ", event_expression)
	print("事件字典大小: ", _event_dict.size())
	print("事件字典键: ", _event_dict.keys())
	
	# 重置所有事件状态
	for event in _event_dict.values():
		print("重置事件: %s" % event.event_name)
		event.reset()
	
	# 解析并执行事件表达式
	var executed_events = await EventParserExecutor.parse_and_execute(event_expression, _event_dict)
	
	print("执行的事件数量: ", executed_events.size())
	print("执行的事件列表: ", executed_events)
	
	# 计算最终结果
	var final_result: StringName = "NONE"
	for event in _event_dict.values():
		print("事件 %s 的触发状态: %s, 结果: %s" % [event.event_name, event.is_triggered, event.result])
	
	# 修复：使用最后一个执行的事件结果作为最终结果
	if not executed_events.is_empty():
		var last_event_name = executed_events[-1]
		if last_event_name in _event_dict:
			final_result = _event_dict[last_event_name].result
			print("使用最后一个执行事件 %s 的结果: %s" % [last_event_name, final_result])
	
	var result = {
		"events": executed_events,
		"result": final_result
	}
	
	print("最终执行结果: %s" % result)
	print("=== EventNode执行结束 ===")
	
	return result

#* 添加绑定事件
#* @param event BaseEvent实例
func add_bound_event(event: BaseEvent) -> void:
	if event is BaseEvent:
		bound_events.append(event)

#* 移除绑定事件
#* @param event_name 事件名称
func remove_bound_event(event_name: StringName) -> void:
	for i in range(bound_events.size() - 1, -1, -1):
		if bound_events[i].event_name == event_name:
			bound_events.remove_at(i)
			break

#* 获取绑定的事件
#* @param event_name 事件名称
#* @return BaseEvent实例，如果不存在则返回null
func get_bound_event(event_name: StringName) -> BaseEvent:
	return _event_dict.get(event_name, null)
