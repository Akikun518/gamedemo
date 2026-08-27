# 客户还价流程

日期：2026-08-27

## 新增

- `Contract.counter_offer` 字段，客户还价时给出一个可接受金额。
- `GameState.accept_counter_offer()`：接受还价后把合同报酬改为客户还价金额，并视为接受。
- 谈判面板：当客户还价时显示“客户还价：X”和“接受还价”按钮。

## 验证

```text
godot --headless res://tests/m0_headless_test.tscn
M0 RUNTIME TEST PASSED

python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
```

主场景 headless 启动无工程脚本错误。
