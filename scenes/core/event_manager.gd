extends Node
@export var game_event_dictionary: Dictionary[String, EventNode]

func aaa() -> void:
	print(1)

func execute_game_event(game_event_id: String) -> Dictionary:
	if not game_event_dictionary.has(game_event_id):
		print("未找{0}的事件".format([game_event_id]))
	return await game_event_dictionary[game_event_id].get_execution_result()
