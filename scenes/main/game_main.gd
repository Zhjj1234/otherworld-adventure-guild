extends Node

#*@onready var ground_layer_manager: GroundLayerManager = %GroundLayerManager
@onready var player_manager: PlayerManager = %PlayerManager
@onready var map_manager: MapManager = %MapManager

func _ready():
	GameManager.initizalize_game_state()
