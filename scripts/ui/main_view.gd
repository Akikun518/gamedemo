extends Control
## Root phase container. It swaps presentation panels and forwards user intent.

const MORNING_PANEL := preload("res://scenes/morning/morning_panel.tscn")
const RESULT_PANEL := preload("res://scenes/ui/result_panel.tscn")
const EVENING_PANEL := preload("res://scenes/evening/evening_panel.tscn")

@onready var phase_host: Control = $PhaseHost
@onready var notice_label: Label = $NoticeLabel

func _ready() -> void:
    EventBus.phase_changed.connect(_on_phase_changed)
    EventBus.day_advanced.connect(_on_day_advanced)
    EventBus.mission_dispatched.connect(_on_mission_dispatched)
    EventBus.mission_resolved.connect(_on_mission_resolved)
    EventBus.notice.connect(_on_notice)
    _refresh()

func _refresh() -> void:
    for child in phase_host.get_children():
        child.queue_free()

    match GameState.current_phase:
        TimeSystem.MORNING:
            var morning := MORNING_PANEL.instantiate()
            phase_host.add_child(morning)
            morning.setup(GameState.available_missions(), GameState.available_mercenaries(), GameState.money, GameState.reputation)
            morning.end_morning_requested.connect(_on_end_morning_requested)
        TimeSystem.RESULT:
            var result := RESULT_PANEL.instantiate()
            phase_host.add_child(result)
            result.setup(GameState.latest_result, GameState.money, GameState.reputation)
            result.continue_requested.connect(_on_continue_requested)
        TimeSystem.EVENING:
            var evening := EVENING_PANEL.instantiate()
            phase_host.add_child(evening)
            evening.setup(GameState.available_drinks(), GameState.guests(), GameState.current_day)
            evening.end_day_requested.connect(_on_end_day_requested)
        _:
            pass

func _on_dispatch_requested(mission_id: String) -> void:
    GameState.dispatch_mission(mission_id)

func _on_end_morning_requested() -> void:
    GameState.end_morning()

func _on_continue_requested() -> void:
    GameState.continue_from_result()

func _on_end_day_requested() -> void:
    GameState.end_evening()

func _on_phase_changed(_day: int, _phase: String) -> void:
    _refresh()

func _on_day_advanced(_day: int) -> void:
    _refresh()

func _on_mission_dispatched(_payload: Dictionary) -> void:
    _refresh()

func _on_mission_resolved(_payload: Dictionary) -> void:
    _refresh()

func _on_notice(message: String) -> void:
    notice_label.text = message
