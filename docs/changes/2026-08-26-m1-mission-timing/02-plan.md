# M1 任务延时结算与佣兵偏好 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让派遣任务按天延时结算，佣兵按标签接单，好感度替换信用点显示，并接入 EventBus 信号。

**Architecture:** 数据继续留在 JSON；`MissionData`/`MercenaryData` 负责字段与接单判断；`MissionResolver` 计算完成天数、截止日与是否逾期；`GameState` 持有队列并在每天早晨结算；UI 只做展示和转发。

**Tech Stack:** Godot 4.7.2, GDScript, JSON, Python 结构校验。

---

## 文件结构

### 修改

- `data/missions/find_cat.json`
- `data/mercenaries/luo.json`
- `data/mercenaries/manniu.json`
- `data/mercenaries/sam.json`
- `data/drinks/neon_fog.json`
- `scripts/mission/mission_data.gd`
- `scripts/mission/mission_resolver.gd`
- `scripts/mission/mission_manager.gd`
- `scripts/mercenary/mercenary_data.gd`
- `scripts/core/game_state.gd`
- `scripts/core/time_system.gd`
- `scripts/morning/morning_panel.gd`
- `scenes/morning/morning_panel.tscn`
- `scripts/evening/evening_panel.gd`
- `scripts/ui/result_panel.gd`
- `scenes/ui/result_panel.tscn`
- `scripts/ui/main_view.gd`
- `scenes/main.tscn`
- `tests/m0_headless_test.gd`
- `tools/validate_project.py`
- `README.md`

### 新增

- `docs/changes/2026-08-26-m1-mission-timing/01-spec.md`（已由设计阶段生成）
- `docs/changes/2026-08-26-m1-mission-timing/02-plan.md`（本文件）
- `docs/changes/2026-08-26-m1-mission-timing/03-verification.md`（验证完成后补）

---

## Task 1: 数据字段与校验契约

**Files:**
- Modify: `data/missions/find_cat.json`
- Modify: `data/mercenaries/luo.json`
- Modify: `data/mercenaries/manniu.json`
- Modify: `data/mercenaries/sam.json`
- Modify: `data/drinks/neon_fog.json`
- Modify: `tools/validate_project.py`

- [ ] **Step 1: 先写校验契约（让它失败）**

在 `tools/validate_project.py` 中，把 `DATA_REQUIRED_FIELDS` 改为：

```python
DATA_REQUIRED_FIELDS = {
    "mercenaries": {"id", "name", "role", "star", "stats", "price", "alive", "unlock", "likes", "dislikes"},
    "missions": {"id", "title", "client", "surface_rank", "true_rank", "required_roles", "reward", "base_days", "unlock", "on_success", "on_failure", "tags", "time_limit_days", "unlimited"},
    "drinks": {"id", "name", "taste", "alcohol", "audience", "unlock", "ingredients"},
    "factions": {"id", "name", "type", "affection"},
    "intel": {"id", "text", "related_mission", "hint"},
}
```

- [ ] **Step 2: 运行校验，确认因缺字段失败**

Run: `python tools/validate_project.py`
Expected: `M0 VALIDATION FAILED`，列出 missions/drinks/mercenaries 缺字段。

- [ ] **Step 3: 写入 JSON 字段**

`find_cat.json` 增加：

```json
"tags": ["cat", "neighbor"],
"time_limit_days": 2,
"unlimited": false
```

三个佣兵分别增加 `likes` 与 `dislikes`：

```json
// luo
"likes": ["vehicle", "heist"],
"dislikes": ["suicide"]

// manniu
"likes": ["combat", "money"],
"dislikes": ["civilian"]

// sam
"likes": ["talk", "negotiate"],
"dislikes": ["night_owl"]
```

`neon_fog.json` 增加：

```json
"ingredients": ["伏特加", "姜汁啤酒", "青柠"]
```

- [ ] **Step 4: 运行校验，确认数据契约通过**

Run: `python tools/validate_project.py`
Expected: `M0 VALIDATION PASSED`。

---

## Task 2: 佣兵接单判断

**Files:**
- Modify: `scripts/mercenary/mercenary_data.gd`
- Modify: `scripts/mission/mission_data.gd`
- Modify: `scripts/mission/mission_manager.gd`

