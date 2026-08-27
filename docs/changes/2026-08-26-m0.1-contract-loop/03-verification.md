# M0.1 验证记录

日期：2026-08-26

## 命令与结果

### 运行时验收

```text
$ godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED
```

### 结构校验

```text
$ python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
- folders: data / scenes / scripts / assets / tests
- no content IDs hard-coded in scripts
```

### 主场景启动

```text
$ godot --headless --quit-after 5
（退出码 0，无工程脚本错误）
```

## 测试覆盖

- 每天 3 个调查点，委托板最多 6 个普通委托。
- 新委托为 Pending，无情报时只能选择表面等级。
- 调查推进情报完整度，达到阈值后可评估到真实等级，但不能跳到 S。
- 推荐报价被客户接受，合同确认后派遣按钮可用。
- 佣兵根据等级、报酬与性格给出态度；确认合同后才能派遣。
- 派遣后委托离开待处理板，结算时使用谈判后的报酬。
