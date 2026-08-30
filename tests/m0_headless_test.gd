extends Node
## Autoload-aware M0.1 acceptance test. Run the .tscn, not `godot -s`.

const MAIN_SCENE := preload("res://scenes/main.tscn")

func _ready() -> void:
	await _run()

func _run() -> void:
	var errors: Array[String] = []
	_run_acceptance_tests(errors)
	_run_deadline_tests(errors)
	_run_contract_flow(errors)
	_run_debug_and_night_tests(errors)
	_run_counteroffer_tests(errors)
	_run_lowball_tests(errors)
	_run_skill_tests(errors)
	_run_night_loop_tests(errors)
	_run_intel_inventory_tests(errors)
	await _run_ui_smoke(errors)

	if errors.is_empty():
		print("M0 RUNTIME TEST PASSED")
		get_tree().quit(0)
	else:
		print("M0 RUNTIME TEST FAILED")
		for error in errors:
			print("- " + error)
		get_tree().quit(1)

func _run_acceptance_tests(errors: Array[String]) -> void:
	var merc := MercenaryData.from_json({
		"id": "probe", "name": "探针", "role": "assault", "star": 2,
		"likes": ["combat"], "dislikes": ["hostage"], "alive": true, "unlock": "initial",
	})
	var hostage_mission := MissionData.from_json({
		"id": "hostage", "title": "绑架", "tags": ["hostage", "combat"],
	})
	var talk_mission := MissionData.from_json({
		"id": "talk", "title": "谈判", "tags": ["talk"],
	})
	_expect(errors, not merc.accepts_mission(hostage_mission), "Mercenary should refuse a disliked mission.")
	_expect(errors, not merc.accepts_mission(talk_mission), "Mercenary should refuse when no liked tag matches.")

func _run_deadline_tests(errors: Array[String]) -> void:
	var resolver := MissionResolver.new()
	var merc := MercenaryData.from_json({
		"id": "weak", "name": "弱", "role": "assault", "star": 1,
		"likes": [], "dislikes": [], "alive": true, "unlock": "initial",
	})
	var mission := MissionData.from_json({
		"id": "rush", "title": "赶工", "true_rank": "B", "base_days": 3,
		"time_limit_days": 1, "unlimited": false, "tags": [],
	})
	var result := resolver.resolve(mission, [merc], 1)
	_expect(errors, bool(result.get("timed_out", false)), "Mission should time out when completion exceeds deadline.")
	_expect(errors, not bool(result.get("success", true)), "Timed-out mission should fail.")
	_expect(errors, int(result.get("settlement_day", 0)) == int(result.get("deadline_day", 0)), "Settlement should land on the deadline.")

func _run_contract_flow(errors: Array[String]) -> void:
	_expect(errors, GameState.current_day == 1, "Initial day should be 1.")
	_expect(errors, GameState.investigation_points == 3, "Day should start with three investigation points.")
	_expect(errors, GameState.pending_contracts().size() <= GameState.MAX_PENDING_CONTRACTS, "The board should cap pending contracts.")

	GameState.select_contract("find_cat")
	var contract := GameState.selected_contract()
	_expect(errors, contract != null, "find_cat should exist as a contract.")
	if contract == null:
		return

	_expect(errors, contract.state == Contract.STATE_PENDING, "New contract should start Pending.")
	_expect(errors, contract.mission.rank_options(contract.intel_progress()) == ["D"], "With no intel, only surface rank should be available.")

	for option in contract.mission.investigation_options:
		if GameState.investigation_points <= 0:
			break
		var result := GameState.investigate_contract(str(option.get("id", "")))
		_expect(errors, result.has("ok"), "Investigation should succeed with points remaining.")

	_expect(errors, contract.intel_progress() >= MissionData.NEGOTIATION_FULL_THRESHOLD, "Investigation should push intel progress past the full threshold.")
	var rank_options := contract.mission.rank_options(contract.intel_progress())
	_expect(errors, rank_options.has("B"), "Full intel should unlock reassessing to the true rank.")
	_expect(errors, not rank_options.has("S"), "Player should not be able to jump beyond the true rank.")

	var assess := GameState.assess_contract("B")
	_expect(errors, assess.has("ok"), "Assessing B with full intel should be allowed.")
	_expect(errors, not GameState.assess_contract("S").has("ok"), "Assessing S should be rejected without supporting intel.")

	var negotiate := GameState.negotiate_contract(600)
	_expect(errors, negotiate.get("response", "") == "Accepted", "A recommended reward should be accepted by the client.")
	var confirm := GameState.confirm_contract()
	_expect(errors, confirm.has("ok") and contract.confirmed, "Contract should be confirmed after client accepts.")

	var mercenary := _first_accepting_mercenary(contract)
	_expect(errors, mercenary != null, "At least one mercenary should be willing for the confirmed contract.")
	if mercenary == null:
		return
	GameState.selected_mercenary_ids = [mercenary.id]
	var dispatch := GameState.dispatch_contract()
	_expect(errors, dispatch.has("dispatched"), "A confirmed contract with a willing mercenary should dispatch.")
	_expect(errors, contract.state == Contract.STATE_DISPATCHED, "Dispatched contract should leave the pending board.")

