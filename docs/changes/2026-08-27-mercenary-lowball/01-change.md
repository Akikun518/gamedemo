# 佣兵连续压价反馈

日期：2026-08-27

## 新增

- `GameState.mercenary_lowball_count` 记录每个佣兵被连续压价的次数。
- `register_mercenary_lowball(id)` 增加计数；`lowball_dialogue(id)` 返回三段递进台词。
- 三段台词：
  1. 钱有点少。
  2. 你最近是不是越来越会算账了？
  3. 以后这种价格别找我。
- 第三次压价后，该佣兵对低报酬委托直接拒绝。
- 派遣时若佣兵态度为 Reluctant，会自动记一次压价；达到第三次则拒绝并显示对应台词。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
```

主场景 headless 启动无工程脚本错误。
