# M0 Prototype Design (2026-08-26)

## Goal

Build the smallest Godot 4.7.2 project that proves the day loop and one mission settlement can run without hard-coding content: start in Day 1 Morning, inspect one mission, select one of three mercenaries, dispatch, receive a deterministic result, continue to Evening, and advance to Day 2 Morning.

## Chosen approach

Use data-driven autoloads plus swappable phase panels:

- `DataRepository` reads every JSON record in each content directory.
- `GameState` owns the authoritative day, phase, money, reputation, roster, mission queue, results, and known intel.
- `MissionResolver` contains only settlement rules and receives dictionaries/data objects from the managers.
- `main.tscn` swaps `MorningPanel`, `ResultPanel`, and `EveningPanel`. No gameplay content is embedded in the UI.

## Alternatives considered

1. One large `main.gd`: fastest to write, but it would hide future M1/M2 boundaries and encourage hard-coded content.
2. Full mission queue with multi-day overlap: correct for the final prototype, but too much for M0. M0 instead records `start_day`, `due_day`, and `completion_days`, leaving the fields ready for M1.
3. Immediate result without a queue: easier, but would discard data needed to grow into multi-day missions. The selected design resolves the single mission immediately while retaining queue-shaped records.

## M0 scope

- Godot project settings for 640x360 integer-scaled output.
- Three initial mercenaries: Luo, Manniu, Sam.
- One mission: `find_cat`.
- One reserved drink record: `neon_fog`.
- One client faction (`neighbor`) and one success intel (`cat_necklace`).
- Morning dispatch, result, evening, and day advance phases.
- Save/dialogue/bartending/intel gameplay folders are present as clear expansion points but not implemented in M0.

## Acceptance criteria

1. Project and content structure pass the repository validator.
2. Initial state is Day 1 / Morning.
3. Dispatching Luo to `find_cat` succeeds in one day, awards 100 credits and 2 reputation, and unlocks `cat_necklace`.
4. Continuing from the result reaches Evening; ending Evening reaches Day 2 Morning.
5. No mercenary, mission, drink, faction, or intel ID is hard-coded in logic scripts.
