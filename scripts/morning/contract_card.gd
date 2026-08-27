extends PanelContainer
## A compact fixer-terminal contract card.

signal pressed(contract_id: String)

var _contract_id := ""

@onready var button: Button = $Button

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 1.0)
	style.border_color = Color(0.24, 0.48, 0.72, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)

func setup(contract: Contract) -> void:
	_contract_id = contract.id
	button.text = contract.board_summary()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _on_button_pressed() -> void:
	pressed.emit(_contract_id)
