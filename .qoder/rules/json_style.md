---
trigger: always_on
---
\## Global Pattern

res/\*\*/\*.json



\## Must Follow

\# 纯基础格式规则，适配你的4空格习惯+Godot解析

\- 缩进：强制4空格（按你习惯，和格式化插件保持一致）

\- 键名：统一snake\_case（如player\_hp，不写playerHp/PlayerHP）

\- 字符串：只用双引号"，禁用单引号'（Godot解析更稳）

\- 无尾逗号：对象/数组末尾禁止多余逗号（避免解析报错）

\- 类型统一：整数用int，小数用float（不写字符串型数字）

