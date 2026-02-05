#* 网格区域视图
#* 管理单个区域的显示（背景、格子绘制）
#* 
#* ## 设计说明
#* 
#* **职责：**
#* - 负责单个区域的视觉显示（背景、格子、网格线）
#* - 不处理任何交互逻辑（mouse_filter = MOUSE_FILTER_IGNORE）
#* - 不管理数据，数据由 GridSystem 统一管理
#* 
#* **层级关系：**
#* - 作为 DraggableGrid 的子节点
#* - z_index = 0，在底层显示
#* - 多个 GridRegionView 可以共存，共享同一个 GridSystem
#* 
#* **重要：**
#* - GridRegionView 只是视图层，不包含任何逻辑
#* - 所有数据操作都通过父节点 DraggableGrid 的 GridSystem 进行
#* - 区域视图之间可以重叠，重叠部分由 GridSystem 管理标识
extends Control
class_name GridRegionView

#* 对应的区域数据
var region: GridRegion = null

#* 格子大小（像素）
var cell_size: int = 50

#* 格子间距
var cell_spacing: int = 2

#* 网格线颜色
var grid_line_color: Color = Color(0.3, 0.3, 0.3, 0.5)

#* 背景颜色
var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)

#* 是否为每个格子绘制背景（如果为 false 则只绘制网格线）
var show_cell_background: bool = true

#* 每格的背景颜色（在没有贴图时使用）
var cell_background_color: Color = Color(0.08, 0.08, 0.08, 1.0)

#* 可选的格子背景贴图（会平铺到每个格子）
var cell_background_texture: Texture2D

#* 构造函数
#* @param p_region 区域数据
#* @param p_cell_size 格子大小
#* @param p_cell_spacing 格子间距
func _init(p_region: GridRegion, p_cell_size: int = 50, p_cell_spacing: int = 2):
	self.region = p_region
	self.cell_size = p_cell_size
	self.cell_spacing = p_cell_spacing

func _ready() -> void:
	_update_size_and_position()

#* 更新视图的大小（不设位置）
#* 本 View 的 position 即该区域的视觉基准点（左上角），由父节点 DraggableGrid 通过 set_region_base_point 或 add_region 时设置
func _update_size_and_position() -> void:
	if region == null:
		return
	
	var width_px: int = region.width * (cell_size + cell_spacing) + cell_spacing
	var height_px: int = region.height * (cell_size + cell_spacing) + cell_spacing
	
	custom_minimum_size = Vector2(width_px, height_px)
	size = Vector2(width_px, height_px)
	clip_contents = true
	queue_redraw()

#* 设置区域数据
func set_region(p_region: GridRegion) -> void:
	region = p_region
	_update_size_and_position()

#* 绘制区域背景和格子
func _draw() -> void:
	if region == null:
		return
	
	# 绘制整体背景
	var total_size = Vector2(
		region.width * (cell_size + cell_spacing) + cell_spacing,
		region.height * (cell_size + cell_spacing) + cell_spacing
	)
	draw_rect(Rect2(Vector2.ZERO, total_size), background_color)
	
	# 绘制每个格子的背景（可选贴图或纯色）
	if show_cell_background:
		for grid_y in range(region.height):
			for grid_x in range(region.width):
				var pos = Vector2(
					grid_x * (cell_size + cell_spacing) + cell_spacing,
					grid_y * (cell_size + cell_spacing) + cell_spacing
				)
				var cell_rect_size = Vector2(cell_size, cell_size)
				var rect = Rect2(pos, cell_rect_size)
				if cell_background_texture:
					# 平铺贴图到格子矩形
					draw_texture_rect(cell_background_texture, rect, true)
				else:
					# 可以使用交替颜色提高可读性
					var shade = cell_background_color
					if ((grid_x + grid_y) % 2) == 0:
						shade = cell_background_color
					else:
						shade = cell_background_color.lightened(0.05)
					draw_rect(rect, shade)
	
	# 绘制网格线
	for x in range(region.width + 1):
		var x_pos = x * (cell_size + cell_spacing) + cell_spacing
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, region.height * (cell_size + cell_spacing) + cell_spacing),
			grid_line_color,
			1.0
		)
	
	for y in range(region.height + 1):
		var y_pos = y * (cell_size + cell_spacing) + cell_spacing
		draw_line(
			Vector2(0, y_pos),
			Vector2(region.width * (cell_size + cell_spacing) + cell_spacing, y_pos),
			grid_line_color,
			1.0
		)

#* 将格子坐标转换为屏幕位置（相对于区域视图）
func grid_to_screen(grid_pos: GridPos) -> Vector2:
	# 计算相对于区域起始位置的偏移
	var offset_x = grid_pos.x - region.pos.x
	var offset_y = grid_pos.y - region.pos.y
	return Vector2(
		offset_x * (cell_size + cell_spacing) + cell_spacing,
		offset_y * (cell_size + cell_spacing) + cell_spacing
	)

#* 将屏幕位置转换为格子坐标（相对于区域视图）
func screen_to_grid(screen_pos: Vector2) -> GridPos:
	var grid_x = int((screen_pos.x - cell_spacing) / (cell_size + cell_spacing))
	var grid_y = int((screen_pos.y - cell_spacing) / (cell_size + cell_spacing))
	# 转换为全局格子坐标
	return GridPos.new(region.pos.x + grid_x, region.pos.y + grid_y)
