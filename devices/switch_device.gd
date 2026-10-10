class_name SwitchDevice
extends Device

var port_count: int = 8
var mac_table: Dictionary = {}

func _init(p_id: String = "", p_name: String = "Switch") -> void:
	super(p_id, p_name, "switch")
	for i in range(1, port_count + 1):
		add_interface("port%d" % i)

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
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	port_count = data.get("port_count", 8)
	mac_table = data.get("mac_table", {})
