class_name Server
extends Computer

var services: Array = []

func _init(p_id: String = "", p_name: String = "Server") -> void:
	super._init(p_id, p_name, "server")
	cpu_cores = 4
	ram_mb = 8192
	storage_mb = 512000

func add_service(service) -> void:
	service.device_id = id
	services.append(service)

func remove_service(service_name: String) -> void:
	for i in range(services.size()):
		if services[i].service_name == service_name:
			services.remove_at(i)
			break

func get_service(service_name: String):
	for s in services:
		if s.service_name == service_name:
			return s
	return null

func get_running_services() -> Array:
	var running: Array = []
	for s in services:
		if s.is_running:
			running.append(s)
	return running

func start_service(service_name: String) -> String:
	var s = get_service(service_name)
	if s:
		s.start()
		return "Service started"
	return "Service not found"

func stop_service(service_name: String) -> String:
	var s = get_service(service_name)
	if s:
		s.stop()
		return "Service stopped"
	return "Service not found"

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

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	var srv_list: Array = []
	for s in services:
		srv_list.append(s.to_dict())
	dict["services"] = srv_list
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	services.clear()
	if data.has("services") and data["services"] is Array:
		for s_data in data["services"]:
			var s = Service.from_dict(s_data)
			if s:
				s.device_id = id
				services.append(s)
