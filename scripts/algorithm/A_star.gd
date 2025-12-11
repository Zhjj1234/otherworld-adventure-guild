extends Node
#* A*寻路算法
class_name AStart

#* A*寻路算法实现
var _is_passable_grid_inner: Callable = func(_coords: Vector2i) -> bool: return true

#* 设置是否可通过的函数
func set_is_passable_grid_inner(fun: Callable):
	_is_passable_grid_inner = fun

#* 实现A*寻路算法
func find_path(start: Vector2i, end: Vector2i, step: int, return_closest_on_fail: bool = false) -> Array:
	var open_list: Array = []
	var closed_list: Array = []
	
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	var came_from: Dictionary = {}
	
	#* --- 修改点 1: 使用 H (曼哈顿距离) 而不是 F score 来跟踪最近节点 ---
	var closest_node: Vector2i = start
	#* 记录当前找到的最小距离
	var min_distance_to_target: int = _calculate_heuristic(start, end)
	
	g_score[start] = 0
	f_score[start] = _calculate_heuristic(start, end)
	open_list.append(start)
	
	while not open_list.is_empty():
		var current: Vector2i = _get_lowest_f_score_node(open_list, f_score)
		
		if current == end:
			return _reconstruct_path(came_from, current)
		
		open_list.erase(current)
		closed_list.append(current)
		
		for neighbor in _get_neighbors(current):
			if neighbor in closed_list:
				continue
			
			if not _is_passable_grid(neighbor):
				continue
				
			var tentative_g_score: int = g_score[current] + 1
			
			#* --- 修改点 2: 严格处理步长限制 ---
			#* 如果超出步长，直接跳过。既然走不到，就不应该将其视为"最近的可达点"
			if tentative_g_score > step:
				continue
			
			#* 标准 A* 更新逻辑
			if not (neighbor in open_list) or tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				#* H score: 当前点到终点的距离
				var h_score = _calculate_heuristic(neighbor, end)
				f_score[neighbor] = tentative_g_score + h_score
				
				if not (neighbor in open_list):
					open_list.append(neighbor)
				
				#* --- 修改点 3: 更新最近节点逻辑 ---
				#* 只有当这个点确实比之前的点离终点更近（H值更小）时，才更新
				#* 这里使用 <= 可以在距离相等时更新为更深层的节点，路径看起来更自然
				if return_closest_on_fail and h_score < min_distance_to_target:
					min_distance_to_target = h_score
					closest_node = neighbor
	
	#* 无法到达终点
	if return_closest_on_fail:
		#* 只有当确实找到了比起点更近的点，且该点不是起点时
		if closest_node != start:
			return _reconstruct_path(came_from, closest_node)
		#* 如果真的哪里都去不了（周围全是墙），至少返回起点
		return [start]
	
	return []

#* 计算启发式函数（曼哈顿距离）
func _calculate_heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

#* 获取f_score最低的节点
func _get_lowest_f_score_node(nodes: Array, f_score: Dictionary) -> Vector2i:
	var lowest: Vector2i = nodes[0]
	var lowest_score = f_score[lowest]
	
	#* 优化一点性能，避免多次字典查找
	for i in range(1, nodes.size()):
		var node = nodes[i]
		var score = f_score[node]
		if score < lowest_score:
			lowest = node
			lowest_score = score
	return lowest

#* 获取相邻节点
func _get_neighbors(node: Vector2i) -> Array:
	return [
		Vector2i(node.x + 1, node.y),
		Vector2i(node.x - 1, node.y),
		Vector2i(node.x, node.y + 1),
		Vector2i(node.x, node.y - 1)
	]

#* 重构路径
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

#* 检查网格是否可通过 (示例)
func _is_passable_grid(coords: Vector2i) -> bool:
	return _is_passable_grid_inner.call(coords)
