class_name MercenaryManager
extends RefCounted

var _mercenaries: Array[MercenaryData] = []
var _by_id: Dictionary = {}

func _init(records: Array[Dictionary]) -> void:
	for record in records:
		var mercenary := MercenaryData.from_json(record)
		_mercenaries.append(mercenary)
		_by_id[mercenary.id] = mercenary

func all() -> Array[MercenaryData]:
	return _mercenaries

func available() -> Array[MercenaryData]:
	var available: Array[MercenaryData] = []
	for mercenary in _mercenaries:
		if mercenary.alive and mercenary.unlock == "initial":
			available.append(mercenary)
	return available

func get_mercenary(id: String) -> MercenaryData:
	return _by_id.get(id) as MercenaryData
