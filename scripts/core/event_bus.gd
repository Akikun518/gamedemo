extends Node
## Cross-system signals. UI listens here instead of reaching into managers.

signal phase_changed(current_day: int, phase: String)
signal mission_dispatched(payload: Dictionary)
signal mission_resolved(payload: Dictionary)
signal day_advanced(current_day: int)
signal notice(message: String)