- [ ] **Step 1: 写失败测试**

在 `tests/m0_headless_test.gd` 末尾增加（该文件当前是 Node 脚本，后面会整体改写，本步骤先加两个纯数据断言）：

```gdscript
func _test_acceptance() -> Array[String]:
    var errors: Array[String] = []
    var merc := MercenaryData.from_json({
        "id": "probe", "name": "探针", "role": "assault", "star": 2,
        "likes": ["combat"], "dislikes": ["hostage"], "alive": true, "unlock": "initial",
    })
    var hostage_mission := MissionData.from_json({
        "id": "hostage", "title": "绑架", "tags": ["hostage", "combat"],
    })
    var talk_mission := MissionData.from_json({
        "id": "talk", "title": "谈判", "tags": ["talk"],
    })
    _expect(errors, not merc.accepts_mission(hostage_mission), "Mercenary should refuse a disliked mission.")
    _expect(errors, not merc.accepts_mission(talk_mission), "Mercenary should refuse when no liked tag matches.")
    return errors
```

注意：`_expect` 当前签名是 `(errors: Array[String], condition, message)`，本步骤直接调用；测试还没接入主流程。

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: 脚本因 `MercenaryData.from_json` 没有 `likes`/`dislikes` 或 `accepts_mission` 不存在而报错/失败。

- [ ] **Step 3: 实现 `MercenaryData` 接单判断**

在 `scripts/mercenary/mercenary_data.gd` 增加字段与解析：

```gdscript
var likes: Array[String] = []
var dislikes: Array[String] = []

static func from_json(record: Dictionary) -> MercenaryData:
    var data := MercenaryData.new()
    # ... existing fields ...
    for like in record.get("likes", []) as Array:
        data.likes.append(str(like))
    for dislike in record.get("dislikes", []) as Array:
        data.dislikes.append(str(dislike))
    return data

func accepts_mission(mission: MissionData) -> bool:
    if not alive:
        return false
    for dislike in dislikes:
        if mission.tags.has(dislike):
            return false
    if likes.is_empty():
        return true
    for like in likes:
        if mission.tags.has(like):
            return true
    return false

func refusal_reason(mission: MissionData) -> String:
    for dislike in dislikes:
        if mission.tags.has(dislike):
            return "不接：%s" % taboo
    return "不接：不感兴趣"

func summary() -> String:
    return "%s  |  %s  |  %d星  |  好感度 %d/100" % [display_name, role, star, affection]
```

同时把 `MissionData` 增加 `tags`/`time_limit_days`/`unlimited`：

```gdscript
var tags: Array[String] = []
var time_limit_days := 2
var unlimited := false

static func from_json(record: Dictionary) -> MissionData:
    # ... existing fields ...
    for tag in record.get("tags", []) as Array:
        data.tags.append(str(tag))
    data.time_limit_days = int(record.get("time_limit_days", 2))
    data.unlimited = bool(record.get("unlimited", false))
    return data
```

- [ ] **Step 4: 运行测试确认绿色**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: 数据断言通过；主流程仍可能失败（后续任务会改）。

---

## Task 3: 结算器支持截止日与逾期

**Files:**
- Modify: `scripts/mission/mission_resolver.gd`

- [ ] **Step 1: 写失败测试**

在 `tests/m0_headless_test.gd` 增加构造的 `MissionResolver` 断言（与 `_test_acceptance` 同阶段）：

```gdscript
func _test_deadline() -> Array[String]:
    var errors: Array[String] = []
    var resolver := MissionResolver.new()
    var merc := MercenaryData.from_json({
        "id": "weak", "name": "弱", "role": "assault", "star": 1,
        "likes": [], "dislikes": [], "alive": true, "unlock": "initial",
    })
    var mission := MissionData.from_json({
        "id": "rush", "title": "赶工", "true_rank": "B", "base_days": 3,
        "time_limit_days": 1, "unlimited": false, "tags": [],
    })
    var result := resolver.resolve(mission, [merc], 1)
    _expect(errors, bool(result.get("timed_out", false)), "Mission should time out when completion exceeds deadline.")
    _expect(errors, not bool(result.get("success", true)), "Timed-out mission should fail.")
    _expect(errors, int(result.get("settlement_day", 0)) == int(result.get("deadline_day", 0)), "Settlement should land on the deadline.")
    return errors
```

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: 结果没有 `timed_out` 字段，断言失败。

