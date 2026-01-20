extends Node


func _ready():
	EventBus.player_special_item_ids_updated.connect(_on_player_special_item_ids_updated)
	EventBus.reach_target.connect(_on_reach_target)
	pass

func _on_player_special_item_ids_updated(player_special_item_ids: String) -> void:
	print(player_special_item_ids)

func _on_reach_target(coordinate: Vector2i) -> void:
	var interaction_percent = 0.05
	if randf() < interaction_percent:
		EventBus.cell_interacted.emit(true)
	else:
		EventBus.cell_interacted.emit(false)
