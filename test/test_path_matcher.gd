extends Node

# 测试PathMatcher工具类的脚本

func _ready():
	print("=== PathMatcher 测试开始 ===")
	
	# 调用PathMatcher的测试函数
	PathMatcher.test()
	
	print("=== PathMatcher 测试结束 ===")
	
	# 退出游戏
	get_tree().quit()
