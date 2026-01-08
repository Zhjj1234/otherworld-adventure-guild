extends BaseGameUI
class_name GameStartMenuUI

@onready var play_button: Button = %Play
@onready var option_button: Button = %Option
@onready var quit_button: Button = %Quit

func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	option_button.pressed.connect(_on_option_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	UiManager.push_ui("game_list_ui")

func _on_option_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
