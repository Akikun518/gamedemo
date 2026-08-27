extends VBoxContainer
## M0.1 fixer terminal: board, detail, investigate, assess, negotiate, mercenary selection.

signal end_morning_requested

const MODE_BOARD := "board"
const MODE_DETAIL := "detail"
const MODE_ASSESS := "assess"
const MODE_NEGOTIATE := "negotiate"
const MODE_MERCENARY := "mercenary"
const MODE_ROSTER := "roster"
const CONTRACT_CARD := preload("res://scenes/morning/contract_card.tscn")

var _mode := MODE_BOARD

@onready var title_label: Label = $Title
@onready var stats_label: Label = $StatsLabel
@onready var roster_button: Button = $RosterButton
@onready var content: VBoxContainer = $ContentScroll/Content
@onready var back_button: Button = $BackButton
@onready var debug_button: Button = $DebugButton
@onready var end_morning_button: Button = $EndMorningButton

func _ready() -> void:
	GameState.state_changed.connect(_render)

func setup(_missions: Array[MissionData], _mercenaries: Array[MercenaryData], _money: int, _reputation: int) -> void:
	_mode = MODE_BOARD
	_render()

func _render() -> void:
	title_label.text = "FIXER TERMINAL · Day %d" % GameState.current_day
	stats_label.text = "资金：%d   信誉：%d   调查点：%d" % [GameState.money, GameState.reputation, GameState.investigation_points]
	back_button.visible = _mode != MODE_BOARD
	roster_button.visible = _mode == MODE_BOARD
	debug_button.text = "Debug: ON" if GameState.debug_mode else "Debug"
	for child in content.get_children():
		child.queue_free()

	match _mode:
		MODE_BOARD:
			_render_board()
		MODE_DETAIL:
			_render_detail()
		MODE_ASSESS:
			_render_assess()
		MODE_NEGOTIATE:
			_render_negotiate()
		MODE_MERCENARY:
			_render_mercenary()
		MODE_ROSTER:
			_render_roster()

func _render_board() -> void:
	var contracts := GameState.pending_contracts()
	if contracts.is_empty():
		_add_label("今天没有待处理的委托。")
	else:
		for contract in contracts:
			var card := CONTRACT_CARD.instantiate()
			content.add_child(card)
			card.setup(contract)
			card.pressed.connect(func(id: String) -> void: _open_contract(id))
	if GameState.debug_mode:
		_render_debug_menu()

func _render_roster() -> void:
	_add_label("可用佣兵")
	for mercenary in GameState.available_mercenaries():
		var stats := mercenary.stats
		var line := "%s  |  %s  |  %d星  |  好感度 %d/100\n战力 %d / 黑客 %d / 口才 %d / 敏捷 %d / 义体 %d" % [
			mercenary.display_name,
			mercenary.role,
			mercenary.star,
			mercenary.affection,
			int(stats.get("combat", 0)),
			int(stats.get("hacking", 0)),
			int(stats.get("persuasion", 0)),
			int(stats.get("agility", 0)),
			int(stats.get("cyberware", 0)),
		]
		if not mercenary.personality.is_empty():
			line += "\n性格：%s" % mercenary.personality
		if not mercenary.taboo.is_empty():
			line += "\n禁忌：%s" % mercenary.taboo
		if not mercenary.likes.is_empty():
			line += "\n喜欢：%s" % "、".join(mercenary.likes)
		if not mercenary.dislikes.is_empty():
			line += "\n讨厌：%s" % "、".join(mercenary.dislikes)
		_add_label(line)

func _render_debug_menu() -> void:
	_add_label("--- DEBUG ---")
	_add_button("调查点 +1", func() -> void: GameState.add_investigation_point(); _render())
	var contract := GameState.selected_contract()
	if contract != null:
		_add_button("揭示当前委托全部情报", func() -> void: GameState.reveal_all_intel(contract.id); _render())
		_add_button("让当前委托过期", func() -> void: GameState.debug_expire_contract(contract.id); _render())
		_add_button("强制客户接受", func() -> void: GameState.force_client_accept(); _render())
		_add_button("强制客户拒绝", func() -> void: GameState.force_client_reject(); _render())

func _open_contract(id: String) -> void:
	GameState.select_contract(id)
	_mode = MODE_DETAIL
	_render()

func _render_detail() -> void:
	var contract := GameState.selected_contract()
	if contract == null:
		_mode = MODE_BOARD
		_render()
		return
	var mission := contract.mission
	_add_label(mission.title)
	_add_label("委托人：%s" % mission.client)
	_add_label("表面等级：%s    表面报酬：%d    剩余时间：%d 天" % [mission.surface_rank, mission.surface_reward, contract.remaining_days])
	_add_label("已知情报：%s    状态：%s" % [contract.intel_summary(), contract.state])
	if not contract.night_intel_ids.is_empty():
		_add_label("[已有相关情报] %s" % GameState.night_intel_text(contract))

	if contract.confirmed:
		_add_button("选择佣兵并派遣", func() -> void: _mode = MODE_MERCENARY; _render())
	else:
		for option in mission.investigation_options:
			var label := str(option.get("label", "调查"))
			var cost := int(option.get("cost", 1))
			var option_id := str(option.get("id", ""))
			_add_button("%s（%d 调查点）" % [label, cost], func() -> void: _investigate(option_id))
		_add_button("重新评估委托", func() -> void: _mode = MODE_ASSESS; _render())
		_add_button("进入价格谈判", func() -> void: _mode = MODE_NEGOTIATE; _render())
		_add_button("拒绝委托", func() -> void: _reject_contract())

