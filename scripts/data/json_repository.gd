extends Node
## Generic JSON reader. Content directories can grow without code changes.

func load_records(directory_path: String) -> Array[Dictionary]:
    var records: Array[Dictionary] = []
    if not DirAccess.dir_exists_absolute(directory_path):
        push_warning("Data directory does not exist: " + directory_path)
        return records

    for file_name in DirAccess.get_files_at(directory_path):
        if not file_name.to_lower().ends_with(".json"):
            continue
        var path := directory_path.path_join(file_name)
        var text := FileAccess.get_file_as_string(path)
        if text.is_empty():
            push_error("Empty or unreadable data file: " + path)
            continue
        var parsed: Variant = JSON.parse_string(text)
        if parsed is Dictionary:
            records.append(parsed)
        else:
            push_error("Expected a JSON object in: " + path)
    return records
