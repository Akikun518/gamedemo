# 修复：点击委托无反应

日期：2026-08-27

## 问题

点击委托卡片后无法进入详情页，界面像是没有反应。

## 根因

`GameState.select_contract()` 会发出 `state_changed`，而主界面 `MainView` 监听了这个信号并每次重建 MorningPanel。重建后的面板会重置为委托板状态，导致“点击 → 进入详情”的瞬间又被拉回委托板。

同样的问题会影响调查、评估、谈判等所有需要保留当前面板状态的操作。

## 修复

- `MainView` 不再监听 `state_changed` 重建面板，只按阶段切换（`phase_changed` / `day_advanced` / 派遣与结算信号）。
- `MorningPanel` 自己监听 `state_changed`，只刷新自身内容，不再丢失当前是“委托板 / 详情 / 评估 / 谈判 / 选人”的状态。
- 测试新增 UI 交互断言：点击第一张委托卡片后必须显示详情内容。
- 校验器移除对已由 Godot 默认值保证的 `stretch/aspect` 的硬性检查，避免编辑器重写 project.godot 后误报。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
```

主场景 headless 启动无工程脚本错误。
