#* 事件解析执行器，无状态工具类
#* 提供静态方法，用于解析和执行事件表达式
class_name EventParserExecutor

#* 解析并执行事件表达式
#* @param expr 事件表达式，如 "A|B"、"A->B"、"!A"
#* @param events 事件字典，键为事件名称，值为BaseEvent实例
#* @return 执行的事件名称列表
static func parse_and_execute(expr: String, events: Dictionary[StringName, BaseEvent]) -> Array[StringName]:
	var executed_events: Array[StringName] = []
	
	# 按顺序触发（->）分割
	var sequence_steps = expr.split("->")
	
	for step in sequence_steps:
		step = step.strip_edges()
		
		# 检查是否包含互斥触发（|）
		if "|" in step:
			var executed = await _execute_mutex_events(step, events)
			executed_events.append_array(executed)
		else:
			# 单一事件或非事件
			var executed = await _execute_single_or_not_event(step, events)
			if executed:
				executed_events.append(executed)
	
	return executed_events

#* 执行互斥事件（|）
#* @param expr 互斥事件表达式，如 "A|B|C"
#* @param events 事件字典
#* @return 执行的事件名称列表
static func _execute_mutex_events(expr: String, events: Dictionary[StringName, BaseEvent]) -> Array[StringName]:
	var executed_events: Array[StringName] = []
	var mutex_events: Array[BaseEvent] = []
	var total_weight: float = 0.0
	
	# 分割互斥事件，计算总权重
	var event_names = expr.split("|")
	for name in event_names:
		name = name.strip_edges()
		var event_name = StringName(name)
		
		# 检查事件是否在字典中
		if event_name in events:
			var event = events[event_name]
			mutex_events.append(event)
			total_weight += event.weight
	
	# 如果没有有效的互斥事件，直接返回
	if mutex_events.is_empty():
		return executed_events
	
	# 归一化权重，随机选择一个事件触发
	var random_value = randf() * total_weight
	var current_weight = 0.0
	var selected_event: BaseEvent = null
	
	for event in mutex_events:
		current_weight += event.weight
		if random_value <= current_weight:
			selected_event = event
			break
	
	# 触发选中的事件，其他互斥事件重置为未触发
	for event in mutex_events:
		if event == selected_event:
			if await event.trigger():
				executed_events.append(event.event_name)
		else:
			event.reset()
	
	return executed_events

#* 执行单一事件或非事件（!）
#* @param expr 单一事件表达式，如 "A" 或 "!A"
#* @param events 事件字典
#* @return 执行的事件名称，如果没有则返回空
static func _execute_single_or_not_event(v_expr: String, events: Dictionary[StringName, BaseEvent]) -> StringName:
	var expr = v_expr.strip_edges()
	var is_not = false
	var event_name: StringName
	
	# 处理非操作（!）
	if expr.begins_with("!"):
		is_not = true
		event_name = StringName(expr.substr(1).strip_edges())
	else:
		event_name = StringName(expr)
	
	if event_name not in events:
		return ""
	
	var event = events[event_name]
	
	if is_not:
		# 非操作：重置事件
		event.reset()
		return ""
	else:
		# 单一事件触发
		if await event.trigger():
			return event.event_name
	
	return ""
