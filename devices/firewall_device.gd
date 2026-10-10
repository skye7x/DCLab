class_name FirewallDevice
extends Device

var rules: Array = []

func _init(p_id: String = "", p_name: String = "Firewall") -> void:
	super(p_id, p_name, "firewall")
	add_interface("eth0")
	add_interface("eth1")
	rules.append({"action": "allow", "protocol": "any", "src_ip": "any", "dst_ip": "any", "dst_port": -1, "priority": 1000})

func add_rule(action: String, protocol: String, src_ip: String, dst_ip: String, dst_port: int, priority: int) -> void:
	rules.append({"action": action, "protocol": protocol, "src_ip": src_ip, "dst_ip": dst_ip, "dst_port": dst_port, "priority": priority})
	rules.sort_custom(func(a, b): return a["priority"] < b["priority"])

func remove_rule(index: int) -> void:
	if index >= 0 and index < rules.size():
		rules.remove_at(index)

func check_packet(protocol: String, src_ip: String, dst_ip: String, dst_port: int) -> bool:
	for rule in rules:
		var p_match: bool = (rule["protocol"] == "any" or rule["protocol"].to_lower() == protocol.to_lower())
		var src_match: bool = (rule["src_ip"] == "any" or rule["src_ip"] == src_ip)
		var dst_match: bool = (rule["dst_ip"] == "any" or rule["dst_ip"] == dst_ip)
		var port_match: bool = (rule["dst_port"] == -1 or rule["dst_port"] == dst_port)
		
		if p_match and src_match and dst_match and port_match:
			return rule["action"] == "allow"
			
	return false

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	dict["rules"] = rules.duplicate(true)
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	if data.has("rules"):
		rules = data["rules"].duplicate(true)
