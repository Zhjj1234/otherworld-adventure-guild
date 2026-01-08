extends Node

## Save path
var save_path: String = "user://save/"
var meta_data_path: String = "user://save/meta_data.json"

#* Slot metadata
var _slot_metadata_cache: Dictionary = {
	"slot_1": {"is_used":false, "save_name": "", "timestamp":0},
	"slot_2": {"is_used":false, "save_name": "", "timestamp":0},
	"slot_3": {"is_used":false, "save_name": "", "timestamp":0}
}

func _ready() -> void:
	ObjectSerializer.register_script("GameData", GameData)
	ObjectSerializer.register_script("PlayerGlobalData", PlayerGlobalData)
	ObjectSerializer.register_script("Character", Character)
	#* 初始化槽位元数据缓存
	_update_slot_metadata_cache_from_local()
	pass

#* Update slot metadata cache from local storage
func _update_slot_metadata_cache_from_local() -> void:
	var json_string = _load_json_from_file(meta_data_path)
	if json_string == "":
		return
	_slot_metadata_cache = JSON.parse_string(json_string)

#* Populate current game cache with save meta data
func _update_slot_metadata_cache_current_game(slot_id: int) -> void:
	_slot_metadata_cache["slot_" + str(slot_id)] = {
		"is_used": true,
		"save_name": GameDataManager._current_game_cache.save_name,
		"timestamp": GameDataManager._current_game_cache.timestamp
	}

#* Get slot metadata
func _get_slot_metadata(slot: int) -> Dictionary:
	var slot_key = "slot_" + str(slot)
	if _slot_metadata_cache.has(slot_key):
		return _slot_metadata_cache[slot_key]
	else:
		return {"is_used": false, "save_name": "", "timestamp": 0}

## Start a game
func start_game(slot_id: int) -> void:
	var slot_data = _get_slot_metadata(slot_id)

	if slot_data.is_used:
		#* 加载现有游戏
		_load_existing_game(slot_id)
	else:
		#* 加载新游戏
		_load_game(slot_id)

#* Load a new game
func _load_game(slot_id: int) -> void:
	GameDataManager.set_current_game_data(GameDataManager.get_default_game_data_duplicate())
	save_current_game(slot_id)
	SceneManager.to_game_main_scene()
	pass

#* Load an existing game
func _load_existing_game(slot_id: int) -> void:
	var game_data = load_game_from_slot(slot_id)
	if game_data:
		GameDataManager.set_current_game_data(game_data)
		SceneManager.to_game_main_scene()
	else:
		print("Failed to load game from slot: " + str(slot_id))

## Save the current game
func save_current_game(slot_id: int) -> void:
	#* 更新槽位元数据缓存
	_populate_current_game_cache_save_meta_data(slot_id)
	_update_slot_metadata_cache_current_game(slot_id)
	#* 保存槽位元数据缓存
	_save_json_to_file(JSON.stringify(_slot_metadata_cache), meta_data_path)
	#* 序列化当前游戏数据
	var json = DictionarySerializer.serialize_json(GameDataManager._current_game_cache)
	var file_path = _slot_dict_to_file_path(slot_id)
	#* 将json数据写入文件
	_save_json_to_file(json, file_path)

## Load game from slot
func load_game_from_slot(slot_id: int) -> GameData:
	#* 从文件加载json数据
	var json = _load_json_from_file(_slot_dict_to_file_path(slot_id))
	#* 反序列化json数据到当前游戏数据缓存
	return DictionarySerializer.deserialize_json(json)

#* Convert slot dict to file path
func _slot_dict_to_file_path(slot_id: int) -> String:
	return save_path + "save_" + str(slot_id) + ".json"

#* save json to file GODOT 4.5 API
func _save_json_to_file(json: String, file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(json)
	file.close()

#* load json from file GODOT 4.5 API
func _load_json_from_file(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var json = file.get_as_text()
	file.close()
	return json

#* Populate current game cache with save meta data
func _populate_current_game_cache_save_meta_data(slot_id: int) -> void:
	GameDataManager._current_game_cache.save_name = GameDataManager._current_game_cache.player_global_data.game_progress
	GameDataManager._current_game_cache.timestamp = round(Time.get_unix_time_from_system())
	GameDataManager._current_game_cache.slot_id = slot_id