- [ ] **Step 3: 实现截止日与逾期**

把 `MissionResolver.resolve` 的返回值补齐：

```gdscript
var deadline_day := start_day + mission.time_limit_days
var raw_settlement_day := start_day + completion_days
var timed_out := false
var settlement_day := raw_settlement_day

if not mission.unlimited and raw_settlement_day > deadline_day:
    timed_out = true
    settlement_day = deadline_day
    success = false
    consequences = mission.on_failure

return {
    # ... existing fields ...
    "deadline_day": deadline_day,
    "settlement_day": settlement_day,
    "timed_out": timed_out,
    "due_day": settlement_day,
}
```

`success` 为 false 时，`reward` 已经按 `mission.reward if success else 0` 处理；`consequences` 需在逾期分支重算。

- [ ] **Step 4: 运行测试确认绿色**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: deadline 断言通过。

---

## Task 4: GameState 队列与早晨结算

**Files:**
- Modify: `scripts/core/game_state.gd`
- Modify: `scripts/core/time_system.gd`

- [ ] **Step 1: 写失败测试**

把 `tests/m0_headless_test.gd` 的 `_run()` 改成：

```gdscript
func _run() -> void:
    var mission := GameState.available_missions()[0]
    var mercenary := GameState.available_mercenaries()[0]

    _expect(GameState.current_day == 1, "Initial day should be 1.")
    _expect(GameState.current_phase == TimeSystem.MORNING, "Initial phase should be Morning.")

    GameState.selected_mercenary_ids = [mercenary.id]
    var dispatch := GameState.dispatch_mission(mission.id)
    _expect(not dispatch.has("error"), "Dispatch should accept a matching mercenary.")
    _expect(GameState.active_missions.size() == 1, "Dispatch should enqueue one mission.")
    _expect(GameState.pending_results.is_empty(), "No result should pop on dispatch day.")
    _expect(GameState.current_phase == TimeSystem.MORNING, "Dispatch should stay in Morning.")

    GameState.end_morning()
    _expect(GameState.current_phase == TimeSystem.EVENING, "Ending Morning should reach Evening.")
    GameState.end_evening()
    _expect(GameState.current_day == 2, "Ending Evening should advance to Day 2.")
    _expect(GameState.current_phase == TimeSystem.RESULT, "Day 2 should open with the due result.")

    var result := GameState.latest_result
    _expect(bool(result.get("success", false)), "The tutorial mission should succeed.")
    _expect(GameState.continue_from_result(), "The result should be closable.")
    _expect(GameState.current_phase == TimeSystem.MORNING, "Closing the result should return to the board.")
```

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: `dispatch_mission` 仍走旧逻辑并进入 RESULT，断言失败。

- [ ] **Step 3: 实现队列与状态转换**

`game_state.gd`：

