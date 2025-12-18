extends Node

#*@onready var ground_layer_manager: GroundLayerManager = %GroundLayerManager
@onready var player_manager: PlayerManager = %PlayerManager
@onready var map_manager: Node2D = %MapManager

#* Called when the node enters the scene tree for the first time.
func init() -> void:
	pass

func _ready() -> void:
	player_manager.init() # * Initialize player manager
	MapLoaderManager.register_stage(map_manager) # * Register stage node
	MapLoaderManager.switch_map("res://scenes/map/tilemaps/map2.tscn")
	#tile_map_layers_manager.init() # * Initialize tile map layers manager
