extends Node

#* 网格系统测试脚本
#* 用于验证GridSystem及其相关类的功能是否正常

func _ready():
	print("=== 开始测试网格系统 ===")
	
	# 测试1: 创建GridPos对象
	print("\n1. 测试GridPos对象创建:")
	var pos1 = GridPos.new(1, 2)
	print("   GridPos.new(1, 2) =", pos1)
	
	var pos2 = GridPos.from_vector2i(Vector2i(3, 4))
	print("   GridPos.from_vector2i(Vector2i(3, 4)) =", pos2)
	
	print("   pos1.to_vector2i() =", pos1.to_vector2i())
	print("   pos1 == pos2 =", pos1 == pos2)
	
	# 测试2: 创建GridRect对象
	print("\n2. 测试GridRect对象创建:")
	var rect1 = GridRect.new(pos1, 2, 2)
	print("   GridRect.new(pos1, 2, 2) =", rect1)
	
	var covered = rect1.get_covered_positions()
	print("   rect1.get_covered_positions() =", covered)
	
	print("   rect1.contains(pos1) =", rect1.contains(pos1))
	print("   rect1.contains(pos2) =", rect1.contains(pos2))
	
	# 测试3: 创建PlacementResult对象
	print("\n3. 测试PlacementResult对象创建:")
	var result1 = PlacementResult.new(true, rect1, [pos1])
	print("   PlacementResult.new(true, rect1, [pos1]) =", result1)
	
	# 测试4: 创建GridSystem对象并测试核心功能
	print("\n4. 测试GridSystem对象创建和核心功能:")
	var grid = GridSystem.new(Vector2i(5, 5))
	print("   创建了5x5的网格")
	
	# 测试can_place方法
	print("\n5. 测试can_place方法:")
	var test_rect = GridRect.new(GridPos.new(0, 0), 2, 2)
	var can_place_result = grid.can_place(test_rect)
	print("   检查在(0,0)放置2x2物体是否可行:", can_place_result.is_valid)
	
	# 测试place方法
	print("\n6. 测试place方法:")
	var place_result = grid.place(test_rect, "测试物体")
	print("   放置2x2物体:", place_result)
	
	# 测试is_cell_empty方法
	print("\n7. 测试is_cell_empty方法:")
	print("   检查(0,0)是否被占用:", not grid.is_cell_empty(GridPos.new(0, 0)))
	print("   检查(4,4)是否被占用:", not grid.is_cell_empty(GridPos.new(4, 4)))
	
	# 测试get_cell_data方法
	print("\n8. 测试get_cell_data方法:")
	print("   获取(0,0)的数据:", grid.get_cell_data(GridPos.new(0, 0)))
	
	# 测试can_place方法（冲突情况）
	print("\n9. 测试can_place方法（冲突情况）:")
	var conflict_rect = GridRect.new(GridPos.new(1, 1), 2, 2)
	var conflict_result = grid.can_place(conflict_rect)
	print("   检查在(1,1)放置2x2物体是否可行:", conflict_result.is_valid)
	print("   冲突位置:", conflict_result.blocking_positions)
	
	# 测试get_all_occupied_positions方法
	print("\n10. 测试get_all_occupied_positions方法:")
	var occupied = grid.get_all_occupied_positions()
	print("   所有被占用的格子:", occupied)
	
	# 测试remove方法
	print("\n11. 测试remove方法:")
	grid.remove(test_rect)
	print("   移除2x2物体后，检查(0,0)是否为空:", grid.is_cell_empty(GridPos.new(0, 0)))
	
	# 测试clear方法
	print("\n12. 测试clear方法:")
	grid.place(test_rect, "测试物体")
	grid.clear()
	print("   清空网格后，检查(0,0)是否为空:", grid.is_cell_empty(GridPos.new(0, 0)))
	
	# 测试13: 测试find_nearest_valid_position方法
	print("\n13. 测试find_nearest_valid_position方法:")
	# 创建一个新的10x10网格用于测试
	var test_grid = GridSystem.new(Vector2i(10, 10))
	
	# 在中心位置放置一个2x2的物体，阻塞中心区域
	var center_rect = GridRect.new(GridPos.new(4, 4), 2, 2)
	test_grid.place(center_rect, "中心物体")
	print("   在(4,4)位置放置了一个2x2的物体")
	
	print("\n=== 网格系统测试完成 ===")
	
	# 退出游戏
	get_tree().quit()
