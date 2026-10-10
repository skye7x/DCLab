extends Node

var _logs: Array = []
const MAX_LOGS: int = 5000

func _add_log(device_id: String, level: String, msg: String) -> void:
	var entry: Dictionary = {
		"timestamp": SimTime.total_elapsed,
		"device_id": device_id,
		"level": level,
		"message": msg
	}
	_logs.append(entry)
	if _logs.size() > MAX_LOGS:
		_logs.pop_front()
	EventBus.log_created.emit(device_id, entry)

func log_info(device_id: String, msg: String) -> void:
	_add_log(device_id, "INFO", msg)

func log_warning(device_id: String, msg: String) -> void:
	_add_log(device_id, "WARNING", msg)

func log_error(device_id: String, msg: String) -> void:
	_add_log(device_id, "ERROR", msg)

func get_logs(device_id: String, level_filter: String = "") -> Array:
	var result: Array = []
	for log in _logs:
		if log["device_id"] == device_id and (level_filter == "" or log["level"] == level_filter):
			result.append(log)
	return result

func get_all_logs() -> Array:
	return _logs.duplicate()

func clear() -> void:
	_logs.clear()

func clear_device(device_id: String) -> void:
	var filtered: Array = []
	for log in _logs:
		if log["device_id"] != device_id:
			filtered.append(log)
	_logs = filtered
