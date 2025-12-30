extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var a: GameData = load("res://res/game_data/tres/def_game_data/def_game_data.tres")
	print(a.player_global_data.current_map_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
