class_name RouterDevice
extends Device

var routing_table: RoutingTable
var dhcp_enabled: bool = true
var dhcp_pool_start: int = 100
var dhcp_pool_end: int = 199
var dhcp_leases: Dictionary = {}
var nat_enabled: bool = false
var wan_interface: String = "eth0"
var nat_table: Dictionary = {}   # internal_ip -> {"external_ip": String, "hits": int}

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

static func is_private_ip(ip: String) -> bool:
	if ip.begins_with("10."):
		return true
	if ip.begins_with("192.168."):
		return true
	if ip.begins_with("172."):
		var second = ip.split(".")[1].to_int()
		return second >= 16 and second <= 31
	return false

func nat_translate_outbound(src_ip: String) -> String:
	if not nat_enabled:
		return src_ip
	var wan = get_interface(wan_interface)
	if not wan or wan.ipv4_address == "":
		return src_ip
	if not nat_table.has(src_ip):
		nat_table[src_ip] = {"external_ip": wan.ipv4_address, "hits": 0}
	nat_table[src_ip]["hits"] = int(nat_table[src_ip]["hits"]) + 1
	return wan.ipv4_address

func nat_translate_inbound(dest_ip: String) -> String:
	if not nat_enabled:
		return dest_ip
	for internal_ip in nat_table:
		if nat_table[internal_ip].external_ip == dest_ip:
			return internal_ip
	return dest_ip

func nat_clear() -> void:
	nat_table.clear()

func auto_generate_routes() -> void:
	if not routing_table:
		routing_table = RoutingTable.new()
	# Preserve static routes (those with a gateway set); clear only auto/connected routes
	var static_routes: Array = []
	for r in routing_table.get_all_routes():
		if r.gateway != "":
			static_routes.append(r)
	routing_table.clear()
	for iface in network_interfaces.values():
		if iface.is_configured():
			var subnet = iface.get_subnet()
			if subnet:
				routing_table.add_route(subnet.network_address, subnet.cidr, iface.iface_name, "", 0)
	for r in static_routes:
		routing_table.add_route(r.network, r.cidr, r.interface_name, r.gateway, r.metric)

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
	dict["nat_enabled"] = nat_enabled
	dict["wan_interface"] = wan_interface
	dict["nat_table"] = nat_table.duplicate(true)
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
	nat_enabled = data.get("nat_enabled", false)
	wan_interface = data.get("wan_interface", "eth0")
	nat_table = data.get("nat_table", {})
