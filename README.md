# Fixers Prototype M0

Godot 4.7.2 工程骨架，按 `Prototype_0.1_技术开发手册.md` 搭出的派遣闭环。

## 当前一天流程

1. Day 1 Morning：委托板选任务、选会接的佣兵、派遣。
2. 任务进入后台队列，不会立刻结算。
3. 点“结束白天”进入 Evening，晚上面板展示配方。
4. 结束一天后进入 Day 2 Morning，先弹到期任务的完成/失败栏。
5. 关掉结果后回到当天的委托板，继续接任务。

当前内容：3 个佣兵、1 个任务、1 杯酒、1 个势力、1 条情报，全部来自 JSON。

## Run

Open this folder as a Godot project, or from a terminal in this folder:

```powershell
godot --headless --import
godot --headless res://tests/m0_headless_test.tscn
python tools/validate_project.py
```

The structural validator can run without Godot installed.

## Expansion order

- **M1:** add mission JSON files, then extend multi-day queue handling. Do not put mission IDs in GDScript.
- **M2:** add drink/dialogue JSON files, then implement matching and intel effects in `scripts/bar`, `scripts/dialogue`, and `scripts/intel`.
- **Content:** every content category has a README beside its JSON files.

## Folder map

```text
Prototype_0_1_M0/
├── data/                  # JSON content only
│   ├── mercenaries/       # 3 initial records
│   ├── missions/          # 1 tutorial mission
│   ├── drinks/            # 1 M2 recipe
│   ├── factions/          # 1 client
│   ├── dialogues/         # reserved for M2
│   └── intel/             # 1 success clue
├── scenes/
│   ├── main.tscn          # phase container
│   ├── morning/           # dispatch board
│   ├── evening/           # day-end / future bar
│   └── ui/                # result panel
├── scripts/
│   ├── core/              # state, time, events, save boundary
│   ├── data/              # generic JSON repository
│   ├── mission/           # data, manager, resolver
│   ├── mercenary/         # data and manager
│   ├── bar/               # reserved for M2
│   ├── dialogue/          # reserved for M2
│   ├── intel/             # reserved for M2
│   ├── faction/           # reserved for M1/M2
│   ├── morning/           # phase presentation
│   ├── evening/           # phase presentation
│   └── ui/                # shared presentation
├── assets/fonts/          # place Zpix/Ark Pixel TTF or OTF here
├── tests/                 # headless acceptance test
├── docs/
│   ├── superpowers/      # 设计/计划
│   └── changes/          # 每次变更单独留存
└── tools/                 # offline validator
```


