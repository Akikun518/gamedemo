# M0 Godot Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Godot 4.7.2 M0 skeleton with a clear folder taxonomy, data-driven loading, a one-day state machine, and one resolvable mission.

**Architecture:** Autoloads provide data and state; managers turn JSON dictionaries into typed records; `MissionResolver` owns settlement rules; phase panels are presentational and emit signals. The main scene only coordinates phase transitions.

**Tech Stack:** Godot 4.7.2, GDScript, JSON content records, Control-based 2D UI, Python structural validation.

---

### Task 1: Verification harness

**Files:**
- Create: `tools/validate_project.py`
- Create: `tests/m0_headless_test.gd`

- [ ] Write structural/data-contract assertions before implementation.
- [ ] Run `python tools/validate_project.py`; expected result: failure because `project.godot` and implementation files do not exist yet.
- [ ] Implement only after the failure is confirmed.

### Task 2: Project and folders

**Files:**
- Create: `project.godot`
- Create all `data/*`, `scenes/*`, `scripts/*`, `assets/*`, and `tests` folders.
- Create one README per data folder.

- [ ] Configure 640x360 viewport, 1280x720 initial window, `canvas_items`, `keep`, integer scaling, and nearest filtering.
- [ ] Register `DataRepository`, `EventBus`, and `GameState` autoloads in dependency order.

### Task 3: Data layer and typed records

**Files:**
- Create: `scripts/data/json_repository.gd`
- Create: `scripts/mercenary/mercenary_data.gd`
- Create: `scripts/mercenary/mercenary_manager.gd`
- Create: `scripts/mission/mission_data.gd`
- Create: `scripts/mission/mission_manager.gd`
- Create JSON records under `data/`.

- [ ] Parse all JSON files without game logic containing content IDs.
- [ ] Keep future expansion directories and schema notes readable.

### Task 4: State machine and settlement

**Files:**
- Create: `scripts/core/event_bus.gd`
- Create: `scripts/core/game_state.gd`
- Create: `scripts/core/time_system.gd`
- Create: `scripts/mission/mission_resolver.gd`
- Create: `tests/m0_headless_test.gd`.

- [ ] Verify Day 1 Morning initial state.
- [ ] Verify selection and dispatch.
- [ ] Verify one-day success and rewards.
- [ ] Verify Result -> Evening -> Day 2 Morning transitions.

### Task 5: Minimal UI

**Files:**
- Create: `scenes/main.tscn`
- Create: `scripts/ui/main_view.gd`
- Create: `scenes/morning/morning_panel.tscn` and script.
- Create: `scenes/ui/result_panel.tscn` and script.
- Create: `scenes/evening/evening_panel.tscn` and script.

- [ ] Present mission and roster from state.
- [ ] Dispatch selection and show resolver output.
- [ ] Use Evening only as the M2 placeholder and end-day gate.

### Task 6: Verification and delivery

- [ ] Run `python tools/validate_project.py`.
- [ ] If a local Godot binary is available, run `godot --headless --import`, then `godot --headless res://tests/m0_headless_test.tscn`.
- [ ] Inspect the final folder tree and README.