```gdscript
var pending_results: Array[Dictionary] = []

func active_mission_ids() -> Array[String]:
    var ids: Array[String] = []
    for assignment in active_missions:
        ids.append(str(assignment.get("mission_id", "")))
    return ids

func available_missions() -> Array[MissionData]:
    return mission_manager.available(active_mission_ids())

func dispatch_mission(mission_id: String) -> Dictionary:
    if current_phase != TimeSystem.MORNING:
        return {"error": "Missions can only be dispatched in the morning."}
    if selected_mercenary_ids.is_empty():
        return {"error": "Select at least one mercenary."}
    var mission := mission_manager.get_mission(mission_id)
    if mission == null:
        return {"error": "Unknown mission."}
    var team := selected_team()
    if team.is_empty():
        return {"error": "No living selected mercenary."}
    for mercenary in team:
        if not mercenary.accepts_mission(mission):
            return {"error": "One selected mercenary refuses this mission."}

    var result := _resolver.resolve(mission, team, current_day)
    var assignment := {
        "mission_id": mission.id,
        "mercenary_ids": selected_mercenary_ids.duplicate(),
        "start_day": current_day,
        "settlement_day": int(result.get("settlement_day", current_day)),
        "deadline_day": int(result.get("deadline_day", current_day)),
        "timed_out": bool(result.get("timed_out", false)),
        "unlimited": mission.unlimited,
    }
    active_missions.append(assignment)
    selected_mercenary_ids.clear()
    EventBus.mission_dispatched.emit(assignment)
    EventBus.notice.emit("已派遣「%s」，预计第 %d 天结算。" % [mission.title, int(assignment["settlement_day"])])
    state_changed.emit()
    return {"dispatched": true, "mission_id": mission.id, "settlement_day": assignment["settlement_day"]}

func end_morning() -> bool:
    if current_phase != TimeSystem.MORNING:
        return false
    current_phase = TimeSystem.EVENING
    EventBus.phase_changed.emit(current_day, current_phase)
    state_changed.emit()
    return true

func end_evening() -> bool:
    if current_phase != TimeSystem.EVENING:
        return false
    current_day += 1
    current_phase = TimeSystem.MORNING
    selected_mercenary_ids.clear()
    EventBus.day_advanced.emit(current_day)
    _settle_due_missions()
    EventBus.phase_changed.emit(current_day, current_phase)
    state_changed.emit()
    return true

func continue_from_result() -> bool:
    if current_phase != TimeSystem.RESULT:
        return false
    pending_results.pop_front()
    if pending_results.is_empty():
        current_phase = TimeSystem.MORNING
    else:
        latest_result = pending_results[0]
    EventBus.phase_changed.emit(current_day, current_phase)
    state_changed.emit()
    return true

func _settle_due_missions() -> void:
    for assignment in active_missions.duplicate():
        if int(assignment.get("settlement_day", 9999)) > current_day:
            continue
        var mission := mission_manager.get_mission(str(assignment.get("mission_id", "")))
        if mission == null:
            continue
        var team: Array[MercenaryData] = []
        for id in assignment.get("mercenary_ids", []) as Array:
            var mercenary := mercenary_manager.get_mercenary(str(id))
            if mercenary != null and mercenary.alive:
                team.append(mercenary)
        var result := _resolver.resolve(mission, team, int(assignment.get("start_day", current_day)))
        if bool(assignment.get("timed_out", false)):
            result["success"] = false
            result["reward"] = 0
            result["reputation_change"] = int(mission.on_failure.get("reputation", 0))
        _apply_result(mission, result)
        resolved_results.append(result)
        pending_results.append(result)
        latest_result = result
        active_missions.erase(assignment)
        EventBus.mission_resolved.emit(result)
    if not pending_results.is_empty():
        latest_result = pending_results[0]
        current_phase = TimeSystem.RESULT
```

`mission_manager.gd` 改为：

```gdscript
func available(excluded_ids: Array[String]) -> Array[MissionData]:
    var available: Array[MissionData] = []
    for mission in _missions:
        if mission.unlock == "initial" and not excluded_ids.has(mission.id):
            available.append(mission)
    return available
```

- [ ] **Step 4: 运行测试确认绿色**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: `M0 RUNTIME TEST PASSED`。

---

## Task 5: UI 委托板与结果栏

**Files:**
- Modify: `scripts/morning/morning_panel.gd`
- Modify: `scenes/morning/morning_panel.tscn`
- Modify: `scripts/ui/main_view.gd`
- Modify: `scripts/ui/result_panel.gd`
- Modify: `scenes/ui/result_panel.tscn`
- Modify: `scenes/main.tscn`

- [ ] **Step 1: 写失败测试（UI 路径）**

把 `tests/m0_headless_test.gd` 再补一段 UI 断言：实例化 `scenes/main.tscn`，断言 MorningPanel 下有 `MissionList` 和 `EndMorningButton`；派遣后断言 `MissionList` 不再包含已派遣任务；`EndMorningButton` 能触发进入 Evening。

- [ ] **Step 2: 运行测试确认失败**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: 找不到 `MissionList` 节点，UI 断言失败。

- [ ] **Step 3: 实现委托板**

`morning_panel.gd` 增加：

