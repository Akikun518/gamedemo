class_name SaveSystem
extends RefCounted
## M0 serialization boundary. Persistence can be enabled without storing scene references.

static func snapshot(game_state: Node) -> Dictionary:
    return {
        "current_day": int(game_state.current_day),
        "current_phase": str(game_state.current_phase),
        "money": int(game_state.money),
        "reputation": int(game_state.reputation),
        "known_intel": game_state.known_intel.duplicate(),
    }
