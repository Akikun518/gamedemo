extends Node
## Authoritative game state. Scene scripts read and request transitions; they never own state.

var current_day := 1
var current_phase := TimeSystem.MORNING
var money := 500
var reputation := 0
var compensation_due := 0

var selected_mercenary_ids: Array[String] = []
var selected_contract_id := ""
var selected_guest_id := ""
var investigation_points := 3
var debug_mode := false
var debug_mercenary_override: Dictionary = {}
var mercenary_lowball_count: Dictionary = {}
var contracts: Array[Contract] = []
var active_missions: Array[Dictionary] = []
var resolved_results: Array[Dictionary] = []
var pending_results: Array[Dictionary] = []
var known_intel: Array[String] = []
var latest_result: Dictionary = {}

var mercenary_manager: MercenaryManager
var mission_manager: MissionManager
var drink_records: Array[Dictionary] = []
var guest_records: Array[Dictionary] = []
var faction_records: Array[Dictionary] = []
var intel_records: Array[Dictionary] = []

var _resolver := MissionResolver.new()
var _intel_by_id: Dictionary = {}

const MAX_PENDING_CONTRACTS := 6

signal state_changed

func _ready() -> void:
	mercenary_manager = MercenaryManager.new(DataRepository.load_records("res://data/mercenaries"))
	mission_manager = MissionManager.new(DataRepository.load_records("res://data/missions"))
	drink_records = DataRepository.load_records("res://data/drinks")
	guest_records = DataRepository.load_records("res://data/guests")
	faction_records = DataRepository.load_records("res://data/factions")
	intel_records = DataRepository.load_records("res://data/intel")
	for record in intel_records:
		_intel_by_id[str(record.get("id", ""))] = record
	_init_contracts()
	_refresh_night_intel()

func available_mercenaries() -> Array[MercenaryData]:
	return mercenary_manager.available()

func active_mission_ids() -> Array[String]:
	var ids: Array[String] = []
	for assignment in active_missions:
		ids.append(str(assignment.get("mission_id", "")))
	return ids

func available_missions() -> Array[MissionData]:
	return mission_manager.available(active_mission_ids())

func available_drinks() -> Array[Dictionary]:
	return drink_records

func guests() -> Array[Dictionary]:
	return guest_records

func select_guest(guest_id: String) -> void:
	selected_guest_id = guest_id
	state_changed.emit()

func serve_drink(drink_id: String) -> Dictionary:
	if selected_guest_id.is_empty():
		return {"error": "请先选择客人。"}
	var guest := {}
	for candidate in guest_records:
		if str(candidate.get("id", "")) == selected_guest_id:
			guest = candidate
			break
	if guest.is_empty():
		return {"error": "未知客人。"}
	var preferred := str(guest.get("preferred_drink", ""))
	if preferred != drink_id:
		return {"ok": false, "correct": false, "message": "客人不太满意这杯酒。"}
	var intel_id := str(guest.get("intel_id", ""))
	if not known_intel.has(intel_id):
		known_intel.append(intel_id)
	_refresh_night_intel()
	state_changed.emit()
	return {"ok": true, "correct": true, "message": str(guest.get("dialogue", "客人说了一些有用的信息。")), "intel_id": intel_id}

func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	state_changed.emit()

func add_investigation_point() -> void:
	investigation_points += 1
	state_changed.emit()

func reveal_all_intel(contract_id: String) -> void:
	var contract := get_contract(contract_id)
	if contract == null:
		return
	for entry in contract.mission.intel_entries:
		var intel_id := str(entry.get("id", ""))
		if not contract.discovered_intel.has(intel_id):
			contract.discovered_intel.append(intel_id)
	contract.state = Contract.STATE_READY_FOR_ASSESSMENT
	state_changed.emit()

func debug_expire_contract(contract_id: String) -> void:
	var contract := get_contract(contract_id)
	if contract == null:
		return
	contract.remaining_days = 0
	contract.state = Contract.STATE_EXPIRED
	_apply_expiration_penalty(contract)
	state_changed.emit()

func debug_set_expiration(contract_id: String, days: int) -> void:
	var contract := get_contract(contract_id)
	if contract == null:
		return
	contract.remaining_days = days
	state_changed.emit()

func force_client_accept() -> void:
	var contract := selected_contract()
	if contract == null:
		return
	contract.client_response = "Accepted"
	state_changed.emit()

func force_client_reject() -> void:
	var contract := selected_contract()
	if contract == null:
		return
	contract.client_response = "Rejected"
	state_changed.emit()

