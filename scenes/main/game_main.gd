extends Node

#*@onready var ground_layer_manager: GroundLayerManager = %GroundLayerManager
@onready var player_manager: PlayerManager = %PlayerManager
@onready var tile_map_layers_manager: Node2D = %TileMapLayersManager

#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_manager.init() # * Initialize player manager
	tile_map_layers_manager.init() # * Initialize tile map layers manager
	pass
