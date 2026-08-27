class_name MissionResolver
extends RefCounted

const RANK_NUMBERS := {"D": 1, "C": 2, "B": 3, "A": 4, "S": 5}

func resolve(mission: MissionData, team: Array[MercenaryData], start_day: int) -> Dictionary:
    if mission == null or team.is_empty():
        return {"error": "A mission and at least one living mercenary are required."}

    var max_star := 0
    var team_roles: Array[String] = []
    var team_stats: Dictionary = {}
    for mercenary in team:
        max_star = maxi(max_star, mercenary.star)
        if not team_roles.has(mercenary.role):
            team_roles.append(mercenary.role)
        for stat in mercenary.stats:
            var stat_value := int(mercenary.stats.get(stat, 0))
            if int(team_stats.get(str(stat), 0)) < stat_value:
                team_stats[str(stat)] = stat_value

    var true_rank_number := int(RANK_NUMBERS.get(mission.true_rank, 1))
    var level_gap := true_rank_number - max_star
    var skill_shortfall := 0
    for required_skill in mission.required_skills:
        var stat := str(required_skill.get("stat", "combat"))
        var required_level := int(required_skill.get("level", 1))
        var team_level := int(team_stats.get(stat, 0))
        if team_level < required_level:
            skill_shortfall += required_level - team_level

    var success := level_gap < 3 and skill_shortfall == 0
    var modifier := 0
    if level_gap <= 0:
        modifier -= 1
    else:
        modifier += 1

    var role_matched := false
    for required_role in mission.required_roles:
        if team_roles.has(required_role):
            role_matched = true
            break
    if role_matched:
        modifier -= 1

    var failure_type := "FAILED_NO_CASUALTY"
    if not success:
        if skill_shortfall > 0 and true_rank_number >= 3:
            failure_type = "FAILED_INJURY"
        else:
            failure_type = "FAILED_NO_CASUALTY"

    var completion_days := 1
    if success:
        completion_days = clampi(mission.base_days + modifier, 1, 3)
    else:
        completion_days = 1

    var deadline_day := start_day + mission.time_limit_days
    var settlement_day := start_day + completion_days
    var timed_out := false
    if not mission.unlimited and settlement_day > deadline_day:
        timed_out = true
        settlement_day = deadline_day
        success = false

    var consequences := mission.on_failure if not success else mission.on_success
    var affection_delta := int(consequences.get("affection", 0))
    var affection_changes: Dictionary = {}
    for mercenary in team:
        affection_changes[mercenary.id] = affection_delta

    var new_intel: Array[String] = []
    for intel_id in consequences.get("unlock_intel", []) as Array:
        new_intel.append(str(intel_id))

    return {
        "mission_id": mission.id,
        "mission_title": mission.title,
        "success": success,
        "start_day": start_day,
        "completion_days": completion_days,
        "deadline_day": deadline_day,
        "settlement_day": settlement_day,
        "timed_out": timed_out,
        "due_day": settlement_day,
        "reward": mission.reward if success else 0,
        "damage": false,
        "death": false,
        "failure_type": failure_type if not success else "",
        "skill_shortfall": skill_shortfall,
        "affection_changes": affection_changes,
        "reputation_change": int(consequences.get("reputation", 0)),
        "new_intel": new_intel,
    }
