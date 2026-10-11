extends Node

var devices: Dictionary = {}
var connections: Array = []
var network_sim: NetworkSimulator = null
var is_running: bool = false
var speed: float = 1.0

var _next_id: int = 1
var _next_link_id: int = 1

func _ready() -> void:
	network_sim = NetworkSimulator.new(self)

func generate_id() -> String:
	var id: String = "dev_%03d" % _next_id
	_next_id += 1
	return id

func generate_link_id() -> String:
	var id: String = "link_%03d" % _next_link_id
	_next_link_id += 1
	return id

func add_device(device: Device) -> void:
	devices[device.id] = device
	EventBus.device_added.emit(device)

func remove_device(id: String) -> void:
	if not devices.has(id):
		return
	
	var connections_to_remove: Array = []
	for conn in connections:
		if conn.source_device_id == id or conn.dest_device_id == id:
			connections_to_remove.append(conn.id)
	
	for conn_id in connections_to_remove:
		remove_connection(conn_id)
		
	devices.erase(id)
	EventBus.device_removed.emit(id)

func get_device(id: String) -> Device:
	return devices.get(id, null)

func get_all_devices() -> Array:
	return devices.values()

func create_connection(src_device_id: String, src_iface_name: String, dst_device_id: String, dst_iface_name: String) -> EthernetLink:
	# Avoid duplicate links between same interfaces
	for conn in connections:
		if (conn.source_device_id == src_device_id and conn.source_interface_name == src_iface_name and conn.dest_device_id == dst_device_id and conn.dest_interface_name == dst_iface_name) or (conn.source_device_id == dst_device_id and conn.source_interface_name == dst_iface_name and conn.dest_device_id == src_device_id and conn.dest_interface_name == src_iface_name):
			return conn
	
	# Validate devices and interfaces exist before creating link
	var src_dev = get_device(src_device_id)
	var dst_dev = get_device(dst_device_id)
	if not src_dev or not src_dev.network_interfaces.has(src_iface_name):
		return null
	if not dst_dev or not dst_dev.network_interfaces.has(dst_iface_name):
		return null
	
	var link = EthernetLink.new(generate_link_id(), src_device_id, src_iface_name, dst_device_id, dst_iface_name)
	connections.append(link)
	
	src_dev.network_interfaces[src_iface_name].is_linked = true
	src_dev.network_interfaces[src_iface_name].link = link
	dst_dev.network_interfaces[dst_iface_name].is_linked = true
	dst_dev.network_interfaces[dst_iface_name].link = link

	EventBus.connection_created.emit(link)
	_try_auto_dhcp(src_device_id, src_iface_name)
	_try_auto_dhcp(dst_device_id, dst_iface_name)
	return link

func _try_auto_dhcp(device_id: String, iface_name: String) -> void:
	var dev = get_device(device_id)
	if not dev or not dev.is_powered_on:
		return
	if dev is SwitchDevice:
		return
	if not dev.network_interfaces.has(iface_name):
		return
	var iface = dev.network_interfaces[iface_name]
	if iface.is_configured() or iface.ipv4_address != "":
		return
	var offer = _find_dhcp_offer(device_id, iface_name)
	if offer.is_empty():
		return
	iface.configure(offer.ip, offer.mask, offer.gateway)
	var logger = get_node_or_null("/root/SimLogger")
	if logger:
		logger.log_info(device_id, "DHCP: %s -> %s gw %s" % [iface_name, offer.ip, offer.gateway])
	EventBus.device_updated.emit(device_id)

func _find_dhcp_offer(device_id: String, iface_name: String, _depth: int = 0, _visited: Dictionary = {}) -> Dictionary:
	if _depth > 8:
		return {}
	var dev = get_device(device_id)
	if not dev:
		return {}
	if _visited.has(device_id):
		return {}
	_visited[device_id] = true
	for conn in get_connections_for_device(device_id):
		var my_iface = conn.source_interface_name if conn.source_device_id == device_id else conn.dest_interface_name
		if my_iface != iface_name and _depth == 0:
			continue
		var other_id = conn.get_other_device_id(device_id)
		var other = get_device(other_id)
		if not other:
			continue
		if other is RouterDevice:
			var router_iface_name = conn.source_interface_name if conn.source_device_id == other_id else conn.dest_interface_name
			var offer = other.dhcp_discover(router_iface_name, dev.network_interfaces[iface_name].mac_address)
			if not offer.is_empty():
				return offer
		elif other is SwitchDevice:
			for other_conn in get_connections_for_device(other_id):
				if other_conn.id == conn.id:
					continue
				var next_id = other_conn.get_other_device_id(other_id)
				if next_id == device_id or _visited.has(next_id):
					continue
				# VLAN check: the DHCP request enters the switch via conn's port on the switch
				var switch_ingress = conn.source_interface_name if conn.source_device_id == other_id else conn.dest_interface_name
				var switch_egress = other_conn.source_interface_name if other_conn.source_device_id == other_id else other_conn.dest_interface_name
				if other.has_method("can_forward_between") and not other.can_forward_between(switch_ingress, switch_egress):
					continue
				var next_dev = get_device(next_id)
				if not next_dev:
					continue
				var next_iface = other_conn.source_interface_name if other_conn.source_device_id == next_id else other_conn.dest_interface_name
				if next_dev is RouterDevice:
					var offer = next_dev.dhcp_discover(next_iface, dev.network_interfaces[iface_name].mac_address)
					if not offer.is_empty():
						return offer
				elif next_dev is SwitchDevice:
					var offer2 = _find_dhcp_offer(next_id, next_iface, _depth + 1, _visited)
					if not offer2.is_empty():
						return offer2
	return {}

func remove_connection(link_id: String) -> void:
	for i in range(connections.size()):
		if connections[i].id == link_id:
			var link = connections[i]
			var src_dev = get_device(link.source_device_id)
			if src_dev and src_dev.network_interfaces.has(link.source_interface_name):
				src_dev.network_interfaces[link.source_interface_name].is_linked = false
				src_dev.network_interfaces[link.source_interface_name].link = null
			var dst_dev = get_device(link.dest_device_id)
			if dst_dev and dst_dev.network_interfaces.has(link.dest_interface_name):
				dst_dev.network_interfaces[link.dest_interface_name].is_linked = false
				dst_dev.network_interfaces[link.dest_interface_name].link = null
			connections.remove_at(i)
			EventBus.connection_removed.emit(link_id)
			break

func get_connections_for_device(device_id: String) -> Array:
	var res: Array = []
	for conn in connections:
		if conn.source_device_id == device_id or conn.dest_device_id == device_id:
			res.append(conn)
	return res

func get_link_between(device_id_a: String, device_id_b: String) -> EthernetLink:
	for conn in connections:
		if (conn.source_device_id == device_id_a and conn.dest_device_id == device_id_b) or (conn.source_device_id == device_id_b and conn.dest_device_id == device_id_a):
			return conn
	return null

func start_simulation() -> void:
	is_running = true
	SimTime.unpause()

func pause_simulation() -> void:
	is_running = false
	SimTime.pause()

func stop_simulation() -> void:
	is_running = false
	SimTime.reset()
	EventBus.simulation_stopped.emit()

func set_speed(s: float) -> void:
	speed = s
	SimTime.set_speed(s)

func clear() -> void:
	var dev_ids = devices.keys()
	for id in dev_ids:
		remove_device(id)
	connections.clear()
	_next_id = 1
	_next_link_id = 1

func get_device_count() -> int:
	return devices.size()

func get_connection_count() -> int:
	return connections.size()
