#* 验证结果类
#* 用于传递验证结果和详细信息
extends RefCounted
class_name ValidationResult

#* 验证是否成功
var success: bool = false

#* 错误信息（验证失败时使用）
var error_message: String = ""

#* 额外数据（验证成功时可能携带的信息，如交易金额等）
var extra_data: Dictionary = {}

#* 创建成功结果
static func ok(data: Dictionary = {}) -> ValidationResult:
	var result = ValidationResult.new()
	result.success = true
	result.extra_data = data
	return result

#* 创建失败结果
static func fail(message: String = "") -> ValidationResult:
	var result = ValidationResult.new()
	result.success = false
	result.error_message = message
	return result

#* 转换为布尔值
func to_bool() -> bool:
	return success
