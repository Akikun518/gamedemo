# AGENTS.md —— 给 Codex 的项目说明（每次开工前先读）

这是 Godot 4.7.2 的赛博朋克酒吧 + 佣兵派遣游戏原型。玩家是开发小白，请始终用简单直白的中文交流。

## 最重要的规则：不要主动使用 superpowers 系列技能

本项目采用"小步直接改"的开发方式。**用户没有明确要求时，不要调用 superpowers 插件提供的任何技能**，包括但不限于：

- brainstorming（头脑风暴）
- writing-plans / executing-plans（写计划 / 执行计划）
- test-driven-development（测试驱动开发）
- verification-before-completion / requesting-code-review（验收检查 / 代码评审）
- subagent-driven-development / dispatching-parallel-agents（派子代理）
- using-superpowers / using-git-worktrees / finishing-a-development-branch（流程强制 / 工作树 / 收尾流程）

同时不要新增 `docs/superpowers/` 设计文档或实施计划，不要为此创建分支或工作树。

**唯一例外**：用户明确说"走计划流程"或"写设计文档"时，才按用户要求执行。

## 日常开发方式（默认）

1. 常规、重复性的改动（添加 JSON 内容、改 UI 文字、改小脚本）：**直接改，不写任何文档和计划**。
2. 改动前先读对应 `data/` 目录下的 README，按已有格式添加内容；GDScript 里不要硬编码任务 ID。
3. 改完做最小验证（见下方命令），确认没弄坏现有功能即可；除非用户要求，不要额外写测试。
4. 回复时说明改了什么、怎么验证的、下一步建议做什么。

## 验证命令（在本项目文件夹里运行）

```powershell
& "C:\Users\m1371\Documents\Codex\2026-08-26\superpowers-plugin-superpowers-openai-api-curated-2\work\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless res://tests/m0_headless_test.tscn
python tools/validate_project.py
```

- 第一行跑现有验收测试，输出 "M0 RUNTIME TEST PASSED" 才算通过（日志/证书报错可忽略）。
- 第二行离线校验所有 JSON 是否合法，不需要安装 Godot。

## 范围提醒

- 只做酒吧（晚上调酒 / 对话 / 情报）和佣兵派遣（白天任务板）两套系统。
- 不做开放世界、不做战斗玩法、不做大型主线。
- 改动尽量小，保持现有目录结构和命名习惯。
