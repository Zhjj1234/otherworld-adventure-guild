# Godot 4.5.1 事件系统 Core 模块

## 模块架构

本事件系统遵循黑盒化设计，包含以下核心组件：

1. **BaseEvent** - 事件基类，定义事件基础属性和方法
2. **EventParserExecutor** - 无状态工具类，解析和执行事件表达式
3. **EventNode** - 场景节点容器，管理事件表达式和绑定的事件实例
4. **EventFlowController** - 事件流程控制器，根据执行结果切换节点

## 功能特点

- **灵活的事件表达式**：支持 !（非）、|（互斥触发）、->（顺序触发）
- **互斥触发权重归一化**：自动计算权重，随机选择一个触发
- **顺序触发**：按表达式顺序依次执行，不跳过
- **低耦合设计**：模块间无循环依赖，可独立使用
- **无状态工具类**：EventParserExecutor 使用静态方法，不存储状态

## 使用示例

### 1. 创建自定义事件类

```gdscript
# 示例：创建两个自定义事件类
class_name TestEventA extends BaseEvent

func _execute() -> StringName:
	print("执行事件 A")
	return "SUCCESS"

class_name TestEventB extends BaseEvent

func _execute() -> StringName:
	print("执行事件 B")
	return "FAILURE"
```

### 2. 在场景中使用 EventNode

```gdscript
# 示例：在场景中挂载 EventNode 并测试

# 创建事件实例
var event_a = TestEventA.new("EventA", 1.0)
var event_b = TestEventB.new("EventB", 2.0)

# 获取 EventNode 节点
var event_node = $EventNode

# 设置事件表达式和绑定事件
event_node.event_expression = "EventA|EventB"
event_node.bound_events = [event_a, event_b]

# 执行并获取结果
var result = event_node.get_execution_result()
print("执行结果: %s" % result)
```

### 3. 测试不同的事件表达式

```gdscript
# 互斥触发：权重归一化，随机选择一个
var expr1 = "EventA|EventB"  # 权重 1:2，归一化后概率 33%:67%

# 顺序触发：按顺序依次执行
var expr2 = "EventA->EventB"  # 先执行 A，再执行 B

# 非操作：重置事件状态
var expr3 = "!EventA"  # 重置 EventA 状态

# 混合表达式：顺序+互斥
var expr4 = "EventA|EventB->!EventA"  # 先互斥触发 A 或 B，再重置 A
```

## 事件表达式语法

| 运算符 | 描述 | 示例 |
|--------|------|------|
| `!` | 非操作，重置事件状态 | `!A` |
| `|` | 互斥触发，权重归一化 | `A|B` |
| `->` | 顺序触发，按顺序执行 | `A->B` |

## 代码规范

- 类名使用 PascalCase
- 方法名使用 snake_case
- 关键方法添加注释，参数和返回值标注类型
- 避免全局变量
- 所有组件遵循数据驱动设计

## 安装说明

1. 将 `event_system` 目录复制到项目的 `addons/core/` 目录下
2. 在 Godot 编辑器中启用插件（如果需要）
3. 在场景中添加 `EventNode` 节点，或在代码中使用事件系统

## 版本兼容性

- Godot 4.5.1+
- GDScript 4.0+

## 扩展建议

- 添加事件编辑器插件，可视化编辑事件表达式
- 支持事件参数传递
- 添加事件监听器机制
- 支持事件条件判断
