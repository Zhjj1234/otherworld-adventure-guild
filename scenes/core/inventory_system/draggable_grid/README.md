# DraggableGrid 说明

## 1. 原则
- 逻辑与视图分离：GridSystem 只管放置与占用，视图只负责显示与交互。
- 多区域共享：一个 DraggableGrid 对应一个 GridSystem，可包含多个区域视图。
- 交互统一：槽位（Button）通过激活信号进行拾取/放置，支持鼠标与键盘/手柄输入。

## 2. 核心概念：逻辑坐标 vs 视觉位置

### 2.1 逻辑坐标（GridPos）
- **作用**：用于 GridSystem 的碰撞检测、物品放置、区域管理
- **坐标空间**：统一的逻辑网格空间，所有区域共享
- **关键规则**：**多个区域必须使用不同的逻辑坐标，否则会在逻辑空间中重叠**
- **示例**：如果背包A从 (0,0) 开始，背包B应该从 (5,0) 开始（假设背包宽度为5）

### 2.2 视觉位置（set_region_base_point）
- **作用**：控制区域视图在屏幕上的显示位置（像素坐标）
- **坐标空间**：相对于 DraggableGrid 的本地像素坐标
- **用途**：允许在视觉上自由排列区域（如左上、右上、左下、右下）
- **注意**：**视觉位置不影响逻辑坐标，只影响显示位置**

### 2.3 坐标转换
- `grid_to_screen()`：将逻辑坐标转换为屏幕像素位置
- `screen_to_grid()`：将屏幕像素位置转换为逻辑坐标
- 转换时会自动考虑区域视图的视觉位置

### 2.4 常见错误示例

```gdscript
# 错误：所有区域使用相同的逻辑坐标 (0,0)
inventory_grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 3, "backpack_1"))
inventory_grid.set_region_base_point("backpack_1", Vector2(10, 10))

inventory_grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 3, "backpack_2"))  # 逻辑坐标重叠！
inventory_grid.set_region_base_point("backpack_2", Vector2(320, 10))  # 只改了视觉位置
```

**问题**：拖拽物品到背包2时，会回到背包1，因为它们在逻辑空间中是同一个位置。

```gdscript
# 正确：每个区域使用不同的逻辑坐标
inventory_grid.add_region(GridRegion.new(GridPos.new(0, 0), 5, 3, "backpack_1"))
inventory_grid.set_region_base_point("backpack_1", Vector2(10, 10))

inventory_grid.add_region(GridRegion.new(GridPos.new(5, 0), 5, 3, "backpack_2"))  # 逻辑坐标独立
inventory_grid.set_region_base_point("backpack_2", Vector2(320, 10))  # 视觉位置自由设置
```

## 3. 使用
1. 创建 DraggableGrid 并添加区域：
   - 通过 `initial_regions` 配置，或调用 `add_region()` 动态添加。
   - **重要**：为每个区域分配独立的逻辑坐标（GridPos）
2. 添加槽位：
   - 调用 `add_slot(size, position, color)`，或让系统自动寻找空位。
3. 交互方式：
   - 点击/激活槽位：拾取；再次点击/激活：放置。
   - 目标位置仅覆盖一个槽位时会交换；覆盖多个槽位则放置失败并保持手持。
4. 可调参数：
   - `cell_size`、`cell_spacing`：格子尺寸与间距。
   - `place_search_range`：放置搜索范围，默认 0（仅精确放置或交换）。

## 4. 应用场景
- 背包/仓库 UI（暗黑式背包、网格化物品摆放）
- 物品拖拽与交换系统
- 多区域共享逻辑的网格管理界面（例如左右背包、角色与仓库）

## 5. 多区域布局示例

```gdscript
# 创建 4 个背包，每个 5x3 格
var backpack_width = 5
var backpack_height = 3

# 背包1：左上 - 逻辑坐标(0, 0)，视觉位置(10, 10)
inventory_grid.add_region(GridRegion.new(GridPos.new(0, 0), backpack_width, backpack_height, "backpack_1"))
inventory_grid.set_region_base_point("backpack_1", Vector2(10, 10))

# 背包2：右上 - 逻辑坐标(5, 0)，视觉位置(320, 10)
inventory_grid.add_region(GridRegion.new(GridPos.new(backpack_width, 0), backpack_width, backpack_height, "backpack_2"))
inventory_grid.set_region_base_point("backpack_2", Vector2(320, 10))

# 背包3：左下 - 逻辑坐标(0, 3)，视觉位置(10, 240)
inventory_grid.add_region(GridRegion.new(GridPos.new(0, backpack_height), backpack_width, backpack_height, "backpack_3"))
inventory_grid.set_region_base_point("backpack_3", Vector2(10, 240))

# 背包4：右下 - 逻辑坐标(5, 3)，视觉位置(320, 240)
inventory_grid.add_region(GridRegion.new(GridPos.new(backpack_width, backpack_height), backpack_width, backpack_height, "backpack_4"))
inventory_grid.set_region_base_point("backpack_4", Vector2(320, 240))
```
