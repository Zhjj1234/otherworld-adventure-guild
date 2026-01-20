extends Node2D
#* 玩家管理器类，负责管理玩家相关的功能和状态


#* 玩家移动管理器，用于控制玩家角色的移动
var player_movement_manager: PlayerMovementManager = null

func _on_player_movement_manager_registered(pmm: PlayerMovementManager):
	player_movement_manager = pmm

func set_player_position(pos: Vector2):
	player_movement_manager._set_player_position(pos)
