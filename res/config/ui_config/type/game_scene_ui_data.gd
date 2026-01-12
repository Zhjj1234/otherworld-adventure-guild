#* 游戏场景UI数据类，定义单个UI的配置信息
extends Resource
class_name GameSceneUIData

#* UI的唯一标识符
@export var ui_id: String
#* UI的名称
@export var ui_name: String
#* UI资源的路径
@export var ui_path: String
#* UI所属的场景ID
@export var is_lazy_load: bool
#* 是否在加载场景时显示
@export var is_display_on_load: bool
#* 
@export var is_only_push: bool
#* UI所属的场景ID
@export var scene_id: String
