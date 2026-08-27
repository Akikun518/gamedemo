class_name MissionData
extends RefCounted

const RANK_NUMBERS := {"D": 1, "C": 2, "B": 3, "A": 4, "S": 5}
const RANKS := ["D", "C", "B", "A", "S"]
const NEGOTIATION_LIMITED_THRESHOLD := 0.40
const NEGOTIATION_FULL_THRESHOLD := 0.70

var id := ""
var title := ""
var client := ""
var surface_rank := "D"
var true_rank := "D"
var required_roles: Array[String] = []
var reward := 0
var base_days := 1
var tags: Array[String] = []
var time_limit_days := 2
var unlimited := false
var unlock := "initial"
var on_success: Dictionary = {}
var on_failure: Dictionary = {}

# M0.1 contract layer
var surface_reward := 0
var minimum_reasonable_reward := 0
var recommended_reward := 0
var maximum_reasonable_reward := 0
var expiration_days := 1
var remaining_days := 1
var required_skills: Array[Dictionary] = []
var hidden_conditions: Array[String] = []
var investigation_options: Array[Dictionary] = []
var intel_entries: Array[Dictionary] = []
var minimum_supported_rank := "D"
var maximum_supported_rank := "S"
var negotiation_enabled := true
var is_main_story := false
var no_expiration := false
var client_response_rules: Dictionary = {}
var mercenary_response_rules: Dictionary = {}
var expiration_consequences: Dictionary = {}

static func from_json(record: Dictionary) -> MissionData:
    var data := MissionData.new()
    data.id = str(record.get("id", ""))
    data.title = str(record.get("title", data.id))
    data.client = str(record.get("client", ""))
    data.surface_rank = str(record.get("surface_rank", "D"))
    data.true_rank = str(record.get("true_rank", data.surface_rank))
    for role in record.get("required_roles", []) as Array:
        data.required_roles.append(str(role))
    data.reward = int(record.get("reward", 0))
    data.base_days = int(record.get("base_days", 1))
    for tag in record.get("tags", []) as Array:
        data.tags.append(str(tag))
    data.time_limit_days = int(record.get("time_limit_days", 2))
    data.unlimited = bool(record.get("unlimited", false))
    data.unlock = str(record.get("unlock", "initial"))
    data.on_success = record.get("on_success", {}) as Dictionary
    data.on_failure = record.get("on_failure", {}) as Dictionary

    data.surface_reward = int(record.get("surfaceReward", data.reward))
    data.recommended_reward = int(record.get("recommendedReward", data.surface_reward))
    data.minimum_reasonable_reward = int(record.get("minimumReasonableReward", int(data.surface_reward * 0.5)))
    data.maximum_reasonable_reward = int(record.get("maximumReasonableReward", int(data.surface_reward * 2.0)))
    data.expiration_days = int(record.get("expirationDays", 5))
    data.remaining_days = data.expiration_days
    data.no_expiration = bool(record.get("noExpiration", false))
    data.is_main_story = bool(record.get("isMainStory", data.no_expiration))

    if record.has("required_skills"):
        for skill in record.get("required_skills", []) as Array:
            data.required_skills.append(skill as Dictionary)
    else:
        for role in data.required_roles:
            data.required_skills.append({"role": role, "level": 0})

    for condition in record.get("hiddenConditions", []) as Array:
        data.hidden_conditions.append(str(condition))

    data.investigation_options = _parse_investigation_options(record)
    data.intel_entries = _parse_intel_entries(record)
    data.minimum_supported_rank = str(record.get("minimumSupportedRank", data.surface_rank))
    data.maximum_supported_rank = str(record.get("maximumSupportedRank", data.true_rank))
    data.negotiation_enabled = bool(record.get("negotiationEnabled", true))
    data.client_response_rules = record.get("clientResponseRules", {}) as Dictionary
    data.mercenary_response_rules = record.get("mercenaryResponseRules", {}) as Dictionary
    data.expiration_consequences = record.get("expirationConsequences", {}) as Dictionary
    return data

static func _parse_investigation_options(record: Dictionary) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    if record.has("investigationOptions"):
        for option in record.get("investigationOptions", []) as Array:
            options.append(option as Dictionary)
        return options
    var labels := ["调查客户", "调查地点", "询问佣兵", "查询势力"]
    for i in labels.size():
        options.append({
            "id": "invest_%d" % i,
            "label": labels[i],
            "cost": 1,
            "intel_id": "intel_%d" % i,
        })
    return options

static func _parse_intel_entries(record: Dictionary) -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    if record.has("intelEntries"):
        for entry in record.get("intelEntries", []) as Array:
            entries.append(entry as Dictionary)
        return entries
    var option_count := record.get("investigationOptions", []) as Array
    var count := maxi(option_count.size(), 4)
    for i in count:
        entries.append({
            "id": "intel_%d" % i,
            "source": "调查",
            "description": "这条情报揭示了委托背后的一些信息。",
            "reliability": "中",
        })
    return entries

func public_summary() -> String:
    return "%s  |  委托：%s  |  表面等级：%s  |  报酬：%d" % [title, client, surface_rank, surface_reward]

func rank_number(rank: String) -> int:
    return int(RANK_NUMBERS.get(rank, 1))

func max_supported_rank_for_progress(progress: float) -> String:
    if progress >= NEGOTIATION_FULL_THRESHOLD:
        return true_rank
    return surface_rank

func rank_options(progress: float) -> Array[String]:
    var options: Array[String] = []
    var surface := rank_number(surface_rank)
    var max_num := rank_number(max_supported_rank_for_progress(progress))
    for rank in RANKS:
        var num := rank_number(rank)
        if num >= surface and num <= max_num:
            options.append(rank)
    return options

