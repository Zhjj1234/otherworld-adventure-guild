extends Node



var _slot_metadata_cache: Dictionary = {
	"slot_1": {"is_used":false, "save_name": "", "timestamp":0},
	"slot_2": {"is_used":false, "save_name": "", "timestamp":0},
	"slot_3": {"is_used":false, "save_name": "", "timestamp":0}
}

func load_new_game(slot: int) -> void:
	GameDataManager._current_game_cache = GameDataManager._default_game_cache.duplicate(true)
	# TODO init _slot_metadata_cache
	pass

func load_existing_game(slot: int) -> void:
	pass

func _ready() -> void:
	pass
