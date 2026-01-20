#* 事件基类，定义事件的基础属性和方法
#* Godot 4.5.1 兼容，遵循 GDScript 4.0+ 语法
class_name BaseEvent extends Node

#* 事件名称，用于唯一标识事件
@export var event_name: StringName

#* 事件是否已触发
var is_triggered: bool = false

#* 事件执行结果
var result: StringName = "NONE"

#* 事件权重，用于互斥触发时的概率计算
@export var weight: float = 1.0

#* 重置事件状态
func reset() -> void:
	is_triggered = false
	result = "NONE"

#* 触发事件
#* @param forced 是否强制触发（默认为false）
#* @return 事件是否成功触发
func trigger(forced: bool = false) -> bool:
	if is_triggered and not forced:
		return false
	is_triggered = true
	result = await _execute()
	return true

#* 事件执行的具体逻辑，由子类实现
#* @return 事件执行结果
func _execute() -> StringName:
	return "SUCCESS"