func _run_ui_smoke(errors: Array[String]) -> void:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	var morning := main.get_node_or_null("PhaseHost/MorningPanel") as VBoxContainer
	_expect(errors, morning != null, "The main scene should show the Morning panel.")
	if morning == null:
		return
	var end_morning_button := morning.get_node_or_null("EndMorningButton") as Button
	_expect(errors, end_morning_button != null, "Morning should expose an end-day button.")
	var content := morning.get_node_or_null("ContentScroll/Content") as VBoxContainer
	_expect(errors, content != null, "Morning should render a scrollable content area.")
	if content == null:
		return

	var board_buttons := content.get_children()
	_expect(errors, not board_buttons.is_empty(), "Morning board should render at least one contract card.")
	if board_buttons.is_empty():
		return
	var first_card_node := board_buttons[0]
	var first_card: Button
	if first_card_node.has_node("Button"):
		first_card = first_card_node.get_node("Button") as Button
	else:
		first_card = first_card_node as Button
	_expect(errors, first_card != null, "The first contract card should contain a button.")
	if first_card == null:
		return
	first_card.pressed.emit()
	await get_tree().process_frame

	var morning_after := main.get_node_or_null("PhaseHost/MorningPanel") as VBoxContainer
	_expect(errors, morning_after != null, "Morning should still be visible after selecting a contract.")
	if morning_after == null:
		return
	var detail_has_client := false
	for child in (morning_after.get_node("ContentScroll/Content") as VBoxContainer).get_children():
		var label := child as Label
		if label != null and label.text.begins_with("委托人："):
			detail_has_client = true
			break
	_expect(errors, detail_has_client, "Clicking a contract should open its detail view.")

func _run_debug_and_night_tests(errors: Array[String]) -> void:
	var points_before := GameState.investigation_points
	GameState.add_investigation_point()
	_expect(errors, GameState.investigation_points == points_before + 1, "Debug should add an investigation point.")

	GameState.set_debug_mode(true)
	_expect(errors, GameState.debug_mode, "Debug mode should turn on.")

	var pending := GameState.pending_contracts()
	_expect(errors, not pending.is_empty(), "There should be pending contracts to debug.")
	if not pending.is_empty():
		var contract := pending[0]
		GameState.reveal_all_intel(contract.id)
		_expect(errors, contract.intel_progress() == 1.0, "Reveal-all should fill contract intel.")

	var night := GameState.collect_night_intel()
	_expect(errors, night.has("ok"), "Collecting night intel should find a related pending contract.")
	var has_night_hint := false
	for contract in GameState.pending_contracts():
		if not contract.night_intel_ids.is_empty():
			has_night_hint = true
			break
	_expect(errors, has_night_hint, "Night intel should mark a related pending contract.")

func _run_counteroffer_tests(errors: Array[String]) -> void:
	var contract := GameState.get_contract("find_cat")
	_expect(errors, contract != null, "find_cat should exist for counteroffer tests.")
	if contract == null:
		return
	GameState.select_contract(contract.id)
	GameState.reveal_all_intel(contract.id)
	var negotiate := GameState.negotiate_contract(700)
	_expect(errors, negotiate.get("response", "") == "CounterOffer", "A high but acceptable offer should trigger a counteroffer.")
	var accept := GameState.accept_counter_offer()
	_expect(errors, accept.has("ok"), "The client counteroffer should be acceptable.")
	_expect(errors, contract.negotiated_reward == contract.counter_offer, "Accepting the counteroffer should set the negotiated reward.")

