class_name Server
extends Computer

func _init(p_id: String = "", p_name: String = "Server") -> void:
	super._init(p_id, p_name, "server")
	cpu_cores = 4
	ram_mb = 8192
	storage_mb = 512000

func get_cpu_usage() -> float:
	var total: float = super.get_cpu_usage()
	for s in services:
		if s.is_running:
			total += s.cpu_usage
	return total

func get_ram_usage() -> float:
	var total: float = super.get_ram_usage()
	for s in services:
		if s.is_running:
			total += s.ram_usage_mb
	return total
