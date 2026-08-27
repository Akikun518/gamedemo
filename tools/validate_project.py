"""Structural and data-contract verification for the M0 Godot skeleton."""
from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_DIRS = [
    "data/mercenaries",
    "data/missions",
    "data/drinks",
    "data/factions",
    "data/dialogues",
    "data/intel",
    "scenes/morning",
    "scenes/evening",
    "scenes/ui",
    "scripts/core",
    "scripts/data",
    "scripts/mission",
    "scripts/mercenary",
    "scripts/bar",
    "scripts/dialogue",
    "scripts/intel",
    "scripts/faction",
    "scripts/ui",
    "assets/fonts",
    "tests",
]

REQUIRED_FILES = {
    "project.godot": "Godot project marker",
    "scenes/main.tscn": "root scene",
    "scenes/morning/morning_panel.tscn": "morning phase panel",
    "scenes/evening/evening_panel.tscn": "evening phase panel",
    "scenes/ui/result_panel.tscn": "result panel",
    "scripts/data/json_repository.gd": "JSON loading",
    "scripts/core/game_state.gd": "authoritative state",
    "scripts/core/time_system.gd": "day/phase rules",
    "scripts/core/event_bus.gd": "UI-safe signals",
    "scripts/mission/mission_manager.gd": "mission loading",
    "scripts/mission/mission_resolver.gd": "settlement rules",
    "scripts/mercenary/mercenary_manager.gd": "roster loading",
    "tests/m0_headless_test.gd": "runtime smoke test",
    "tests/m0_headless_test.tscn": "autoload-aware runtime smoke scene",
}

DATA_REQUIRED_FIELDS = {
    "mercenaries": {"id", "name", "role", "star", "stats", "price", "alive", "unlock", "likes", "dislikes"},
    "missions": {"id", "title", "client", "surface_rank", "true_rank", "required_roles", "reward", "base_days", "unlock", "on_success", "on_failure", "tags", "time_limit_days", "unlimited"},
    "drinks": {"id", "name", "taste", "alcohol", "audience", "unlock", "ingredients"},
    "factions": {"id", "name", "type", "affection"},
    "intel": {"id", "text", "related_mission", "hint"},
}

DATA_MINIMUM_COUNTS = {
    "mercenaries": 3,
    "missions": 1,
    "drinks": 1,
    "factions": 1,
    "intel": 1,
}

CONTENT_IDS = {"find_cat", "luo", "manniu", "sam", "neon_fog", "cat_necklace", "neighbor"}


def fail(messages: list[str]) -> None:
    if messages:
        print("M0 VALIDATION FAILED")
        for message in messages:
            print(f"- {message}")
        raise SystemExit(1)


def validate() -> None:
    errors: list[str] = []
    for relative in EXPECTED_DIRS:
        if not (ROOT / relative).is_dir():
            errors.append(f"missing directory: {relative}")
    for relative, purpose in REQUIRED_FILES.items():
        if not (ROOT / relative).is_file():
            errors.append(f"missing {purpose}: {relative}")

    project = ROOT / "project.godot"
    if project.is_file():
        text = project.read_text(encoding="utf-8")
        for expected in [
            "config_version=5",
            "run/main_scene=\"res://scenes/main.tscn\"",
            "viewport_width=640",
            "viewport_height=360",
            "window_width_override=1280",
            "window_height_override=720",
            "stretch/mode=\"canvas_items\"",
            "stretch/scale_mode=\"integer\"",
            "default_texture_filter=0",
            "DataRepository=\"*res://scripts/data/json_repository.gd\"",
            "EventBus=\"*res://scripts/core/event_bus.gd\"",
            "GameState=\"*res://scripts/core/game_state.gd\"",
        ]:
            if expected not in text:
                errors.append(f"project.godot missing setting: {expected}")

    records: dict[str, list[dict]] = {}
    for category, fields in DATA_REQUIRED_FIELDS.items():
        directory = ROOT / "data" / category
        if not directory.is_dir():
            continue
        parsed = []
        for path in sorted(directory.glob("*.json")):
            try:
                value = json.loads(path.read_text(encoding="utf-8"))
            except Exception as exc:
                errors.append(f"invalid JSON {path.relative_to(ROOT)}: {exc}")
                continue
            if not isinstance(value, dict):
                errors.append(f"{path.relative_to(ROOT)} must contain an object")
                continue
            missing = fields - set(value)
            if missing:
                errors.append(f"{path.name} missing fields: {', '.join(sorted(missing))}")
            parsed.append(value)
        minimum_count = DATA_MINIMUM_COUNTS.get(category)
        if minimum_count is not None and len(parsed) < minimum_count:
            errors.append(f"{category}: expected at least {minimum_count} records, found {len(parsed)}")
        records[category] = parsed

    if len(records.get("mercenaries", [])) == 3:
        roles = {record.get("role") for record in records["mercenaries"]}
        if roles != {"driver", "assault", "negotiator"}:
            errors.append(f"unexpected initial roles: {sorted(roles)}")
    if records.get("missions") and records["missions"][0].get("id") == "find_cat":
        mission = records["missions"][0]
        if mission.get("true_rank") != "D" or mission.get("reward") != 100 or mission.get("base_days") != 1:
            errors.append("find_cat must be a D/D, 100-credit, one-day tutorial mission")
        success = mission.get("on_success", {})
        if success.get("reputation") != 2 or "cat_necklace" not in success.get("unlock_intel", []):
            errors.append("find_cat success must award reputation and unlock cat_necklace")

    for gd_file in (ROOT / "scripts").rglob("*.gd"):
        text = gd_file.read_text(encoding="utf-8")
        for content_id in CONTENT_IDS:
            if f'"{content_id}"' in text:
                errors.append(f"hard-coded content ID {content_id!r} in {gd_file.relative_to(ROOT)}")

    event_bus = ROOT / "scripts" / "core" / "event_bus.gd"
    if event_bus.is_file():
        bus_text = event_bus.read_text(encoding="utf-8")
        signals = re.findall(r"^signal\s+(\w+)", bus_text, flags=re.MULTILINE)
        for signal_name in signals:
            used = False
            for gd_file in (ROOT / "scripts").rglob("*.gd"):
                if gd_file == event_bus:
                    continue
                if signal_name in gd_file.read_text(encoding="utf-8"):
                    used = True
                    break
            if not used:
                errors.append(f"EventBus signal {signal_name!r} is not connected or emitted outside event_bus.gd")

    for relative in ["mercenaries", "missions", "drinks", "factions", "dialogues", "intel"]:
        if not (ROOT / "data" / relative / "README.md").is_file():
            errors.append(f"missing data folder guide: data/{relative}/README.md")

    fail(errors)
    print("M0 VALIDATION PASSED")
    print(f"- content records: {sum(len(value) for value in records.values())}")
    print("- folders: data / scenes / scripts / assets / tests")
    print("- no content IDs hard-coded in scripts")


if __name__ == "__main__":
    validate()