func force_mercenary_accept(mercenary_id: String) -> void:
	debug_mercenary_override[mercenary_id] = "Eager"
	state_changed.emit()

func force_mercenary_refuse(mercenary_id: String) -> void:
	debug_mercenary_override[mercenary_id] = "Refuse"
	state_changed.emit()

func register_mercenary_lowball(mercenary_id: String) -> int:
	var count := int(mercenary_lowball_count.get(mercenary_id, 0)) + 1
	mercenary_lowball_count[mercenary_id] = count
	return count

func lowball_dialogue(mercenary_id: String) -> String:
	var count := int(mercenary_lowball_count.get(mercenary_id, 0))
	if count >= 3:
		return "以后这种价格别找我。"
	if count == 2:
		return "你小子是不是越来越会算账了？"
	if count == 1:
		return "这点钱打发乞丐呢？！"
	return ""

func collect_night_intel() -> Dictionary:
	for record in intel_records:
		var intel_id := str(record.get("id", ""))
		if known_intel.has(intel_id):
			continue
		var related := str(record.get("related_mission", ""))
		var target := get_contract(related)
		var target_is_pending := false
		for pending in pending_contracts():
			if pending.id == related:
				target_is_pending = true
				break
		if target != null and target_is_pending:
			known_intel.append(intel_id)
			_refresh_night_intel()
			EventBus.notice.emit("夜晚获得情报：%s" % str(record.get("text", intel_id)))
			state_changed.emit()
			return {"ok": true, "intel_id": intel_id}
	return {"error": "没有新的相关情报。"}

func _refresh_night_intel() -> void:
	for contract in contracts:
		contract.night_intel_ids.clear()
		for record in intel_records:
			if str(record.get("related_mission", "")) == contract.mission.id and known_intel.has(str(record.get("id", ""))):
				contract.night_intel_ids.append(str(record.get("id", "")))

func night_intel_text(contract: Contract) -> String:
	var texts: Array[String] = []
	for intel_id in contract.night_intel_ids:
		texts.append(str(get_intel(intel_id).get("text", intel_id)))
	return "；".join(texts)

func _init_contracts() -> void:
	contracts.clear()
	var pending_normal := 0
	for mission in mission_manager.all():
		var contract := Contract.new(mission)
		if mission.is_main_story or mission.no_expiration:
			contracts.append(contract)
		elif pending_normal < MAX_PENDING_CONTRACTS:
			contracts.append(contract)
			pending_normal += 1
	contracts.sort_custom(func(a: Contract, b: Contract) -> bool: return a.mission.title < b.mission.title)

func pending_contracts() -> Array[Contract]:
	var pending: Array[Contract] = []
	for contract in contracts:
		if contract.state != Contract.STATE_EXPIRED and contract.state != Contract.STATE_REJECTED and contract.state != Contract.STATE_DISPATCHED and contract.state != Contract.STATE_COMPLETED:
			pending.append(contract)
	return pending

func get_contract(id: String) -> Contract:
	for contract in contracts:
		if contract.id == id:
			return contract
	return null

func select_contract(id: String) -> void:
	selected_contract_id = id
	selected_mercenary_ids.clear()
	state_changed.emit()

func selected_contract() -> Contract:
	return get_contract(selected_contract_id)

func selected_contract_rank_options() -> Array[String]:
	var contract := selected_contract()
	if contract == null:
		return []
	return contract.rank_options()

func investigate_contract(option_id: String) -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if investigation_points <= 0:
		return {"error": "没有调查点了。"}
	var option := {}
	for candidate in contract.mission.investigation_options:
		if str(candidate.get("id", "")) == option_id:
			option = candidate
			break
	if option.is_empty():
		return {"error": "Unknown investigation option."}
	var intel_id := str(option.get("intel_id", ""))
	if contract.discovered_intel.has(intel_id):
		return {"error": "已经调查过这条线索。"}
	investigation_points -= int(option.get("cost", 1))
	contract.discovered_intel.append(intel_id)
	if contract.state == Contract.STATE_PENDING:
		contract.state = Contract.STATE_INVESTIGATING
	if contract.mission.investigation_options.size() <= contract.discovered_intel.size():
		contract.state = Contract.STATE_READY_FOR_ASSESSMENT
	EventBus.notice.emit("发现新情报：%s" % str(option.get("label", "调查")))
	state_changed.emit()
	return {"ok": true, "intel_id": intel_id, "points_left": investigation_points}

