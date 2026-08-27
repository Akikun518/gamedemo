extends VBoxContainer

signal end_day_requested

var _drink: Dictionary = {}

@onready var drink_label: Label = $DrinkLabel

func setup(drink: Dictionary, current_day: int) -> void:
    _drink = drink
    drink_label.text = "第 %d 天晚上\n预留配方：%s（%s）\n材料：%s\n口味：%s   酒精度：%d/5" % [
        current_day,
        str(drink.get("name", "")),
        str(drink.get("ref", "")),
        "、".join(drink.get("ingredients", [])),
        "、".join(drink.get("taste", [])),
        int(drink.get("alcohol", 0)),
    ]

func _on_end_day_button_pressed() -> void:
    end_day_requested.emit()

func _on_collect_intel_button_pressed() -> void:
    GameState.collect_night_intel()

