# M1 Design: 任务延时结算、佣兵偏好与好感度展示

日期：2026-08-26

## 目标

把 M0 的“派完立刻弹结果”改成符合手册的派遣闭环：

1. 白天选任务、选佣兵、派遣；任务进入后台队列，不立刻结算。
2. 当天晚上正常过夜；第二天早上先弹出到期任务的成功/失败栏。
3. 弹完结果后回到当天委托板，继续接任务。
4. 每个佣兵有性格、偏好与禁忌，部分任务会接、部分任务会拒绝。
5. 佣兵列表显示好感度，不再显示信用点。
6. 任务有截止时间；只有主线任务可以不限时。
7. 调酒数据支持配方字段，为后续独立调酒小游戏留好入口。
8. 修复 EventBus 5 个 UNUSED_SIGNAL 警告，把信号真正接进界面。

## 一天流程（确认版）

```text
Day 1 Morning
  ├── 委托板列出可接任务（当前 1 个）
  ├── 点击任务 → 佣兵列表按该任务显示“会接 / 不接”
  ├── 选择会接的佣兵 → 派遣
  ├── 任务进入 active_missions，状态提示“已派遣，预计 X 天结算”
  ├── 可继续接其他任务（M1 先支持多派遣记录）
  └── 点击“结束白天”
        ↓
Evening
  ├── 酒吧占位面板，展示配方（M2 再做调酒小游戏）
  └── 点击“结束这一天”
        ↓
Day 2 Morning（先结算，后看板）
  ├── 结算所有 settlement_day <= current_day 的任务
  ├── 逐个弹出成功 / 失败 / 逾期失败 结果栏
  └── 关闭结果 → 回到 Day 2 委托板继续接任务
```

## 数据结构变更

### 任务 mission

新增字段：

- `tags`: Array[String]，任务标签，如 `["cat", "escort"]`
- `time_limit_days`: int，派遣后第几天截止（从派遣当天开始算）
- `unlimited`: bool，主线不限时任务专用；`true` 时忽略 `time_limit_days`

截止日 = `start_day + time_limit_days`；结算日 = `start_day + completion_days`。

- 普通任务：如果 `start_day + completion_days > 截止日`，在截止日当天判定“逾期失败”。
- 不限时任务：没有截止日，在 `start_day + completion_days` 当天结算。

### 佣兵 mercenary

新增字段：

- `likes`: Array[String]，喜欢的任务标签；为空 = 不挑活
- `dislikes`: Array[String]，讨厌/禁忌的任务标签；命中即拒绝

接单规则（`MercenaryData.accepts_mission(mission)`）：

1. 任务标签命中任意 `dislikes` → 拒绝。
2. `likes` 非空且与任务标签无交集 → 不感兴趣，拒绝。
3. 其余情况 → 接。

### 酒 drink

新增字段：

- `ingredients`: Array[String]，配方材料，如 `["姜汁啤酒", "伏特加", "青柠"]`

配方先用于晚上面板展示；完整调酒小游戏（选材料、口感匹配、酒精判定）属于后续专门任务，不在本设计里实现。

## 状态机与 GameState 变更

- 新增 `pending_results: Array[Dictionary]`，到期结算的结果按顺序排队。
- `latest_result` 改为当前正在展示的一条结果。
- `dispatch_mission()` 不再调用结算器；只校验任务、佣兵接单规则，写入 `active_missions` 并停留 Morning。
- 新增 `end_morning()`：Morning → Evening。
- `end_evening()`：天数 +1，切到 Morning，随后调用 `_settle_due_missions()`；若有到期结果则进入 RESULT，否则停在 Morning。
- `continue_from_result()`：弹出下一条 pending result；队列清空后回到 Morning（不是 Evening）。
- 结算时机为“Day N 早晨”，保证“第二天才弹结果”。

结算结果新增字段：

- `timed_out: bool`
- `deadline_day: int`
- `settlement_day: int`

逾期强制失败，且只应用 `on_failure` 后果。

## 佣兵接单在 UI 上的体现

- 佣兵卡片：名字、职业、星级、性格、偏好/禁忌、好感度 X/100；去掉信用点。
- 选中某个任务后，佣兵行显示“会接”或“不接：讨厌夜枭 / 对这类任务不感兴趣”。
- 拒绝该任务的佣兵复选框禁用，不能加入派遣队。
- 派遣时再次校验，防止绕过 UI 直接调用状态产生非法派遣。

## 委托板 UI 变更

Morning 面板从“单个任务”改成：

- 左侧/上方：任务列表（点击选中）
- 中间：佣兵列表（随选中任务刷新接单状态）
- 下方：状态提示 + “派遣所选佣兵” + “结束白天”

当前内容只有 1 个任务，但结构按多任务设计。

## EventBus 修复

5 个信号全部接进实际使用点，不删除总线：

- `phase_changed` → MainView 刷新当前面板
- `day_advanced` → MainView 刷新并重新结算视图
- `mission_dispatched` → MainView 更新“已派遣”状态
- `mission_resolved` → MainView 展示结果队列
- `notice` → Main 场景顶部提示标签

## 测试策略

更新 `tests/m0_headless_test.tscn` 对应的 `m0_headless_test.gd`，覆盖：

1. Day 1 Morning 初始状态。
2. 选中任务 + 会接的佣兵 → 派遣后 `active_missions` 为 1，`current_phase` 仍是 Morning，`pending_results` 为空。
3. `end_morning()` → Evening；`end_evening()` → Day 2，先进入 RESULT。
4. 结果内容为成功、1 天、报酬与信誉按 `find_cat` 的 `on_success` 应用。
5. `continue_from_result()` → 回到 Day 2 Morning 委托板。
6. 接单规则单元断言：构造一个命中 `dislikes` 的任务和一个命中 `likes` 但无交集的任务，均返回拒绝。
7. EventBus 每个信号至少有一个 connect 使用点（用静态检查脚本验证）。

## 非目标

- 不做 8 个佣兵 / 8 个任务的完整内容。
- 不做完整调酒小游戏。
- 不做多日重叠队列的 UI 展开（M1 只保证数据层可排队、按天结算）。
- 不做存档读档的新功能，仅保留 M0 的序列化边界。