func assess_contract(rank: String) -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if not contract.rank_options().has(rank):
		return {"error": "当前情报不足以把委托评估为该等级。"}
	contract.assessed_rank = rank
	contract.state = Contract.STATE_READY_FOR_ASSESSMENT
	state_changed.emit()
	return {"ok": true, "assessed_rank": rank}

func negotiate_contract(reward: int) -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if contract.state != Contract.STATE_READY_FOR_ASSESSMENT and contract.state != Contract.STATE_NEGOTIATING:
		return {"error": "先完成评估再谈判。"}
	contract.negotiated_reward = reward
	contract.state = Contract.STATE_AWAITING_CLIENT
	var mission := contract.mission
	var window := contract.negotiation_window()
	if reward <= mission.recommended_reward:
		contract.client_response = "Accepted"
	elif reward <= window:
		contract.client_response = "CounterOffer"
		contract.counter_offer = mission.recommended_reward
	else:
		contract.client_response = "Rejected"
	state_changed.emit()
	return {"ok": true, "response": contract.client_response, "window": window}

func accept_counter_offer() -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if contract.client_response != "CounterOffer":
		return {"error": "No counteroffer to accept."}
	contract.negotiated_reward = contract.counter_offer
	contract.client_response = "Accepted"
	state_changed.emit()
	return {"ok": true, "reward": contract.negotiated_reward}

func confirm_contract() -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if contract.client_response == "Rejected":
		return {"error": "客户拒绝了报价，需要重新报价。"}
	if contract.client_response == "CounterOffer":
		contract.negotiated_reward = contract.mission.recommended_reward
	contract.state = Contract.STATE_CONFIRMED
	contract.confirmed = true
	state_changed.emit()
	return {"ok": true, "reward": contract.negotiated_reward}

func reject_contract(id: String) -> void:
	var contract := get_contract(id)
	if contract == null:
		return
	contract.state = Contract.STATE_REJECTED
	_apply_client_penalty(contract, 2, 0, 0)
	if selected_contract_id == id:
		selected_contract_id = ""
	state_changed.emit()

func mercenary_attitude(mercenary: MercenaryData, contract: Contract) -> Dictionary:
	if debug_mercenary_override.has(mercenary.id):
		var forced := str(debug_mercenary_override.get(mercenary.id, ""))
		if forced == "Refuse":
			return {"attitude": "Refuse", "reason": "Debug 强制拒绝。"}
		return {"attitude": "Eager", "reason": "Debug 强制接受。"}
	if int(mercenary_lowball_count.get(mercenary.id, 0)) >= 3:
		return {"attitude": "Refuse", "reason": "以后这种价格别找我。"}
	if not mercenary.accepts_mission(contract.mission):
		return {"attitude": "Refuse", "reason": mercenary.refusal_reason(contract.mission)}
	var risk := contract.mission.rank_number(contract.assessed_rank)
	var expected := contract.mission.recommended_reward + maxi(0, risk - mercenary.star) * 200
	var reward := contract.negotiated_reward
	if reward >= int(expected * 1.2):
		return {"attitude": "Eager", "reason": "钱给得够，风险可接受。", "expected": expected}
	if reward >= expected:
		return {"attitude": "Willing", "reason": "价格合理，可以接。", "expected": expected}
	if reward >= int(expected * 0.7):
		return {"attitude": "Reluctant", "reason": "钱有点少，但能谈。", "expected": expected}
	return {"attitude": "Refuse", "reason": "这个价格配不上这个风险。", "expected": expected}

func dispatch_contract() -> Dictionary:
	var contract := selected_contract()
	if contract == null:
		return {"error": "No contract selected."}
	if not contract.confirmed:
		return {"error": "合同尚未确认。"}
	if selected_mercenary_ids.is_empty():
		return {"error": "请选择至少一名佣兵。"}
	var team := selected_team()
	if team.is_empty():
		return {"error": "没有可用的佣兵。"}
	for mercenary in team:
		var attitude := mercenary_attitude(mercenary, contract)
		if attitude.get("attitude", "Refuse") == "Refuse":
			return {"error": "佣兵拒绝了这个委托。"}
		if attitude.get("attitude", "Reluctant") == "Reluctant":
			var count := register_mercenary_lowball(mercenary.id)
			if count >= 3:
				EventBus.notice.emit("%s：%s" % [mercenary.display_name, lowball_dialogue(mercenary.id)])
				return {"error": "佣兵拒绝了这个委托。"}

	var result := _resolver.resolve(contract.mission, team, current_day)
	result["reward"] = contract.negotiated_reward if bool(result.get("success", false)) else 0
	var settlement_day := int(result.get("settlement_day", current_day))
	active_missions.append({
		"mission_id": contract.mission.id,
		"contract_id": contract.id,
		"mercenary_ids": selected_mercenary_ids.duplicate(),
		"start_day": current_day,
		"settlement_day": settlement_day,
		"timed_out": bool(result.get("timed_out", false)),
		"unlimited": contract.mission.unlimited,
		"reward": contract.negotiated_reward,
	})
	contract.state = Contract.STATE_DISPATCHED
	selected_mercenary_ids.clear()
	EventBus.mission_dispatched.emit({"contract_id": contract.id, "mission_id": contract.mission.id})
	EventBus.notice.emit("已派遣「%s」，预计第 %d 天结算。" % [contract.mission.title, settlement_day])
	state_changed.emit()
	return {"dispatched": true, "contract_id": contract.id, "settlement_day": settlement_day}

