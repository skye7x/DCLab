class_name SwitchDevice
extends Device

var port_count: int = 8
var mac_table: Dictionary = {}
var port_vlans: Dictionary = {}       # port_name -> VLAN ID (default 1)
var trunk_ports: Array = []           # port names carrying all VLANs

func _init(p_id: String = "", p_name: String = "Switch") -> void:
	super(p_id, p_name, "switch")
	for i in range(1, port_count + 1):
		add_interface("port%d" % i)
		port_vlans["port%d" % i] = 1

func get_port_vlan(port_name: String) -> int:
	return port_vlans.get(port_name, 1)

func set_port_vlan(port_name: String, vlan_id: int) -> void:
	if network_interfaces.has(port_name):
		port_vlans[port_name] = clampi(vlan_id, 1, 4094)

func is_trunk(port_name: String) -> bool:
	return port_name in trunk_ports

func set_trunk(port_name: String, trunked: bool) -> void:
	if not network_interfaces.has(port_name):
		return
	if trunked and not (port_name in trunk_ports):
		trunk_ports.append(port_name)
	elif not trunked and (port_name in trunk_ports):
		trunk_ports.erase(port_name)

func can_forward_between(in_port: String, out_port: String) -> bool:
	if in_port == out_port:
		return false
	if is_trunk(in_port) or is_trunk(out_port):
		return true
	return get_port_vlan(in_port) == get_port_vlan(out_port)

func learn_mac(mac_address: String, port_name: String) -> void:
	mac_table[mac_address] = port_name

func lookup_mac(mac_address: String) -> String:
	return mac_table.get(mac_address, "")

func clear_mac_table() -> void:
	mac_table.clear()

func get_connected_port(target_device_id: String) -> String:
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimEngine"):
		var engine = tree.root.get_node("SimEngine")
		var conns: Array = engine.get_connections_for_device(self.id)
		for conn in conns:
			var other = conn.get_other_device_id(self.id)
			if other == target_device_id:
				return conn.source_interface_name if conn.source_device_id == self.id else conn.dest_interface_name
	return ""

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	dict["port_count"] = port_count
	dict["mac_table"] = mac_table.duplicate()
	dict["port_vlans"] = port_vlans.duplicate()
	dict["trunk_ports"] = trunk_ports.duplicate()
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	port_count = data.get("port_count", 8)
	mac_table = data.get("mac_table", {})
	port_vlans = data.get("port_vlans", {})
	trunk_ports = data.get("trunk_ports", [])
