extends Node2D

#* UI：加载进度文字
@onready var label: Label = $CanvasLayer/Label

#* 可选：给这次加载起个唯一 ID（方便以后取消加载之类的）
var load_id: String = ""

#* ------------------------------------------------------------------
#* 入口：点击“新游戏”按钮时调用
#* ------------------------------------------------------------------
func _on_new_game_pressed() -> void:
	label.text = "0%"
	label.show()
	
	## 开始异步加载所有资源，await 保证这里会等到全部加载完毕
	await SaveAndLoadManager._load_all(
		{
			"map_config": "res://res/config/map_config.json",
			"job_config": "res://res/config/job_config.json",
			"enemy_config": "res://res/config/enemy_config.json",
			"skill_config": "res://res/config/skill_config.json",
			"level_system_config": "res://res/config/level_system_config.json",
			"game_def_data": "res://res/game_data/game_def_data.json",
		},
		_update_progress_bar
	)
	
	#* print(GameDataManager.get_atlas_info())
	#* print(GameDataManager.game_data)
	#* #*  得到的JSON类型资源的data是一个Dictionary（字典）
	#* print(GameDataManager.game_data["def"].data)
	#* 加载完成后的收尾工作
	label.text = "100%"
	await get_tree().create_timer(0.3).timeout # 让玩家看到 100% 一小会儿
	label.hide()
	print("所有资源加载完成！")
	#print(JSON.stringify(GameDataManager._game_data, "  ", false))  # 美化打印
	#* 这里可以安全进入游戏主场景了
	get_tree().change_scene_to_file("res://scenes/main/game_main.tscn")

#* ------------------------------------------------------------------
#* 实时更新进度条（放在这里更清晰，_process 里就不用写了）
#* ------------------------------------------------------------------
func _update_progress_bar(_game_datas: Dictionary) -> void:
	var percent = int(SaveAndLoadManager.current_progress * 100)
	label.text = str(percent) + "%"