func get_intel(id: String) -> Dictionary:
	return _intel_by_id.get(id, {}) as Dictionary

func toggle_mercenary(id: String) -> void:
	var index := selected_mercenary_ids.find(id)
	if index >= 0:
		selected_mercenary_ids.remove_at(index)
	else:
		selected_mercenary_ids.append(id)
	state_changed.emit()

func selected_team() -> Array[MercenaryData]:
	var team: Array[MercenaryData] = []
	for id in selected_mercenary_ids:
		var mercenary := mercenary_manager.get_mercenary(id)
		if mercenary != null and mercenary.alive:
			team.append(mercenary)
	return team

func dispatch_mission(mission_id: String) -> Dictionary:
	if current_phase != TimeSystem.MORNING:
		return {"error": "Missions can only be dispatched in the morning."}
	if selected_mercenary_ids.is_empty():
		return {"error": "Select at least one mercenary."}

	var mission := mission_manager.get_mission(mission_id)
	if mission == null:
		return {"error": "Unknown mission."}

	var team := selected_team()
	if team.is_empty():
		return {"error": "No living selected mercenary."}
	for mercenary in team:
		if not mercenary.accepts_mission(mission):
			return {"error": "One selected mercenary refuses this mission."}

	var result := _resolver.resolve(mission, team, current_day)
	var settlement_day := int(result.get("settlement_day", current_day))
	var assignment := {
		"mission_id": mission.id,
		"mercenary_ids": selected_mercenary_ids.duplicate(),
		"start_day": current_day,
		"settlement_day": settlement_day,
		"deadline_day": int(result.get("deadline_day", current_day)),
		"timed_out": bool(result.get("timed_out", false)),
		"unlimited": mission.unlimited,
	}
	active_missions.append(assignment)
	selected_mercenary_ids.clear()
	EventBus.mission_dispatched.emit(assignment)
	EventBus.notice.emit("已派遣「%s」，预计第 %d 天结算。" % [mission.title, settlement_day])
	state_changed.emit()
	return {"dispatched": true, "mission_id": mission.id, "settlement_day": settlement_day}

func continue_from_result() -> bool:
	if current_phase != TimeSystem.RESULT:
		return false
	pending_results.pop_front()
	if pending_results.is_empty():
		current_phase = TimeSystem.MORNING
	else:
		latest_result = pending_results[0]
	EventBus.phase_changed.emit(current_day, current_phase)
	state_changed.emit()
	return true

func end_morning() -> bool:
	if current_phase != TimeSystem.MORNING:
		return false
	current_phase = TimeSystem.EVENING
	EventBus.phase_changed.emit(current_day, current_phase)
	state_changed.emit()
	return true

func end_evening() -> bool:
	if current_phase != TimeSystem.EVENING:
		return false
	current_day += 1
	current_phase = TimeSystem.MORNING
	investigation_points = 3
	selected_mercenary_ids.clear()
	EventBus.day_advanced.emit(current_day)
	_tick_contract_expiration()
	_settle_due_missions()
	EventBus.phase_changed.emit(current_day, current_phase)
	state_changed.emit()
	return true

func _tick_contract_expiration() -> void:
	for contract in pending_contracts():
		if contract.mission.no_expiration or contract.mission.is_main_story:
			continue
		contract.remaining_days -= 1
		if contract.remaining_days <= 0:
			contract.state = Contract.STATE_EXPIRED
			_apply_expiration_penalty(contract)

func _apply_expiration_penalty(contract: Contract) -> void:
	var penalty := contract.mission.expiration_consequences
	var reputation_penalty := int(penalty.get("reputationPenalty", 1))
	var client_affection := int(penalty.get("clientAffectionPenalty", 5))
	var faction_penalty := int(penalty.get("factionPenalty", 3))
	_apply_client_penalty(contract, client_affection, faction_penalty, reputation_penalty)

