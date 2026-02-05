extends Node

func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_game_cancel"):
		UIManager.pop_ui()
