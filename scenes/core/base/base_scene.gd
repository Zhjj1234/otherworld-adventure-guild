extends Node
class_name BaseScene

func _ready() -> void:
	_ui_init()

func _ui_init() -> void:
	UiManager.load_uis(SceneManager.get_current_scene_id())
