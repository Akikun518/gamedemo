# 校验器适配内容增长

日期：2026-08-26

## 原因

`data/` 下的内容已从最初的 3 佣兵 / 1 任务 / 1 酒扩充到完整内容（8 佣兵、8 任务、5 酒、6 势力、4 情报），旧校验器还在用固定数量断言，扩充后会误报失败。

## 修改

- `tools/validate_project.py` 的 `DATA_COUNTS` 改为 `DATA_MINIMUM_COUNTS`。
- 数量断言从“必须等于”改为“至少满足最小数量”，因此后续继续加 JSON 不再触发数量误报。
- 补回 `project.godot` 的 `window/stretch/aspect="keep"`。

## 验证

```text
python tools/validate_project.py
M0 VALIDATION PASSED
- content records: 31
- folders: data / scenes / scripts / assets / tests
- no content IDs hard-coded in scripts
```