func _run_lowball_tests(errors: Array[String]) -> void:
	_expect(errors, GameState.register_mercenary_lowball("probe") == 1, "First lowball should be registered.")
	_expect(errors, GameState.lowball_dialogue("probe") == "钱有点少。", "First lowball dialogue should be shown.")
	_expect(errors, GameState.register_mercenary_lowball("probe") == 2, "Second lowball should be registered.")
	_expect(errors, GameState.lowball_dialogue("probe") == "你最近是不是越来越会算账了？", "Second lowball dialogue should be shown.")
	_expect(errors, GameState.register_mercenary_lowball("probe") == 3, "Third lowball should be registered.")
	_expect(errors, GameState.lowball_dialogue("probe") == "以后这种价格别找我。", "Third lowball dialogue should be shown.")

	var mission := MissionData.from_json({
		"id": "lowball_probe", "title": "压价测试", "surface_rank": "D", "true_rank": "D", "reward": 100, "tags": [],
	})
	var contract := Contract.new(mission)
	contract.assessed_rank = "D"
	contract.negotiated_reward = 100
	var merc := MercenaryData.from_json({
		"id": "probe_merc", "name": "压价佣兵", "role": "assault", "star": 1,
		"likes": [], "dislikes": [], "alive": true, "unlock": "initial",
	})
	GameState.mercenary_lowball_count[merc.id] = 3
	var attitude := GameState.mercenary_attitude(merc, contract)
	_expect(errors, attitude.get("attitude", "") == "Refuse", "Three lowballs should make a mercenary refuse.")

func _run_skill_tests(errors: Array[String]) -> void:
	var resolver := MissionResolver.new()
	var mission := MissionData.from_json({
		"id": "skill_probe", "title": "技能测试", "true_rank": "B", "base_days": 2,
		"time_limit_days": 3, "unlimited": false, "tags": [],
		"required_skills": [{"stat": "hacking", "level": 6}],
	})
	var good_hacker := MercenaryData.from_json({
		"id": "good_hacker", "name": "好黑客", "role": "hacker", "star": 4,
		"stats": {"hacking": 9, "combat": 2, "persuasion": 2, "agility": 4, "cyberware": 5},
		"likes": [], "dislikes": [], "alive": true, "unlock": "initial",
	})
	var bad_hacker := MercenaryData.from_json({
		"id": "bad_hacker", "name": "差黑客", "role": "hacker", "star": 2,
		"stats": {"hacking": 3, "combat": 3, "persuasion": 3, "agility": 3, "cyberware": 3},
		"likes": [], "dislikes": [], "alive": true, "unlock": "initial",
	})
	_expect(errors, bool(resolver.resolve(mission, [good_hacker], 1).get("success", false)), "A skilled hacker should meet the required skill.")
	_expect(errors, not bool(resolver.resolve(mission, [bad_hacker], 1).get("success", true)), "An under-skilled hacker should fail the required skill.")

func _run_night_loop_tests(errors: Array[String]) -> void:
	GameState.select_guest("luo")
	var correct := GameState.serve_drink("luo", "neon_fog")
	_expect(errors, correct.get("reaction_tier", "") == "Perfect", "Serving the favorite drink should be Perfect.")
	_expect(errors, GameState.known_intel.has("cat_necklace"), "The guest intel should enter the IntelDatabase.")
	var wrong := GameState.serve_drink("luo", "short_circuit")
	_expect(errors, wrong.get("reaction_tier", "") == "Wrong", "Serving a disliked drink should be Wrong.")

func _run_intel_inventory_tests(errors: Array[String]) -> void:
	var before := GameState.intel_inventory.size()
	var added := GameState.add_intel_to_inventory("prism_ai")
	_expect(errors, added.has("ok"), "Intel should be addable to inventory.")
	_expect(errors, GameState.intel_inventory.size() == before + 1, "Adding intel should grow the inventory.")

	var money_before := GameState.money
	var bought := GameState.buy_intel("proto_lead", 100)
	_expect(errors, bought.has("ok"), "Buying intel should succeed with enough money.")
	_expect(errors, GameState.money == money_before - 100, "Buying intel should deduct money.")

	var sell_before := GameState.money
	var sold := GameState.sell_intel("prism_ai", 50)
	_expect(errors, sold.has("ok"), "Selling owned intel should succeed.")
	_expect(errors, GameState.money == sell_before + 50, "Selling intel should add money.")
	_expect(errors, GameState.intel_item("prism_ai").get("status", "") == "Sold", "Sold intel should be marked Sold.")

	var exchanged := GameState.exchange_intel("proto_lead", "debt_gang")
	_expect(errors, exchanged.has("ok"), "Exchanging intel should succeed.")
	_expect(errors, GameState.intel_item("proto_lead").get("status", "") == "Traded", "Offered intel should be marked Traded.")

func _first_accepting_mercenary(contract: Contract) -> MercenaryData:
	for mercenary in GameState.available_mercenaries():
		var attitude := GameState.mercenary_attitude(mercenary, contract)
		if attitude.get("attitude", "Refuse") != "Refuse":
			return mercenary
	return null

func _expect(errors: Array[String], condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