```gdscript
signal end_morning_requested

var _missions: Array[MissionData] = []
var _mercenaries: Array[MercenaryData] = []

@onready var mission_list: VBoxContainer = $MissionList
@onready var end_morning_button: Button = $EndMorningButton

func setup(missions: Array[MissionData], mercenaries: Array[MercenaryData], current_money: int, current_reputation: int) -> void:
    _missions = missions
    _mercenaries = mercenaries
    _selected_ids.clear()
    _render_missions()
    _render_mercenaries()
    end_morning_button.pressed.connect(_on_end_morning_button_pressed)

func _render_missions() -> void:
    for child in mission_list.get_children():
        child.queue_free()
    for mission in _missions:
        var button := Button.new()
        button.text = mission.public_summary()
        button.toggle_mode = true
        button.button_pressed = _mission != null and _mission.id == mission.id
        button.pressed.connect(func() -> void: _select_mission(mission))
        mission_list.add_child(button)

func _select_mission(mission: MissionData) -> void:
    _mission = mission
    _selected_ids.clear()
    _render_mercenaries()
    status_label.text = "已选中「%s」。选择会接的佣兵后派遣。" % mission.title
```

佣兵渲染使用 `mercenary.accepts_mission(_mission)` 决定复选框是否禁用，并显示 `summary_for_mission`。

`main_view.gd` Morning 分支改为：

```gdscript
morning.setup(GameState.available_missions(), GameState.available_mercenaries(), GameState.money, GameState.reputation)
morning.dispatch_requested.connect(_on_dispatch_requested)
morning.end_morning_requested.connect(func() -> void: GameState.end_morning())
```

`result_panel.tscn` 的 `ContinueButton` 文案改为“返回委托板”。`result_panel.gd` 详情补上“截止日 / 逾期”提示。

- [ ] **Step 4: 运行测试确认绿色**

Run: `godot --headless res://tests/m0_headless_test.tscn`
Expected: `M0 RUNTIME TEST PASSED`。

---

## Task 6: EventBus 接线与配方展示

**Files:**
- Modify: `scripts/ui/main_view.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/evening/evening_panel.gd`

- [ ] **Step 1: 写失败测试**

在 `tools/validate_project.py` 增加信号使用检查：遍历 `event_bus.gd` 声明的信号名，确认除 `event_bus.gd` 外至少一个 `.gd` 文件包含该名字。

- [ ] **Step 2: 运行校验确认失败**

Run: `python tools/validate_project.py`
Expected: 每个信号都被报告“not used outside event_bus.gd”。

- [ ] **Step 3: 接线**

`main_view.gd` `_ready()`：

```gdscript
EventBus.phase_changed.connect(func(_day: int, _phase: String) -> void: _refresh())
EventBus.day_advanced.connect(func(_day: int) -> void: _refresh())
EventBus.mission_dispatched.connect(_on_mission_dispatched)
EventBus.mission_resolved.connect(_on_mission_resolved)
EventBus.notice.connect(_on_notice)
```

`scenes/main.tscn` 增加一个 `NoticeLabel`，`main_view.gd` 用它显示 `EventBus.notice`。

`evening_panel.gd` 的配方文案加入 `ingredients`：

```gdscript
drink_label.text = "第 %d 天晚上\n预留配方：%s（%s）\n材料：%s\n口味：%s   酒精度：%d/5" % [
    current_day,
    str(drink.get("name", "")),
    str(drink.get("ref", "")),
    "、".join(drink.get("ingredients", [])),
    "、".join(drink.get("taste", [])),
    int(drink.get("alcohol", 0)),
]
```

- [ ] **Step 4: 运行校验确认绿色**

Run: `python tools/validate_project.py`
Expected: 信号使用检查通过。

---

## Task 7: 全量验证与复盘文档

- [ ] 运行 `python tools/validate_project.py`。
- [ ] 运行 `godot --headless res://tests/m0_headless_test.tscn`。
- [ ] 运行 `godot --headless --quit-after 5` 检查主场景无脚本错误。
- [ ] 把验证输出写入 `docs/changes/2026-08-26-m1-mission-timing/03-verification.md`。
- [ ] 更新 `README.md` 的运行说明和文件夹地图。