func _apply_client_penalty(contract: Contract, client_affection: int, faction_penalty: int, reputation_penalty: int) -> void:
	if reputation_penalty > 0:
		reputation -= reputation_penalty
	for faction in faction_records:
		if str(faction.get("id", "")) == contract.mission.client:
			faction["affection"] = int(faction.get("affection", 0)) - faction_penalty

func _settle_due_missions() -> void:
	for assignment in active_missions.duplicate():
		if int(assignment.get("settlement_day", 9999)) > current_day:
			continue
		var mission := mission_manager.get_mission(str(assignment.get("mission_id", "")))
		if mission == null:
			continue

		var team: Array[MercenaryData] = []
		for id in assignment.get("mercenary_ids", []) as Array:
			var mercenary := mercenary_manager.get_mercenary(str(id))
			if mercenary != null and mercenary.alive:
				team.append(mercenary)

		var result := _resolver.resolve(mission, team, int(assignment.get("start_day", current_day)))
		if bool(result.get("death", false)):
			result["dead_mercenary_ids"] = _pick_dead_mercenaries(team)
			result["compensation_due"] = (result["dead_mercenary_ids"] as Array).size() * 100
		if bool(result.get("success", false)):
			result["reward"] = int(assignment.get("reward", result.get("reward", 0)))
		if bool(assignment.get("timed_out", false)):
			result["success"] = false
			result["reward"] = 0
			result["reputation_change"] = int(mission.on_failure.get("reputation", 0))
			result["affection_changes"] = {}
			for mercenary in team:
				result["affection_changes"][mercenary.id] = int(mission.on_failure.get("affection", 0))

		_apply_result(mission, result)
		resolved_results.append(result)
		pending_results.append(result)
		var contract := get_contract(str(assignment.get("contract_id", "")))
		if contract != null:
			contract.state = Contract.STATE_COMPLETED
		active_missions.erase(assignment)
		EventBus.mission_resolved.emit(result)

	if not pending_results.is_empty():
		latest_result = pending_results[0]
		current_phase = TimeSystem.RESULT

func phase_label() -> String:
	match current_phase:
		TimeSystem.MORNING:
			return "白天 · 派遣"
		TimeSystem.RESULT:
			return "结算 · 复盘"
		TimeSystem.EVENING:
			return "晚上 · 酒吧"
		_:
			return current_phase

func _apply_result(mission: MissionData, result: Dictionary) -> void:
	money += int(result.get("reward", 0))
	reputation += int(result.get("reputation_change", 0))

	var dead_ids: Array[String] = []
	for id in result.get("dead_mercenary_ids", []) as Array:
		dead_ids.append(str(id))
		var mercenary := mercenary_manager.get_mercenary(str(id))
		if mercenary != null:
			mercenary.alive = false
			mercenary.affection = 0
	if not dead_ids.is_empty():
		reputation -= 20 * dead_ids.size()
		compensation_due += int(result.get("compensation_due", 0))

	var changes := result.get("affection_changes", {}) as Dictionary
	for mercenary_id in changes:
		if dead_ids.has(str(mercenary_id)):
			continue
		var mercenary := mercenary_manager.get_mercenary(str(mercenary_id))
		if mercenary != null:
			mercenary.affection = clampi(mercenary.affection + int(changes[mercenary_id]), 0, 100)

	for intel_id in result.get("new_intel", []) as Array:
		var id := str(intel_id)
		if not known_intel.has(id) and _intel_by_id.has(id):
			known_intel.append(id)

func _pick_dead_mercenaries(team: Array[MercenaryData]) -> Array[String]:
	if team.is_empty():
		return []
	var weakest := team[0]
	for mercenary in team:
		var weak_score := int(weakest.stats.get("combat", 0)) + int(weakest.stats.get("agility", 0))
		var score := int(mercenary.stats.get("combat", 0)) + int(mercenary.stats.get("agility", 0))
		if score < weak_score:
			weakest = mercenary
	return [weakest.id]

func pay_compensation() -> Dictionary:
	if compensation_due <= 0:
		return {"error": "没有待支付赔偿。"}
	if money < compensation_due:
		return {"error": "资金不足。"}
	money -= compensation_due
	compensation_due = 0
	state_changed.emit()
	return {"ok": true}

func decline_compensation() -> Dictionary:
	if compensation_due <= 0:
		return {"error": "没有待支付赔偿。"}
	compensation_due = 0
	reputation -= 5
	state_changed.emit()
	return {"ok": true}
