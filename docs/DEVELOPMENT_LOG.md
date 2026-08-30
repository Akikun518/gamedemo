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

## M0.2.4

日期：2026-08-27

目标：夜晚最小情报闭环。

完成：
- 新增 3 个酒吧客人数据。
- 晚上可选择客人并调酒，给对酒会解锁相关 Intel，给错酒不会解锁。
- 解锁的 Intel 会进入 IntelDatabase，并在第二天相关委托上标记 NEW INTEL。

修改：
- data/guests/regular.json
- data/guests/hacker.json
- data/guests/driver.json
- scripts/core/game_state.gd
- scripts/evening/evening_panel.gd
- scenes/evening/evening_panel.tscn
- scripts/ui/main_view.gd
- tests/m0_headless_test.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- 待提交。

GitHub Push：
- 待推送。

已知问题：
- 夜晚客人还比较简化，后续可扩展对话树。

下一步：
- 文档同步与整体验收。

## M0.3.1

日期：2026-08-30

目标：夜晚酒吧核心玩法第一阶段。

完成：
- 调酒结果从对/错升级为 Perfect / Acceptable / Wrong。
- 客人数据加入 social_class、favorite_tags、disliked_tags。
- 新增精力系统：默认 4 点，按社会身份消耗，0 点仍可普通接待但不能 DeepTalk。
- 新增客人状态：relationship_stage、affection、visit_count、memory。
- 新增 deep_talk 接口，返回关系阶段和剩余精力。

修改：
- data/guests/regular.json
- data/guests/hacker.json
- data/guests/driver.json
- scripts/core/game_state.gd
- scripts/evening/evening_panel.gd
- scenes/evening/evening_panel.tscn
- tests/m0_headless_test.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- 待提交。

GitHub Push：
- 待推送。

已知问题：
- IntelInventory、交易、对话树尚未接入。

下一步：
- Phase D：IntelInventory 与情报交易。

## M0.3.5

日期：2026-08-30

目标：统一 Mercenary 与 Guest 的角色数据。

完成：
- 洛 / 萨姆 / 米拉通过同一 `id` 同时拥有佣兵身份和酒吧顾客身份。
- 临时占位顾客 regular / hacker / driver 已移除。
- 顾客记录现在从带 `guest` 字段的佣兵自动生成，不再复制角色。
- 酒吧互动直接修改佣兵的 `affection`，不再维护两份好感。
- 保留 guest_states 中的 visit_count / memory / intent / known_intel。

修改：
- data/mercenaries/luo.json
- data/mercenaries/sam.json
- data/mercenaries/mira.json
- scripts/mercenary/mercenary_data.gd
- scripts/core/game_state.gd
- tests/m0_headless_test.gd

测试：
- `godot --headless res://tests/m0_headless_test.tscn` 通过。

Git Commit：
- 待提交。

GitHub Push：
- 待推送。

已知问题：
- IntelInventory / 交易尚未接入。

下一步：
- 继续 Phase D。
