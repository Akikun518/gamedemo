# Development Log

## M0.2.1

日期：2026-08-27

目标：验证 Intel 因果链与等级判断是否成立。

完成：
- Intel 条目现在带 `rankAdjustment` / `rewardAdjustment` / `riskFlags`，调查结果会真正改变可评估等级、报价窗口和可见风险，而不是只显示文字。
- `find_cat` 的 4 条 Intel 形成从“客户隐瞒”到“公司数据库”的因果链。
- 等级选项由已发现 Intel 的数量与效果计算，玩家只能在证据支持范围内调整，不能直接跳到 S。

修改：
- data/missions/find_cat.json
- scripts/mission/mission_data.gd
- scripts/mission/contract.gd
- scripts/core/game_state.gd
- scripts/morning/morning_panel.gd
- tests/m0_headless_test.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- 4bce789 feat: implement intel causal chain and rank judgment

GitHub Push：
- 已推送 origin/main。

已知问题：
- 佣兵技能、失败/伤亡/赔偿、夜晚最小闭环尚未接入。

下一步：
- Phase 5：佣兵技能与团队能力。

## M0.2.2

日期：2026-08-27

目标：让佣兵技能真正参与任务结算。

完成：
- MissionResolver 现在按团队最高技能值检查任务的 `required_skills`。
- 任务数据从 `required_roles` 自动映射到技能与门槛；也可直接用 `required_skills` 指定。
- 技能不足时任务失败，并返回 `failure_type` 与 `skill_shortfall`。

修改：
- scripts/mission/mission_data.gd
- scripts/mission/mission_resolver.gd
- tests/m0_headless_test.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- cb5cc8b feat: use mercenary skills for mission resolution

GitHub Push：
- 已推送 origin/main。

已知问题：
- 失败 / 伤亡 / 赔偿 / 关系闭环尚未接入。

下一步：
- Phase 6：失败 / 伤亡 / 赔偿 / 关系。

## M0.2.3

日期：2026-08-27

目标：失败 / 伤亡 / 赔偿基础闭环。

完成：
- 技能不足导致的高风险失败会返回 FAILED_INJURY / FAILED_DEATH。
- 死亡时标记阵亡佣兵、扣除信誉，并产生待支付赔偿。
- 提供 pay_compensation / decline_compensation 两个状态接口。

修改：
- scripts/mission/mission_resolver.gd
- scripts/core/game_state.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- 待提交。

GitHub Push：
- 待推送。

已知问题：
- 赔偿还没有 UI 入口。

下一步：
- Phase 7：夜晚最小情报闭环。
