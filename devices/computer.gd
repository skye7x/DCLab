class_name Computer
extends Device

var cpu_cores: int = 2
var ram_mb: int = 4096
var storage_mb: int = 256000
var operating_system = null

func _init(p_id: String = "", p_name: String = "PC", p_type: String = "pc") -> void:
	super(p_id, p_name, p_type)

func get_cpu_usage() -> float:
	if operating_system:
		var total: float = 0.0
		for p in operating_system.get_processes():
			total += p.cpu_percent
		return total
	return 0.5

func get_ram_usage() -> float:
	if operating_system:
		var total: float = 0.0
		for p in operating_system.get_processes():
			total += p.ram_mb
		return total
	return 128.0

func get_storage_usage() -> float:
	return 1024.0

func install_os(os_name: String = "DCLinux") -> void:
	operating_system = LinuxSystem.new(display_name, id)

func power_off() -> void:
	super.power_off()

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	dict["cpu_cores"] = cpu_cores
	dict["ram_mb"] = ram_mb
	dict["storage_mb"] = storage_mb
	if operating_system:
		dict["operating_system"] = operating_system.to_dict()
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	cpu_cores = data.get("cpu_cores", 2)
	ram_mb = data.get("ram_mb", 4096)
	storage_mb = data.get("storage_mb", 256000)
	if data.has("operating_system") and data["operating_system"] is Dictionary:
		operating_system = LinuxSystem.new(display_name, id)
		operating_system.from_dict(data["operating_system"])