func _investigate(option_id: String) -> void:
	GameState.investigate_contract(option_id)
	_render()

func _reject_contract() -> void:
	var contract := GameState.selected_contract()
	if contract != null:
		GameState.reject_contract(contract.id)
	_mode = MODE_BOARD
	_render()

func _render_assess() -> void:
	var contract := GameState.selected_contract()
	if contract == null:
		_mode = MODE_BOARD
		_render()
		return
	_add_label("当前表面等级：%s" % contract.mission.surface_rank)
	_add_label("已知情报：%s" % contract.intel_summary())
	if not contract.risk_flags().is_empty():
		_add_label("隐藏风险：%s" % "、".join(contract.risk_flags()))
	_add_label("可设置等级：")
	for rank in GameState.selected_contract_rank_options():
		_add_button(rank, func() -> void: _assess(rank))

func _assess(rank: String) -> void:
	GameState.assess_contract(rank)
	_mode = MODE_DETAIL
	_render()

func _render_negotiate() -> void:
	var contract := GameState.selected_contract()
	if contract == null:
		_mode = MODE_BOARD
		_render()
		return
	_add_label("客户原报价：%d" % contract.mission.surface_reward)
	_add_label("推荐报价区间：%d ～ %d" % [contract.mission.minimum_reasonable_reward, contract.negotiation_window()])
	var input := LineEdit.new()
	input.placeholder_text = str(contract.mission.recommended_reward)
	content.add_child(input)
	var submit := Button.new()
	submit.text = "提交报价"
	submit.pressed.connect(func() -> void: _submit_negotiation(input.text))
	content.add_child(submit)
	if not contract.client_response.is_empty():
		_add_label("客户回应：%s" % contract.client_response)
		if contract.client_response == "CounterOffer":
			_add_label("客户还价：%d" % contract.counter_offer)
			_add_button("接受还价", func() -> void: _accept_counter_offer())
		if contract.client_response == "Accepted":
			_add_button("确认合同", func() -> void: _confirm())

func _submit_negotiation(text: String) -> void:
	var reward := int(text)
	GameState.negotiate_contract(reward)
	_render()

func _confirm() -> void:
	GameState.confirm_contract()
	_mode = MODE_DETAIL
	_render()

func _accept_counter_offer() -> void:
	GameState.accept_counter_offer()
	_render()

func _render_mercenary() -> void:
	var contract := GameState.selected_contract()
	if contract == null:
		_mode = MODE_BOARD
		_render()
		return
	_add_label("%s   等级：%s   报酬：%d" % [contract.mission.title, contract.assessed_rank, contract.negotiated_reward])
	for mercenary in GameState.available_mercenaries():
		var attitude := GameState.mercenary_attitude(mercenary, contract)
		var checkbox := CheckBox.new()
		checkbox.text = "%s  |  %s  |  %s" % [mercenary.display_name, attitude.get("attitude", "Refuse"), attitude.get("reason", "")]
		checkbox.disabled = attitude.get("attitude", "Refuse") == "Refuse"
		checkbox.toggle_mode = true
		checkbox.toggled.connect(func(selected: bool) -> void: _toggle_mercenary(mercenary.id, selected))
		content.add_child(checkbox)
	var dispatch := Button.new()
	dispatch.text = "确认派遣"
	dispatch.disabled = not contract.confirmed
	dispatch.pressed.connect(func() -> void: _dispatch())
	content.add_child(dispatch)

func _toggle_mercenary(id: String, selected: bool) -> void:
	var index := GameState.selected_mercenary_ids.find(id)
	if selected and index < 0:
		if GameState.selected_mercenary_ids.size() >= 3:
			return
		GameState.selected_mercenary_ids.append(id)
	elif not selected and index >= 0:
		GameState.selected_mercenary_ids.remove_at(index)

func _dispatch() -> void:
	var result := GameState.dispatch_contract()
	if result.has("error"):
		_add_label(str(result.get("error", "派遣失败")))
	else:
		_mode = MODE_BOARD
		_render()

func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

func _add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	content.add_child(button)

func _on_back_button_pressed() -> void:
	if _mode == MODE_DETAIL:
		_mode = MODE_BOARD
	elif _mode == MODE_ROSTER:
		_mode = MODE_BOARD
	else:
		_mode = MODE_DETAIL
	_render()

func _on_roster_button_pressed() -> void:
	_mode = MODE_ROSTER
	_render()

func _on_debug_button_pressed() -> void:
	GameState.set_debug_mode(not GameState.debug_mode)
	_render()

func _on_end_morning_button_pressed() -> void:
	end_morning_requested.emit()
