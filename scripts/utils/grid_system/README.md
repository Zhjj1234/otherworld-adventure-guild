# 网格系统 (Grid System)

一个纯逻辑的网格管理系统，支持多尺寸物体放置检测，与视图完全解耦，适用于2D/3D场景。

## 概述

本网格系统提供了一套完整的工具类，用于管理网格数据和物体放置逻辑。它采用数据驱动设计，与视图层完全分离，可灵活应用于各种游戏场景，如：
- 2D/3D地图编辑
- 物品放置系统
- 建筑系统
- 路径规划

## 实现思路

1. **数据驱动设计**：核心逻辑与视图完全解耦，仅处理数据关系
2. **模块化架构**：将网格系统拆分为多个独立的功能类，每个类负责单一职责
3. **高性能**：采用字典存储网格数据，支持O(1)时间复杂度的位置查询
4. **灵活扩展**：支持任意大小的网格和多尺寸物体放置
5. **清晰的API**：提供直观易用的方法，简化开发者使用

## 架构设计原则

### 核心原则：一个 GridSystem 实例 = 一个逻辑网格空间

**重要概念：**
- **GridSystem** 是纯逻辑层，只管理数据和规则，不涉及任何视图渲染
- **一个 GridSystem 实例可以管理多个区域（GridRegion）**，这些区域共享同一个数据空间
- 区域可以重叠，重叠部分的标识用 "&" 连接（如 "a&b"）
- 物体放置时，所有覆盖的格子必须属于同一个区域标识（不能跨区域放置）

### 典型使用场景

**场景：DraggableGrid（UI控件）**
```
DraggableGrid (一个实例)
├── GridSystem (一个实例，管理所有区域的数据)
├── GridRegionView (区域视图1，只负责显示)
├── GridRegionView (区域视图2，只负责显示)
└── SlotContainer (Slot容器，包含所有可拖拽物品)
```

**关键点：**
- 一个 DraggableGrid 只对应一个 GridSystem 实例
- 多个区域视图共享同一个 GridSystem，实现统一的数据管理
- Slot（可拖拽物品）可以在不同区域之间移动，因为它们共享同一个 GridSystem
- 区域视图只负责显示，不处理交互（mouse_filter=IGNORE）
- Slot 容器负责所有交互逻辑（mouse_filter=PASS）

### 设计层次

1. **逻辑层（GridSystem）**：纯数据管理，与视图完全解耦
2. **视图层（GridRegionView）**：负责区域的可视化显示
3. **交互层（DraggableGrid、DraggableSlot）**：处理用户交互和拖拽逻辑

## 核心类

### 1. GridPos
表示格子坐标的数据结构

**主要功能**：
- 存储格子的x和y坐标
- 支持与Vector2i的相互转换
- 支持相等比较

### 2. GridRect
表示物体占用区域的数据结构

**主要功能**：
- 存储区域的起始位置和大小
- 计算覆盖的所有格子坐标
- 检查是否包含某个格子

### 3. PlacementResult
表示放置结果的数据结构

**主要功能**：
- 存储放置是否成功
- 存储检测的区域
- 存储冲突的格子列表

### 4. GridSystem
核心网格管理类

**主要功能**：
- 管理网格数据
- 执行碰撞检测
- 处理物体放置和移除
- 查询网格状态

## 使用方式

### 1. 创建网格

```gdscript
# 创建一个10x10的网格
var grid = GridSystem.new(Vector2i(10, 10))
```

### 2. 检测物体是否可以放置

```gdscript
# 创建一个2x2的物体区域
var rect = GridRect.new(GridPos.new(0, 0), 2, 2)

# 检测是否可以放置
var result = grid.can_place(rect)

if result.is_valid:
    print("可以放置")
else:
    print("无法放置，冲突位置:", result.blocking_positions)
```

### 3. 放置物体

```gdscript
# 放置物体，存储物体数据
var success = grid.place(rect, "物体数据")

if success:
    print("放置成功")
else:
    print("放置失败")
```

### 4. 检查格子状态

```gdscript
# 检查某个格子是否为空
var is_empty = grid.is_cell_empty(GridPos.new(0, 0))

# 获取格子中的物体数据
var data = grid.get_cell_data(GridPos.new(0, 0))
```

