class_name LinuxSystem extends OperatingSystem

func _init(p_hostname: String = "localhost", p_device_id: String = ""):
	super(p_hostname, p_device_id)
	os_name = "DCLinux"
	add_process("init", 0.1, 5.0)
	add_process("syslog", 0.1, 2.0)

func to_dict() -> Dictionary:
	var d = super.to_dict()
	d["type"] = "LinuxSystem"
	return d
