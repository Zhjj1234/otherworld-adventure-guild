extends Node

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_game_back"):
		UIManager.pop_ui()
