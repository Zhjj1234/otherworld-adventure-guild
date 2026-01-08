#* UI配置类，管理所有游戏场景UI的配置数据
extends Resource
class_name UIConfig

#* 游戏场景UI数据列表，存储所有UI的配置信息
@export var game_scene_ui_data_list: Array[GameSceneUIData]
