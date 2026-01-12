extends BaseGameUI

# UI组件引用
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var return_to_main_button: Button = %ReturnToMainButton

#* 初始化主菜单界面
func _ready() -> void:
	# 连接按钮的按下信号
	continue_button.pressed.connect(_on_continue_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	return_to_main_button.pressed.connect(_on_return_to_main_button_pressed)

#* 继续游戏按钮按下时的回调函数
func _on_continue_button_pressed() -> void:
	UIManager.pop_ui()
	# 这里可以添加继续游戏的逻辑

#* 选项按钮按下时的回调函数
func _on_options_button_pressed() -> void:
	print("选项按钮被按下")
	# 这里可以添加打开选项菜单的逻辑

#* 返回主菜单按钮按下时的回调函数
func _on_return_to_main_button_pressed() -> void:
	SceneManager.change_scene("game_start")
	# 这里可以添加返回主菜单的逻辑
