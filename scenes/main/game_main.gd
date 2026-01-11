extends BaseScene

func _ready():
	super._ready()
	_initizalize_game_state()
	print("GameMain: ready")

#* 初始化游戏状态，从存档数据中恢复玩家位置和地图
func _initizalize_game_state():
	var current_map_id = GameDataManager.get_player_current_map_id()  #* 获取当前地图ID
	var current_player_position = GameDataManager.get_player_current_position()  #* 获取玩家当前位置
	GameManager.switch_map(current_map_id, current_player_position)  #* 切换到存档时的地图和位置
