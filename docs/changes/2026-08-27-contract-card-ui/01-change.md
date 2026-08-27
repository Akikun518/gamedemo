# 委托卡片视觉

日期：2026-08-27

## 新增

- 新增 `scenes/morning/contract_card.tscn` 和 `scripts/morning/contract_card.gd`。
- 委托列表不再是一排普通按钮，而是带深色背景、蓝色描边和圆角的卡片。
- 卡片包含一个按钮，点击后进入委托详情。
- UI 冒烟测试更新为识别卡片内的按钮。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
```

主场景 headless 启动无工程脚本错误。
