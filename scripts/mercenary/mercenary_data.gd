class_name MercenaryData
extends RefCounted

var id := ""
var display_name := ""
var role := ""
var star := 1
var stats: Dictionary = {}
var affection := 0
var price := 0
var personality := ""
var taboo := ""
var likes: Array[String] = []
var dislikes: Array[String] = []
var alive := true
var unlock := "initial"

static func from_json(record: Dictionary) -> MercenaryData:
    var data := MercenaryData.new()
    data.id = str(record.get("id", ""))
    data.display_name = str(record.get("name", data.id))
    data.role = str(record.get("role", ""))
    data.star = int(record.get("star", 1))
    data.stats = record.get("stats", {}) as Dictionary
    data.affection = int(record.get("affection", 0))
    data.price = int(record.get("price", 0))
    data.personality = str(record.get("personality", ""))
    data.taboo = str(record.get("taboo", ""))
    for like in record.get("likes", []) as Array:
        data.likes.append(str(like))
    for dislike in record.get("dislikes", []) as Array:
        data.dislikes.append(str(dislike))
    data.alive = bool(record.get("alive", true))
    data.unlock = str(record.get("unlock", "initial"))
    return data

func summary() -> String:
    return "%s  |  %s  |  %d星  |  好感度 %d/100" % [display_name, role, star, affection]

func summary_for_mission(mission: MissionData) -> String:
    var line := "%s  |  %s  |  %d星  |  好感度 %d/100" % [display_name, role, star, affection]
    if not personality.is_empty():
        line += "  |  %s" % personality
    if accepts_mission(mission):
        return line + "  |  会接"
    return line + "  |  " + refusal_reason(mission)

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
            if not taboo.is_empty():
                return "不接：%s" % taboo
            return "不接：讨厌 %s" % dislike
    return "不接：不感兴趣"
