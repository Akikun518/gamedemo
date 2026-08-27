class_name Contract
extends RefCounted
## One pending contract on the fixer's tablet.

const STATE_PENDING := "Pending"
const STATE_INVESTIGATING := "Investigating"
const STATE_READY_FOR_ASSESSMENT := "ReadyForAssessment"
const STATE_NEGOTIATING := "Negotiating"
const STATE_AWAITING_CLIENT := "AwaitingClientResponse"
const STATE_CONFIRMED := "Confirmed"
const STATE_DISPATCHED := "Dispatched"
const STATE_COMPLETED := "Completed"
const STATE_EXPIRED := "Expired"
const STATE_REJECTED := "Rejected"

var id := ""
var mission: MissionData
var state := STATE_PENDING
var remaining_days := 1
var discovered_intel: Array[String] = []
var night_intel_ids: Array[String] = []
var assessed_rank := "D"
var negotiated_reward := 0
var counter_offer := 0
var client_response := ""
var confirmed := false

func _init(mission_data: MissionData) -> void:
    mission = mission_data
    id = mission_data.id
    remaining_days = mission_data.remaining_days
    assessed_rank = mission_data.surface_rank
    negotiated_reward = mission_data.surface_reward

func intel_progress() -> float:
    var total := mission.intel_entries.size()
    if total == 0:
        return 0.0
    return float(discovered_intel.size()) / float(total)

func intel_summary() -> String:
    return "%d / %d" % [discovered_intel.size(), mission.intel_entries.size()]

func board_summary() -> String:
    var suffix := ""
    if not night_intel_ids.is_empty():
        suffix = "  |  [NEW INTEL]"
    return "%s  |  %s  |  %dc  |  剩余 %d 天  |  情报 %s%s" % [
        mission.title,
        mission.surface_rank,
        mission.surface_reward,
        remaining_days,
        intel_summary(),
        suffix,
    ]

