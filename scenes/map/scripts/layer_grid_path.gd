#* 图层路径渲染器
#* 负责渲染可通行路径和不可通行路径的可视化显示
extends TileMapLayer
class_name LayerGridPath

#* 节点初始化函数
#* 在节点准备就绪时执行初始化操作
func _ready() -> void:
	pass


#* 渲染方向性路径
#* 根据可通行路径和消耗体力路径渲染可视化效果
#* @param passable_path: Array - 可通行路径坐标数组
#* @param costable_path: Array - 可移动路径坐标数组
func rend_directional(passable_path: Array, costable_path: Array):
	visible = true
	clear()
	for i in range(passable_path.size()):
		if i == 0:
			continue
		if i < costable_path.size():
			_set_passable(costable_path[i].position)
		else:
			_set_dis_passable(passable_path[i])


#* 设置可通行单元格
#* 在指定坐标位置设置可通行的路径图块
#* @param coords: Vector2i - 要设置的坐标
func _set_passable(coords: Vector2i) -> void:
	set_cell(coords, 0, Vector2i.ZERO)

#* 设置不可通行单元格
#* 在指定坐标位置设置不可通行的路径图块
#* @param coords: Vector2i - 要设置的坐标
func _set_dis_passable(coords: Vector2i) -> void:
	set_cell(coords, 0, Vector2i(1,0))
