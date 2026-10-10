class_name RouterDevice
extends Device

var routing_table: RoutingTable
var dhcp_enabled: bool = true
var dhcp_pool_start: int = 100
var dhcp_pool_end: int = 199
var dhcp_leases: Dictionary = {}

func _init(p_id: String = "", p_name: String = "Router") -> void:
	super(p_id, p_name, "router")
	routing_table = RoutingTable.new()
	add_interface("eth0")
	add_interface("eth1")

func add_route(network: String, cidr: int, iface_name: String, gateway: String, metric: int) -> void:
	if routing_table:
		routing_table.add_route(network, cidr, iface_name, gateway, metric)

func remove_route(network: String, cidr: int) -> void:
	if routing_table:
		routing_table.remove_route(network, cidr)

func route_packet(dest_ip: String) -> Dictionary:
	if routing_table:
		return routing_table.find_route(dest_ip)
	return {}

func auto_generate_routes() -> void:
	if not routing_table:
		routing_table = RoutingTable.new()
	routing_table.clear()
	for iface in network_interfaces.values():
		if iface.is_configured():
			var subnet = iface.get_subnet()
			if subnet:
				routing_table.add_route(subnet.network_address, subnet.cidr, iface.iface_name, "", 0)

func dhcp_discover(iface_name: String, mac_address: String) -> Dictionary:
	if not dhcp_enabled:
		return {}
	var iface = get_interface(iface_name)
	if not iface or not iface.is_configured():
		return {}
	if dhcp_leases.has(mac_address):
		return {"ip": dhcp_leases[mac_address], "mask": iface.subnet_mask, "gateway": iface.ipv4_address}
	var subnet = iface.get_subnet()
	if not subnet:
		return {}
	var base = IPv4Address.to_int(subnet.network_address)
	var used_ips: Dictionary = {}
	for mac in dhcp_leases:
		used_ips[dhcp_leases[mac]] = true
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimEngine"):
		var engine = tree.root.get_node("SimEngine")
		for dev in engine.get_all_devices():
			if dev.id == id:
				continue
			for i in dev.network_interfaces.values():
				if i.ipv4_address != "":
					used_ips[i.ipv4_address] = true
	for host in range(dhcp_pool_start, dhcp_pool_end + 1):
		var candidate = IPv4Address.from_int(base + host)
		if not used_ips.has(candidate):
			dhcp_leases[mac_address] = candidate
			_log("INFO", "DHCP lease %s -> %s (%s)" % [mac_address, candidate, iface_name])
			return {"ip": candidate, "mask": iface.subnet_mask, "gateway": iface.ipv4_address}
	return {}

func to_dict() -> Dictionary:
	var dict: Dictionary = super.to_dict()
	if routing_table:
		dict["routing_table"] = routing_table.to_dict()
	dict["dhcp_enabled"] = dhcp_enabled
	dict["dhcp_pool_start"] = dhcp_pool_start
	dict["dhcp_pool_end"] = dhcp_pool_end
	dict["dhcp_leases"] = dhcp_leases.duplicate()
	return dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	if not routing_table:
		routing_table = RoutingTable.new()
	if data.has("routing_table") and data["routing_table"] is Dictionary:
		routing_table.from_dict(data["routing_table"])
	dhcp_enabled = data.get("dhcp_enabled", true)
	dhcp_pool_start = data.get("dhcp_pool_start", 100)
	dhcp_pool_end = data.get("dhcp_pool_end", 199)
	dhcp_leases = data.get("dhcp_leases", {})
