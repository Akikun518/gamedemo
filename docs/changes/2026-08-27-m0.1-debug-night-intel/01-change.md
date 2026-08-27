# M0.1 Debug 面板与夜晚情报关联

日期：2026-08-27

## 新增

- `GameState.debug_mode` 与一组 Debug 方法：调查点 +1、揭示当前委托全部情报、让委托过期、强制客户接受/拒绝、强制佣兵接受/拒绝。
- 白天 Terminal 面板增加 `Debug` 开关；开启后在委托板下方显示 Debug 操作。
- 晚上酒吧面板增加“收集一条酒吧情报”按钮，数据驱动地收集与待处理委托相关的情报。
- `Contract.night_intel_ids` 记录夜晚情报；委托板显示 `[NEW INTEL]`，详情页显示对应情报文本。
- 第二天进入白天时，相关情报已经标记在对应委托上。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
```

主场景 headless 启动无工程脚本错误。
