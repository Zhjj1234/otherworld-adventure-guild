extends Control

class_name BaseGameUI

@export var _default_focus_button: Button

func set_set_default_focus() -> void:
	if _default_focus_button:
		_default_focus_button.grab_focus()

func show_game_ui():
	show()

func hide_game_ui():
	hide()
