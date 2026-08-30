extends VBoxContainer
## Minimal evening loop: choose a guest, serve a drink, unlock intel.

signal end_day_requested

var _drinks: Array[Dictionary] = []
var _guests: Array[Dictionary] = []

@onready var drink_label: Label = $DrinkLabel
@onready var stamina_label: Label = $StaminaLabel
@onready var guest_list: VBoxContainer = $GuestScroll/GuestList
@onready var drink_list: VBoxContainer = $DrinkScroll/DrinkList
@onready var status_label: Label = $StatusLabel
@onready var deep_talk_button: Button = $DeepTalkButton
@onready var end_day_button: Button = $EndDayButton

func setup(drinks: Array[Dictionary], guests: Array[Dictionary], current_day: int) -> void:
	_drinks = drinks
	_guests = guests
	drink_label.text = "第 %d 天晚上" % current_day
	stamina_label.text = "精力：%d" % GameState.stamina
	end_day_button.pressed.connect(_on_end_day_button_pressed)
	deep_talk_button.pressed.connect(_on_deep_talk_button_pressed)
	_render_guests()
	_render_drinks()
	status_label.text = "选择客人，再给 ta 调一杯酒。"

func _render_guests() -> void:
	for child in guest_list.get_children():
		child.queue_free()
	for guest in _guests:
		var button := Button.new()
		button.text = str(guest.get("name", "客人"))
		button.pressed.connect(func() -> void: _select_guest(str(guest.get("id", ""))))
		guest_list.add_child(button)

func _render_drinks() -> void:
	for child in drink_list.get_children():
		child.queue_free()
	for drink in _drinks:
		var button := Button.new()
		button.text = "%s（%s）" % [str(drink.get("name", "酒")), "、".join(drink.get("ingredients", []))]
		button.pressed.connect(func() -> void: _serve_drink(str(drink.get("id", ""))))
		drink_list.add_child(button)

func _select_guest(id: String) -> void:
	GameState.select_guest(id)
	status_label.text = "已选择客人，请调酒。"
	var guest := GameState.guest_by_id(id)
	var cost := GameState.social_class_cost(str(guest.get("social_class", "Civilian")))
	deep_talk_button.text = "深入交流（%d 精力）" % cost

func _serve_drink(id: String) -> void:
	var result := GameState.serve_drink(GameState.selected_guest_id, id)
	status_label.text = str(result.get("dialogue", str(result.get("error", ""))))
	stamina_label.text = "精力：%d" % GameState.stamina

func _on_deep_talk_button_pressed() -> void:
	var result := GameState.deep_talk(GameState.selected_guest_id)
	status_label.text = str(result.get("dialogue", str(result.get("error", ""))))
	stamina_label.text = "精力：%d" % GameState.stamina

func _on_end_day_button_pressed() -> void:
	end_day_requested.emit()
