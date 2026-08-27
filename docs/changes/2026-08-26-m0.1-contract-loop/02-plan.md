# M0.1 委托调查 / 平板 / 谈判 实现计划

日期：2026-08-26

## 已完成

1. 扩展 `MissionData`：新增表面报酬、合理报价带、有效期、调查选项、情报条目、支持等级范围、主线/不限时标记。
2. 新增 `Contract` 状态对象：Pending / Investigating / ReadyForAssessment / Negotiating / AwaitingClientResponse / Confirmed / Dispatched / Completed / Expired / Rejected。
3. `GameState` 增加：
   - `MAX_PENDING_CONTRACTS = 6`
   - `investigation_points`（每天 3 点）
   - 委托板生成、调查、评估、谈判、确认、拒绝、佣兵态度、派遣
   - 结束一天时刷新调查点并扣除委托剩余天数，过期触发关系/信誉惩罚
4. 白天 UI 重构为 `FIXER TERMINAL`：委托列表 → 详情 → 调查 → 评估 → 谈判 → 选人 → 派遣，派遣按钮在合同确认前不可用。
5. 测试覆盖委托完整核心流程与 UI 节点冒烟。

## 待续

- 完整的 Debug 面板
- 夜晚情报自动关联到第二天委托
- 委托卡片更精致的视觉样式
- 客户还价 / 佣兵连续压榨的专属对话

## 验证命令

```text
godot --headless res://tests/m0_headless_test.tscn
python tools/validate_project.py
godot --headless --quit-after 5
```
