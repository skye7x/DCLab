extends Node
class_name ProjectManager

var current_project: ProjectData = null
var current_path: String = ""
var recent_projects: Array = []
var _save_dir: String = "user://projects/"
var command_history: CommandHistory

func _ready():
	command_history = CommandHistory.new()
	DirAccess.make_dir_recursive_absolute(_save_dir)
	_load_recent_list()

func new_project(p_name: String = "Untitled Project"):
	var engine = get_node_or_null("/root/SimEngine")
	if engine and engine.has_method("clear"):
		engine.clear()
		
	current_project = ProjectData.new(p_name)
	current_path = ""
	command_history.clear()
	
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("project_loaded"):
		bus.project_loaded.emit(p_name)

func save_project(path: String = ""):
	if not current_project:
		current_project = ProjectData.new("Untitled Project")
		
	if path != "":
		current_path = path
	elif current_path == "":
		current_path = _save_dir + current_project.project_name.replace(" ", "_") + ".dclabproj"
		
	if not current_path.ends_with(".dclabproj") and not current_path.ends_with(".json"):
		current_path += ".dclabproj"
		
	var time_dict = Time.get_datetime_dict_from_system()
	current_project.modified_at = "%d-%02d-%02dT%02d:%02d:%02d" % [time_dict.year, time_dict.month, time_dict.day, time_dict.hour, time_dict.minute, time_dict.second]
	
	var engine = get_node_or_null("/root/SimEngine")
	var data = ProjectSerializer.serialize_project(engine, current_project)
	
	var file = FileAccess.open(current_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		_add_to_recent(current_project.project_name, current_path)
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.project_saved.emit(current_project.project_name)
		
func load_project(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
		
	var text = file.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return false
		
	var engine = get_node_or_null("/root/SimEngine")
	current_project = ProjectSerializer.deserialize_project(data, engine)
	current_path = path
	command_history.clear()
	
	_add_to_recent(current_project.project_name, current_path)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.project_loaded.emit(current_project.project_name)
		
	return true

func get_recent_projects() -> Array:
	return recent_projects

func _add_to_recent(p_name: String, path: String):
	for i in range(recent_projects.size() - 1, -1, -1):
		if recent_projects[i].path == path:
			recent_projects.remove_at(i)
			
	recent_projects.push_front({"name": p_name, "path": path})
	if recent_projects.size() > 10:
		recent_projects.pop_back()
		
	_save_recent_list()

func _load_recent_list():
	var file = FileAccess.open("user://recent_projects.json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_ARRAY:
			recent_projects = data

func _save_recent_list():
	var file = FileAccess.open("user://recent_projects.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(recent_projects, "  "))

func get_save_directory() -> String:
	return _save_dir

func create_sample_project() -> Dictionary:
	var proj = ProjectData.new("Small Office")
	var data = {
		"version": 1,
		"project": proj.to_dict(),
		"devices": [
			{
				"id": "dev_001", "display_name": "Gateway", "device_type": "router",
				"position": {"x": 400, "y": 100}, "is_enabled": true, "is_powered_on": true,
				"network_interfaces": {
					"eth0": {"iface_name": "eth0", "mac_address": "02:1A:2B:3C:4D:50", "ipv4_address": "192.168.10.1", "subnet_mask": "255.255.255.0", "gateway": "", "is_enabled": true, "is_linked": true},
					"eth1": {"iface_name": "eth1", "mac_address": "02:1A:2B:3C:4D:5F", "ipv4_address": "10.0.0.1", "subnet_mask": "255.255.255.0", "gateway": "", "is_enabled": true, "is_linked": false}
				},
				"routing_table": {
					"routes": [
						{"network": "192.168.10.0", "cidr": 24, "interface_name": "eth0", "gateway": "", "metric": 0}
					]
				}
			},
			{
				"id": "dev_002", "display_name": "MainSwitch", "device_type": "switch",
				"position": {"x": 400, "y": 250}, "is_enabled": true, "is_powered_on": true,
				"port_count": 8, "mac_table": {},
				"network_interfaces": {
					"port1": {"iface_name": "port1", "mac_address": "02:1A:2B:3C:4D:61", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": true},
					"port2": {"iface_name": "port2", "mac_address": "02:1A:2B:3C:4D:62", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": true},
					"port3": {"iface_name": "port3", "mac_address": "02:1A:2B:3C:4D:63", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": true},
					"port4": {"iface_name": "port4", "mac_address": "02:1A:2B:3C:4D:64", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": true},
					"port5": {"iface_name": "port5", "mac_address": "02:1A:2B:3C:4D:65", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": false},
					"port6": {"iface_name": "port6", "mac_address": "02:1A:2B:3C:4D:66", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": false},
					"port7": {"iface_name": "port7", "mac_address": "02:1A:2B:3C:4D:67", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": false},
					"port8": {"iface_name": "port8", "mac_address": "02:1A:2B:3C:4D:68", "ipv4_address": "", "subnet_mask": "", "gateway": "", "is_enabled": true, "is_linked": false}
				}
			},
			{
				"id": "dev_003", "display_name": "WebServer", "device_type": "server",
				"position": {"x": 600, "y": 420}, "is_enabled": true, "is_powered_on": true,
				"cpu_cores": 4, "ram_mb": 8192, "storage_mb": 512000,
				"operating_system": {
					"os_name": "DCLinux", "hostname": "web01", 
					"file_system": {
						"/www/index.html": "<html>\n<h1>Hello from Web Server</h1>\n</html>\n"
					}
				},
				"network_interfaces": {
					"eth0": {"iface_name": "eth0", "mac_address": "02:AA:12:34:56:01", "ipv4_address": "192.168.10.10", "subnet_mask": "255.255.255.0", "gateway": "192.168.10.1", "is_enabled": true, "is_linked": true}
				},
				"services": [
					{"service_type": "http", "port": 80, "protocol": "tcp", "is_running": true, "auto_start": true, "device_id": "dev_003", "web_root": "/www", "default_document": "index.html"},
					{"service_type": "ssh", "port": 22, "protocol": "tcp", "is_running": true, "auto_start": true, "device_id": "dev_003"}
				]
			},
			{
				"id": "dev_004", "display_name": "PC-01", "device_type": "pc",
				"position": {"x": 200, "y": 420}, "is_enabled": true, "is_powered_on": true,
				"cpu_cores": 2, "ram_mb": 4096, "storage_mb": 256000,
				"operating_system": {"os_name": "DCLinux", "hostname": "pc01"},
				"network_interfaces": {
					"eth0": {"iface_name": "eth0", "mac_address": "02:AA:12:34:56:02", "ipv4_address": "192.168.10.20", "subnet_mask": "255.255.255.0", "gateway": "192.168.10.1", "is_enabled": true, "is_linked": true}
				}
			},
			{
				"id": "dev_005", "display_name": "PC-02", "device_type": "pc",
				"position": {"x": 400, "y": 420}, "is_enabled": true, "is_powered_on": true,
				"cpu_cores": 2, "ram_mb": 4096, "storage_mb": 256000,
				"operating_system": {"os_name": "DCLinux", "hostname": "pc02"},
				"network_interfaces": {
					"eth0": {"iface_name": "eth0", "mac_address": "02:AA:12:34:56:03", "ipv4_address": "192.168.10.21", "subnet_mask": "255.255.255.0", "gateway": "192.168.10.1", "is_enabled": true, "is_linked": true}
				}
			}
		],
		"connections": [
			{"id": "link_001", "source_device_id": "dev_001", "source_interface_name": "eth0", "dest_device_id": "dev_002", "dest_interface_name": "port1", "is_enabled": true},
			{"id": "link_002", "source_device_id": "dev_002", "source_interface_name": "port2", "dest_device_id": "dev_003", "dest_interface_name": "eth0", "is_enabled": true},
			{"id": "link_003", "source_device_id": "dev_002", "source_interface_name": "port3", "dest_device_id": "dev_004", "dest_interface_name": "eth0", "is_enabled": true},
			{"id": "link_004", "source_device_id": "dev_002", "source_interface_name": "port4", "dest_device_id": "dev_005", "dest_interface_name": "eth0", "is_enabled": true}
		]
	}
	return data

func execute_command(cmd: Command):
	command_history.push_command(cmd)
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("command_executed"):
		bus.command_executed.emit(cmd.get_description())

func undo() -> bool:
	return command_history.undo()

func redo() -> bool:
	return command_history.redo()
