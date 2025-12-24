extends Node2D
#* 地图管理器类，负责管理游戏中的地图切换和相关功能
class_name MapManager

#* 地图管理器注册信号
signal map_manager_registered(map_manager: MapManager)

#* 地图管理器 - 负责管理地图相关的功能
var _tile_map_layers_manager: TileMapLayersManager = null  #* 图块地图图层管理器实例
@onready var layer_grid_path: LayerGridPath = %LayerGridPath
@onready var player_manager: PlayerManager = %PlayerManager

#* 初始化函数，连接信号和事件
func _ready():
	EventBus.position_cell_changed.connect(check_player_current_cell)  #* 连接到玩家位置变化事件
	map_manager_registered.connect(GameManager.on_map_manager_registered)  #* 连接到游戏管理器的注册函数
	map_manager_registered.connect(MapLoaderManager.on_map_manager_registered)  #* 连接到地图加载管理器的注册函数
	map_manager_registered.emit(self)  #* 发出注册信号

func _on_player_manager_ready() -> void:
	player_manager.player_movement_manager.button_coords_changed.connect(layer_grid_path.rend_directional)
	player_manager.player_movement_manager.move_status_changed.connect(_on_player_movement_manager_move_status_changed)
	
#* 切换到指定ID的地图
func switch_map(map_id: String) -> void:
	var map_path = GameDataManager.get_map_info_by_id(map_id).path  #* 获取地图路径
	MapLoaderManager.switch_map(map_path)  #* 通过地图加载管理器切换地图

#* 检查玩家当前所在的网格单元
func check_player_current_cell(player_coords) -> void:
	print("player_coords", player_coords)  #* 打印玩家坐标信息

#* 节点从场景树中移除时清理连接
func _exit_tree() -> void:
	map_manager_registered.disconnect(GameManager.on_map_manager_registered)  #* 断开与游戏管理器的连接
	map_manager_registered.disconnect(MapLoaderManager.on_map_manager_registered)  #* 断开与地图加载管理器的连接
	EventBus.position_cell_changed.disconnect(check_player_current_cell)  #* 断开玩家位置变化事件监听
	player_manager.player_movement_manager.button_coords_changed.disconnect(layer_grid_path.rend_directional)

#* 当图块地图图层管理器注册时调用
func on_tile_map_layers_manager_registered(tile_map_layers_manager: TileMapLayersManager):
	_tile_map_layers_manager = tile_map_layers_manager  #* 保存图层管理器引用

func get_tile_stamina_cost(coords: Vector2i) -> float:
	return _tile_map_layers_manager.get_tile_move_cost(coords)

func _on_player_movement_manager_move_status_changed(status: PlayerMovementManager.MOVE_STATUS) -> void:
	if status == PlayerMovementManager.MOVE_STATUS.MOVING:
		layer_grid_path.visible = false
