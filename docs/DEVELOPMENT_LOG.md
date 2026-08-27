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
