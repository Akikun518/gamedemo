class_name MissionManager
extends RefCounted

var _missions: Array[MissionData] = []
var _by_id: Dictionary = {}

func _init(records: Array[Dictionary]) -> void:
	for record in records:
		var mission := MissionData.from_json(record)
		_missions.append(mission)
		_by_id[mission.id] = mission

func all() -> Array[MissionData]:
	return _missions

func available(excluded_ids: Array[String]) -> Array[MissionData]:
	var available: Array[MissionData] = []
	for mission in _missions:
		if mission.unlock == "initial" and not excluded_ids.has(mission.id):
			available.append(mission)
	return available

func get_mission(id: String) -> MissionData:
	return _by_id.get(id) as MissionData
