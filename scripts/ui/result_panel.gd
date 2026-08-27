extends VBoxContainer

signal continue_requested

var _result: Dictionary = {}

@onready var outcome_label: Label = $OutcomeLabel
@onready var details_label: Label = $DetailsLabel
@onready var intel_list: VBoxContainer = $IntelList

func setup(result: Dictionary, current_money: int, current_reputation: int) -> void:
    _result = result
    var success := bool(result.get("success", false))
    if bool(result.get("timed_out", false)):
        outcome_label.text = "任务逾期失败"
    else:
        outcome_label.text = "任务成功" if success else "任务失败"
    details_label.text = "%s\n耗时：%d 天   报酬：%d   信誉：%+d\n当前资金：%d   当前信誉：%d" % [
        str(result.get("mission_title", "")),
        int(result.get("completion_days", 0)),
        int(result.get("reward", 0)),
        int(result.get("reputation_change", 0)),
        current_money,
        current_reputation,
    ]

    for child in intel_list.get_children():
        child.queue_free()
    if result.get("new_intel", []).is_empty():
        var empty := Label.new()
        empty.text = "本单没有新情报。"
        intel_list.add_child(empty)
        return
    for intel_id in result.get("new_intel", []) as Array:
        var record := GameState.get_intel(str(intel_id))
        var label := Label.new()
        label.text = str(record.get("text", str(intel_id)))
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        intel_list.add_child(label)

func _on_continue_button_pressed() -> void:
    continue_requested.emit()

