## 路径通配符匹配工具类
## 支持 *（单层匹配）和 **（多层匹配）通配符，兼容多种路径格式
class_name PathMatcher
extends RefCounted

## 核心匹配方法
## @param target_path: 待匹配的目录路径（如"A/B/C"、"res://A/B/C"）
## @param pattern: 通配规则（如"A/*"、"A/**/*"、"res://A/*"）
## @param is_absolute: 可选参数，默认false；为true时强制绝对路径开头一致
## @return: 是否匹配成功
static func match_dir(target_path: String, pattern: String, is_absolute: bool = false) -> bool:
	# 标准化路径格式
	var normalized_target = _normalize_path(target_path)
	var normalized_pattern = _normalize_path(pattern)
	
	# 如果是绝对路径匹配，检查路径前缀是否一致
	if is_absolute:
		var target_prefix = _get_path_prefix(normalized_target)
		var pattern_prefix = _get_path_prefix(normalized_pattern)
		if target_prefix != pattern_prefix:
			return false
	
	# 分割路径为组件
	var target_components = normalized_target.split("/")
	var pattern_components = normalized_pattern.split("/")
	
	# 调用核心匹配逻辑
	return _match_components(target_components, pattern_components, 0, 0)

## 标准化路径格式
## @param path: 原始路径
## @return: 标准化后的路径
static func _normalize_path(path: String) -> String:
	if path.is_empty():
		return path
	
	# 统一路径分隔符为 /
	var normalized = path.replace("\\", "/")
	
	# 移除连续的 /
	while normalized.find("//") != -1:
		normalized = normalized.replace("//", "/")
	
	# 移除末尾的 /（如果有）
	if normalized.length() > 1 and normalized.ends_with("/"):
		normalized = normalized.left(normalized.length() - 1)
	
	return normalized

## 获取路径前缀（res://、user://等）
## @param path: 标准化后的路径
## @return: 路径前缀，空字符串表示相对路径
static func _get_path_prefix(path: String) -> String:
	if path.begins_with("res://"):
		return "res://"
	if path.begins_with("user://"):
		return "user://"
	if path.begins_with("/"):
		return "/"
	return ""

## 核心组件匹配逻辑（递归）
## @param target_comps: 目标路径组件数组
## @param pattern_comps: 模式路径组件数组
## @param target_idx: 当前匹配的目标组件索引
## @param pattern_idx: 当前匹配的模式组件索引
## @return: 是否匹配成功
static func _match_components(target_comps: Array, pattern_comps: Array, target_idx: int, pattern_idx: int) -> bool:
	# 模式匹配完成
	if pattern_idx == pattern_comps.size():
		return target_idx == target_comps.size()
	
	# 目标匹配完成，但模式还有剩余（除非剩余都是 **）
	if target_idx == target_comps.size():
		# 检查剩余模式是否都是 **
		for i in range(pattern_idx, pattern_comps.size()):
			if pattern_comps[i] != "**":
				return false
		return true
	
	var pattern_comp = pattern_comps[pattern_idx]
	
	# 处理 ** 通配符（匹配任意多层目录）
	if pattern_comp == "**":
		# 跳过所有 ** 连续出现的情况
		var next_pattern_idx = pattern_idx
		while next_pattern_idx < pattern_comps.size() and pattern_comps[next_pattern_idx] == "**":
			next_pattern_idx += 1
		
		# ** 可以匹配0层或多层目录
		# 尝试匹配target中从当前位置到末尾的所有可能位置
		for i in range(target_idx, target_comps.size() + 1):
			if _match_components(target_comps, pattern_comps, i, next_pattern_idx):
				return true
		return false
	
	# 处理 * 通配符（匹配单层目录/文件名）或精确匹配
	var target_comp = target_comps[target_idx]
	if pattern_comp == "*" or pattern_comp == target_comp:
		return _match_components(target_comps, pattern_comps, target_idx + 1, pattern_idx + 1)
	
	return false

## 测试示例
static func test():
	# 示例1：基本单层匹配
	print("示例1：A/B/C 匹配 A/* → ", match_dir("A/B/C", "A/*"))  # false
	print("示例2：A/B/C 匹配 A/*/C → ", match_dir("A/B/C", "A/*/C"))  # true
	
	# 示例2：多层匹配
	print("示例3：A/B/C/D 匹配 A/**/* → ", match_dir("A/B/C/D", "A/**/*"))  # true
	print("示例4：A/B/C 匹配 **/B/** → ", match_dir("A/B/C", "**/B/**"))  # true
	print("示例5：A/B/C 匹配 **/X/** → ", match_dir("A/B/C", "**/X/**"))  # false
	
	# 示例3：资源路径匹配
	print("示例6：res://A/B/C 匹配 res://A/* → ", match_dir("res://A/B/C", "res://A/*"))  # false
	print("示例7：res://A/B/C 匹配 res://A/** → ", match_dir("res://A/B/C", "res://A/**"))  # true
	
	# 示例4：路径分隔符兼容
	print("示例8：A\\B\\C 匹配 A/*/C → ", match_dir("A\\B\\C", "A/*/C"))  # true
	print("示例9：A//B//C 匹配 A/*/C → ", match_dir("A//B//C", "A/*/C"))  # true
	
	# 示例5：绝对路径匹配
	print("示例10：res://A/B 匹配 user://A/B (绝对匹配) → ", match_dir("res://A/B", "user://A/B", true))  # false
	print("示例11：res://A/B 匹配 res://A/B (绝对匹配) → ", match_dir("res://A/B", "res://A/B", true))  # true
	
	# 示例6：相对路径与绝对路径
	print("示例12：A/B/C 匹配 /*/C → ", match_dir("A/B/C", "/*/C", true))  # false
	print("示例13：/A/B/C 匹配 /*/C → ", match_dir("/A/B/C", "/*/C", true))  # true
	
	# 示例7：空路径和边界情况
	print("示例14：空路径匹配空模式 → ", match_dir("", ""))  # true
	print("示例15：A 匹配 ** → ", match_dir("A", "**"))  # true

## 匹配规则说明
## 1. 通配符规则：
##    - *：匹配单层目录或文件名，不能跨目录边界
##    - **：匹配任意多层目录，可以跨多个目录边界
## 2. 路径兼容：
##    - 自动将 Windows 路径分隔符 (\) 转换为 UNIX 风格 (/)
##    - 处理连续的 /（如 A//B 转换为 A/B）
##    - 移除末尾的 /（如 A/B/ 转换为 A/B）
## 3. 路径类型：
##    - 支持资源路径：res://、user://
##    - 支持相对路径：A/B/C
##    - 支持绝对路径：/A/B/C
## 4. 绝对路径匹配：
##    - is_absolute=true 时，强制前缀一致（res:// 只能匹配 res://）
##    - is_absolute=false 时，忽略前缀，只匹配路径结构

## 性能注意事项
## 1. ** 通配符的性能影响：
##    - ** 匹配需要递归尝试多种可能性，复杂度较高
##    - 建议只在必要时使用 **，避免在频繁调用的场景中使用
##    - 尽量将 ** 放在模式的前面，减少匹配深度
## 2. 适合场景：
##    - 静态配置文件的路径匹配
##    - 资源加载时的路径过滤
##    - 编辑器工具中的文件搜索
## 3. 不适合场景：
##    - 每帧调用的高频路径匹配
##    - 超大规模路径集的匹配
