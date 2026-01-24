extends Node


func _ready():
	EventBus.player_special_item_ids_updated.connect(_on_player_special_item_ids_updated)
	EventBus.reach_target.connect(_on_reach_target)
	pass

func _on_player_special_item_ids_updated(player_special_item_ids: String) -> void:
	print(player_special_item_ids)

func _on_reach_target(coordinate: Vector2i) -> void:
	var result = await EventManager.execute_game_event("on_reach_target")
	DebugPrint.print_simple(result["result"], get_script().resource_path, Color.DARK_ORCHID)
	if result["result"] == "INTERACTED":
		EventBus.cell_interacted.emit(true)
	else:
		EventBus.cell_interacted.emit(false)
	
