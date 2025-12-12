class_name TypeUtil

#* 校验是否为数组/字典（合法集合类型）
static func is_valid_collection(data: Variant) -> bool:
	var data_type = typeof(data)
	#* 用 4.5 正确的 Variant 类型枚举
	return data_type in [TYPE_ARRAY, TYPE_DICTIONARY]

#* 校验并返回合法数组
static func get_valid_array(data: Variant, config_key: String) -> Array:
	if not is_valid_collection(data):
		push_warning("Config [%s] 非法，仅支持数组/字典" % config_key)
		return []
	if typeof(data) != TYPE_ARRAY:
		push_warning("Config [%s] 期望数组，实际非数组" % config_key)
		return []
	return data

#* 校验并返回合法字典
static func get_valid_dict(data: Variant, config_key: String) -> Dictionary:
	if not is_valid_collection(data):
		push_warning("Config [%s] 非法，仅支持数组/字典" % config_key)
		return {}
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Config [%s] 期望字典，实际非字典" % config_key)
		return {}
	return data

#* 新增：从字典中获取深层 key，校验其类型是否为目标类型
static func get_dict_child(parent_dict: Dictionary, parent_key: String, child_key: String, expected_type: int) -> Variant:
#* 先判断父字典是否有效
	if typeof(parent_dict) != TYPE_DICTIONARY:
		push_warning("父配置 [%s] 不是字典，无法获取子键 [%s]" % [parent_key, child_key])
		return null
	#* 安全获取子值
	var child_val = parent_dict.get(child_key, null)
	if child_val == null:
		push_warning("父配置 [%s] 中不存在子键 [%s]" % [parent_key, child_key])
		return null
	#* 校验子值类型
	if typeof(child_val) != expected_type:
		push_warning("父配置 [%s] 的子键 [%s] 类型错误，期望 %s" % [parent_key, child_key, expected_type])
		return null
	return child_val

#* 新增：顶层字典 + 深层子字段 一键校验获取
#* parent_key: 顶层配置名（如 "map_config"）
#* child_key: 深层子键（如 "atlas"）
#* expected_child_type: 子字段期望类型（如 TYPE_DICTIONARY）
static func get_dict_child_from_config(config_cache: Dictionary, parent_key: String, child_key: String, expected_child_type: int) -> Variant:
	#* 第一步：校验顶层配置是否为合法字典
	var parent_dict = get_valid_dict(config_cache.get(parent_key, {}), parent_key)
	if parent_dict.is_empty():
		return null
	#* 第二步：校验深层子字段类型
	var child_val = parent_dict.get(child_key, null)
	if child_val == null:
		push_warning("顶层配置 [%s] 中无深层子键 [%s]" % [parent_key, child_key])
		return null
	if typeof(child_val) != expected_child_type:
		push_warning("顶层配置 [%s] 的子键 [%s] 类型错误，期望 %s，实际 %s" % [parent_key, child_key, expected_child_type, typeof(child_val)])
		return null
	return child_val
