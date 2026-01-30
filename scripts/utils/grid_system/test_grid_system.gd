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
	var result1 = PlacementResult.new(true, rect1, [pos1], "test_region")
	print("   PlacementResult.new(true, rect1, [pos1], 'test_region') =", result1)
	
	# 测试4: 创建GridSystem对象并测试核心功能
	print("\n4. 测试GridSystem对象创建和核心功能:")
	var grid = GridSystem.new()
	# 添加一个5x5的区域，标识为"main"
	grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 5, "main"))
	print("   创建了网格系统，添加了5x5的区域（标识: main）")
	
	# 测试can_place方法
	print("\n5. 测试can_place方法:")
	var test_rect = GridRect.new(GridPos.new(0, 0), 2, 2)
	var can_place_result = grid.can_place(test_rect)
	print("   检查在(0,0)放置2x2物体是否可行:", can_place_result.is_valid)
	
	# 测试place方法
	print("\n6. 测试place方法:")
	var place_result = grid.place(test_rect, "测试物体", can_place_result.region_id)
	print("   放置2x2物体:", place_result)
	print("   区域标识:", can_place_result.region_id)
	
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
	var clear_test_result = grid.can_place(test_rect)
	if clear_test_result.is_valid:
		grid.place(test_rect, "测试物体", clear_test_result.region_id)
	grid.clear()
	print("   清空网格后，检查(0,0)是否为空:", grid.is_cell_empty(GridPos.new(0, 0)))
	
	# 测试13: 测试can_place_or_find_nearby方法
	print("\n13. 测试can_place_or_find_nearby方法:")
	# 创建一个新的10x10网格用于测试
	var test_grid = GridSystem.new()
	test_grid.add_region(GridRegion.new(GridPos.new(0, 0), 10, 10, "test"))
	
	# 在中心位置放置一个2x2的物体，阻塞中心区域
	var center_rect = GridRect.new(GridPos.new(4, 4), 2, 2)
	var center_result = test_grid.can_place(center_rect)
	test_grid.place(center_rect, "中心物体", center_result.region_id)
	print("   在(4,4)位置放置了一个2x2的物体")
	
	# 测试在中心附近查找可放置位置
	var nearby_result = test_grid.can_place_or_find_nearby(GridPos.new(4, 4), 2, 2, 2)
	print("   在(4,4)附近查找2x2可放置位置:", nearby_result.is_valid)
	if nearby_result.is_valid:
		print("   找到的位置:", nearby_result.rect.pos, "区域标识:", nearby_result.region_id)
	
	# 测试14: 测试多区域功能
	print("\n14. 测试多区域功能:")
	var multi_grid = GridSystem.new()
	# 添加区域A：从(0,0)开始，5x5大小
	multi_grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 5, "region_a"))
	# 添加区域B：从(3,3)开始，5x5大小（与区域A有交集）
	multi_grid.add_region(GridRegion.new(GridPos.new(3, 3), 5, 5, "region_b"))
	print("   添加了区域A: (0,0) 5x5, 标识: region_a")
	print("   添加了区域B: (3,3) 5x5, 标识: region_b（与区域A有交集）")
	
	# 测试在区域A中放置
	var rect_a = GridRect.new(GridPos.new(0, 0), 2, 2)
	var result_a = multi_grid.can_place(rect_a)
	print("   在(0,0)放置2x2物体（区域A）:", result_a.is_valid, "区域标识:", result_a.region_id)
	
	# 测试在区域B中放置
	var rect_b = GridRect.new(GridPos.new(6, 6), 2, 2)
	var result_b = multi_grid.can_place(rect_b)
	print("   在(6,6)放置2x2物体（区域B）:", result_b.is_valid, "区域标识:", result_b.region_id)
	
	# 测试在交集区域放置（应该失败，因为标识不一致）
	var rect_intersect = GridRect.new(GridPos.new(3, 3), 3, 3)
	var result_intersect = multi_grid.can_place(rect_intersect)
	print("   在(3,3)放置3x3物体（跨区域A和B）:", result_intersect.is_valid)
	if not result_intersect.is_valid:
		print("   预期失败：因为跨区域，标识不一致")
	
	# 测试获取格子的区域标识
	print("\n15. 测试获取格子的区域标识:")
	print("   格子(0,0)的区域标识:", multi_grid.get_cell_region_id(GridPos.new(0, 0)))
	print("   格子(3,3)的区域标识:", multi_grid.get_cell_region_id(GridPos.new(3, 3)))
	print("   格子(6,6)的区域标识:", multi_grid.get_cell_region_id(GridPos.new(6, 6)))
	print("   格子(10,10)的区域标识（不在任何区域）:", multi_grid.get_cell_region_id(GridPos.new(10, 10)))
	
	print("\n=== 网格系统测试完成 ===")
	
	# 退出游戏
	get_tree().quit()
