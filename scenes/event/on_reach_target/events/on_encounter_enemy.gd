extends BaseEvent
class_name OnEncounterEnemy

func _execute() -> StringName:
	print("[",name, "]execute")
	await get_tree().create_timer(2).timeout
	return "INTERACTED"
