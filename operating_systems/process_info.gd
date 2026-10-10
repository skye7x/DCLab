class_name ProcessInfo extends RefCounted

var pid: int
var process_name: String
var cpu_percent: float = 0.0
var ram_mb: float = 0.0
var is_running: bool = true
var owner: String = "root"

func _init(p_pid: int, p_name: String, p_cpu: float = 0.0, p_ram: float = 0.0):
	pid = p_pid
	process_name = p_name
	cpu_percent = p_cpu
	ram_mb = p_ram

func to_dict() -> Dictionary:
	return {
		"pid": pid,
		"process_name": process_name,
		"cpu_percent": cpu_percent,
		"ram_mb": ram_mb,
		"is_running": is_running,
		"owner": owner
	}
