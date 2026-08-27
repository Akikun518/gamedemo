class_name TimeSystem
extends RefCounted

const MORNING := "morning"
const RESULT := "result"
const EVENING := "evening"

static func next_phase(phase: String) -> String:
    match phase:
        MORNING:
            return RESULT
        RESULT:
            return EVENING
        EVENING:
            return MORNING
        _:
            return MORNING

static func is_valid_phase(phase: String) -> bool:
    return phase == MORNING or phase == RESULT or phase == EVENING
