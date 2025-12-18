---
trigger: glob
glob: scripts/**/*.gd, scenes/**/*.gd
---
\# Godot GDScript 编码规范

\## 版本适配（Godot 4.5 专属）

\- ✅ 节点生命周期函数使用 `\_ready()` `\_process(delta)` `\_physics\_process(delta)`，禁用 3.x 旧函数（如 `\_init()` 仅用于变量初始化）

\- ✅ 信号连接优先用 `connect()` 方法或 `@onready` 注解，避免 `signal.connect()` 链式调用的过时写法

\- ✅ 使用 Godot 4.5 新增的 `@export var` 替代 `export var` 旧语法，支持更丰富的编辑器序列化特性

\- ✅ 场景实例化用 `load()` + `instantiate()`，禁用 3.x 的 `instance()` 方法

\- ✅ 适配 4.5 节点树变更，如 `CanvasLayer` 层级管理、`Node3D` 坐标系统（Y轴向上）



\## 命名规范

\- ✅ 类名：PascalCase（如 MapAnchorService）

\- ✅ 函数/变量：snake\_case（如 get\_teleport\_point）

\- ✅ 常量：UPPER\_SNAKE\_CASE（如 DEFAULT\_SPAWN\_POINT）



\## 节点交互规范

\- ✅ 节点通信优先用 \*\*signal 信号\*\*，禁止硬编码 get\_node 跨层级访问

\- ✅ 场景内节点通过 $ 引用，跨场景节点通过全局服务类代理

\- ✅ 避免在 \_ready() 外直接操作节点属性，需封装为 setter/getter 方法



\## 性能约束

\- ✅ 避免在 \_process() 里执行复杂计算，高频逻辑放 \_physics\_process()

\- ✅ 锚点坐标查询需缓存结果，避免重复读取配置文件

