class_name Device
extends RefCounted

var id: String = ""
var display_name: String = ""
var device_type: String = "generic"
var position: Vector2 = Vector2.ZERO
var is_enabled: bool = true
var is_powered_on: bool = true
var network_interfaces: Dictionary = {}
var metadata: Dictionary = {}
var arp_table: ArpTable = ArpTable.new()

func _init(p_id: String = "", p_name: String = "Device", p_type: String = "generic") -> void:
	id = p_id
	display_name = p_name
	device_type = p_type

func power_on() -> void:
	if not is_powered_on:
		is_powered_on = true
		_emit_event_power(true)
		_log("INFO", "Device powered on")
		_request_dhcp_on_all_ifaces()

func _request_dhcp_on_all_ifaces() -> void:
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimEngine"):
		var engine = tree.root.get_node("SimEngine")
		if engine.has_method("_try_auto_dhcp"):
			for iface_name in network_interfaces:
				engine._try_auto_dhcp(id, iface_name)

func power_off() -> void:
	if is_powered_on:
		is_powered_on = false
		_emit_event_power(false)
		_log("INFO", "Device powered off")

func restart() -> void:
	power_off()
	power_on()

func add_interface(iface_name: String) -> NetworkInterface:
	var iface = NetworkInterface.new(iface_name, id)
	network_interfaces[iface_name] = iface
	return iface

func remove_interface(iface_name: String) -> void:
	if network_interfaces.has(iface_name):
		network_interfaces.erase(iface_name)

func get_interface(iface_name: String) -> NetworkInterface:
	return network_interfaces.get(iface_name, null)

func get_all_interfaces() -> Array:
	return network_interfaces.values()

func to_dict() -> Dictionary:
	var ifaces_dict: Dictionary = {}
	for iface in network_interfaces:
		ifaces_dict[iface] = network_interfaces[iface].to_dict()
		
	return {
		"id": id,
		"display_name": display_name,
		"device_type": device_type,
		"position": {"x": position.x, "y": position.y},
		"is_enabled": is_enabled,
		"is_powered_on": is_powered_on,
		"network_interfaces": ifaces_dict,
		"metadata": metadata,
		"arp_table": arp_table.to_dict()
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("display_name", "")
	device_type = data.get("device_type", "generic")
	var pos = data.get("position", {"x": 0, "y": 0})
	position = Vector2(pos.get("x", 0), pos.get("y", 0))
	is_enabled = data.get("is_enabled", true)
	is_powered_on = data.get("is_powered_on", true)
	metadata = data.get("metadata", {})
	
	network_interfaces.clear()
	if data.has("network_interfaces") and data["network_interfaces"] is Dictionary:
		for if_name in data["network_interfaces"]:
			var if_data = data["network_interfaces"][if_name]
			var iface = NetworkInterface.new(if_name, id)
			iface.from_dict(if_data)
			network_interfaces[if_name] = iface
	if data.has("arp_table") and data["arp_table"] is Dictionary:
		arp_table.from_dict(data["arp_table"])

func get_device_type_display() -> String:
	return device_type.capitalize()

func _emit_event_power(powered: bool) -> void:
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("EventBus"):
		tree.root.get_node("EventBus").device_power_changed.emit(self, powered)

func _log(level: String, msg: String) -> void:
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimLogger"):
		var logger = tree.root.get_node("SimLogger")
		match level:
			"INFO": logger.log_info(id, msg)
			"WARNING": logger.log_warning(id, msg)
			"ERROR": logger.log_error(id, msg)
