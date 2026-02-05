## 全局调试打印工具
## 提供带颜色、可开关的高级打印功能
extends RefCounted
class_name DebugPrint
## 调试总开关，false 时所有调试输出都会被静默
static var debug_enabled: bool = false
## 忽略路径列表，用于忽略某些路径的调试打印
static var caller_path_ignol_list: Array[String] = [
	"res://scenes/core/event_system/*",
	"res://scenes/core/inventory_system/*"
]

enum IS_PRINT {
	TRUE,
	FALSE
}

## 带颜色的调试打印
## message: 要打印的消息内容
## color_type: 颜色类型，默认为白色
## level: 日志级别，用于分类（INFO, WARNING, ERROR等）
static func print_debug(message: Variant,  caller_path: String = "", color: Color = Color.WHITE, level: String = "DEBUG") -> void:
	if not debug_enabled:
		return
	if not _check_caller_path(caller_path):
		return
	# 使用Godot 4.5推荐的print_rich函数实现彩色打印
	print_rich("[color={0}][{1}] {2}[/color]".format([color.to_html(), level, str(message)]))

## 简单打印，无颜色
## message: 要打印的消息内容
static func print_simple(message: Variant, caller_path: String = "", color: Color = Color.WHITE) -> void:
	if not debug_enabled:
		return
	if not _check_caller_path(caller_path):
		return
	print_rich("[color={0}]{1}[/color]".format([color.to_html(), message]))

static func _check_caller_path(caller_path: String) -> bool:
	# if caller_path == "":
	# 	return true
	if caller_path_ignol_list.any(func(element):
		if PathMatcher.match_dir(caller_path, element):
			return true
	):
		return false
	return true

## 信息级别打印（绿色）
static func print_info(message: Variant, caller_path: String = "") -> void:
	print_debug(message, caller_path, Color.GREEN, "INFO")

## 警告级别打印（黄色）
static func print_warning(message: Variant, caller_path: String = "") -> void:
	print_debug(message, caller_path, Color.YELLOW, "WARNING")

## 错误级别打印（红色）
static func print_error(message: Variant, caller_path: String = "") -> void:
	print_debug(message, caller_path, Color.RED, "ERROR")

## 成功级别打印（青色）
static func print_success(message: Variant, caller_path: String = "") -> void:
	print_debug(message, caller_path, Color.CYAN, "SUCCESS")