### 5. 移除物体

```gdscript
# 移除指定区域的物体
grid.remove(rect)

# 清空整个网格
grid.clear()
```

### 6. 获取网格状态

```gdscript
# 获取所有被占用的格子
var occupied_positions = grid.get_all_occupied_positions()
```

## 示例代码

### 2D场景示例

```gdscript
# 创建一个10x10的网格
var grid = GridSystem.new(Vector2i(10, 10))

# 屏幕坐标转网格坐标
func screen_to_grid(screen_pos: Vector2, cell_size: int, cell_spacing: int) -> GridPos:
    var grid_x = int(screen_pos.x / (cell_size + cell_spacing))
    var grid_y = int(screen_pos.y / (cell_size + cell_spacing))
    return GridPos.new(grid_x, grid_y)

# 放置物体
func place_object_at_screen_pos(screen_pos: Vector2, object_size: Vector2i, object_data: Variant):
    var cell_size = 50
    var cell_spacing = 2
    
    var grid_pos = screen_to_grid(screen_pos, cell_size, cell_spacing)
    var rect = GridRect.new(grid_pos, object_size.x, object_size.y)
    
    var result = grid.can_place(rect)
    if result.is_valid:
        grid.place(rect, object_data)
        # 在2D场景中创建可视元素
        var object = preload("res://object.tscn").instantiate()
        object.position = Vector2(
            grid_pos.x * (cell_size + cell_spacing),
            grid_pos.y * (cell_size + cell_spacing)
        )
        add_child(object)
    else:
        # 显示冲突位置（例如绘制红色格子）
        for block_pos in result.blocking_positions:
            draw_conflict_cell(block_pos, cell_size, cell_spacing)
```

### 3D场景示例

```gdscript
# 创建一个10x10的网格
var grid_3d = GridSystem.new(Vector2i(10, 10))

# 世界坐标转网格坐标
func world_to_grid(world_pos: Vector3, cell_size: float) -> GridPos:
    var grid_x = int(world_pos.x / cell_size)
    var grid_y = int(world_pos.z / cell_size)  # 3D中通常用z轴表示深度
    return GridPos.new(grid_x, grid_y)

# 放置3D物体
func place_3d_object(world_pos: Vector3, object_size: Vector2i, object_data: Variant):
    var cell_size = 2.0
    
    var grid_pos = world_to_grid(world_pos, cell_size)
    var rect = GridRect.new(grid_pos, object_size.x, object_size.y)
    
    if grid_3d.place(rect, object_data):
        # 在3D场景中创建可视元素
        var object = preload("res://object_3d.tscn").instantiate()
        object.position = Vector3(
            grid_pos.x * cell_size,
            0,
            grid_pos.y * cell_size
        )
        get_tree().current_scene.add_child(object)
```

## 注意事项

1. **坐标系统**：
   - GridPos使用整数坐标，对应网格中的格子位置
   - 原点(0,0)位于网格的左上角

2. **性能优化**：
   - 对于大规模网格，建议限制get_all_occupied_positions()的调用频率
   - 可以根据需要实现缓存机制，减少重复计算

3. **线程安全**：
   - 本网格系统不是线程安全的，请勿在多线程环境中使用

4. **扩展性**：
   - 可以通过继承GridSystem类，添加自定义逻辑
   - 支持扩展GridPos、GridRect等类，添加额外的属性和方法

5. **Godot版本兼容**：
   - 仅支持Godot 4.5.1+
   - 遵循Godot 4.5.1最佳实践，使用class_name而非preload

## 版本信息

- **版本**：1.0.0
- **Godot版本**：4.5.1+
- **更新日期**：2026-01-26

## 测试

网格系统包含完整的测试脚本`test_grid_system.gd`，可直接在Godot中运行测试：

1. 将test_grid_system.gd挂载到场景节点上
2. 运行场景，查看控制台输出
3. 检查所有测试步骤是否通过

测试脚本包含以下测试内容：
- GridPos对象创建和转换
- GridRect对象创建和覆盖位置计算
- PlacementResult对象创建
- GridSystem核心功能测试
- 物体放置和检测
- 网格状态查询
- 物体移除和清空

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request，共同改进网格系统。