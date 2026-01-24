extends Node

var on_reach_target:PackedScene = preload("res://scenes/event/on_reach_target/on_reach_target.tscn")

#* 测试事件系统
func _ready() -> void:
	var node:EventNode = on_reach_target.instantiate()
	add_child(node)
	var b = await node.get_execution_result()
	print(b)
	
