extends BaseGameUI

# 游戏数据管理器引用
var game_data_manager: Node

# UI组件引用
@onready var stamina_label: Label = %StaminaLabel
@onready var gold_label: Label = %GoldLabel

#* 初始化HUD组件和数据连接
func _ready() -> void:
	# 获取游戏数据管理器
	game_data_manager = get_node("/root/GameDataManager")
	GameDataManager.player_gold_updated.connect(_update_hud_display)
	GameDataManager.player_current_stamina_updated.connect(_update_hud_display)
	
	# 连接数据更新信号
	game_data_manager.current_game_cache_updated.connect(_on_game_data_updated)
	
	# 初始化显示
	_update_hud_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_game_menu"):
		# 确认键被按下
		_open_game_main_menu()

func _open_game_main_menu() -> void:
	UIManager.push_ui("game_main_menu")

#* 游戏数据更新时的回调函数
func _on_game_data_updated() -> void:
	_update_hud_display()

#* 更新HUD显示数据
func _update_hud_display() -> void:
	# 获取当前体力值
	var current_stamina = game_data_manager.get_player_current_stamina()
	# 获取当前金币值
	var current_gold = game_data_manager.get_player_gold()
	
	# 更新UI显示
	stamina_label.text = "Stamina: %d" % current_stamina
	gold_label.text = "Gold: %d" % current_gold
