class_name NetworkSimulator
extends RefCounted

var engine

func _init(p_engine) -> void:
	engine = p_engine

func find_path(source_device_id: String, dest_ip: String) -> Array:
	var source_dev = engine.get_device(source_device_id)
	if not source_dev or not source_dev.is_powered_on:
		return []

	var dest_dev = _find_device_by_ip(dest_ip)
	if not dest_dev or not dest_dev.is_powered_on:
		return []

	var path = _trace_through_network(source_device_id, dest_dev.id, dest_ip)
	return path

func ping(source_device_id: String, dest_ip: String, count: int = 4) -> Dictionary:
	var source_dev = engine.get_device(source_device_id)
	var result = {
		"success": false,
		"results": [],
		"stats": {"sent": count, "received": 0, "lost_percent": 100.0},
		"error": "",
		"error_type": ""
	}
	
	if not source_dev or not source_dev.is_powered_on:
		result.error = "Source device is powered off"
		result.error_type = "source_down"
		return result
		
	var dest_dev = _find_device_by_ip(dest_ip)
	if not dest_dev:
		result.error = "Destination host unreachable: no device has address %s" % dest_ip
		result.error_type = "no_host"
		return result
	if not dest_dev.is_powered_on:
		result.error = "Destination host %s is powered off" % dest_ip
		result.error_type = "dest_down"
		return result
		
	var path = find_path(source_device_id, dest_ip)
	if path.is_empty():
		# Check if source has a route / is on same subnet or has gateway
		var has_route = false
		var src_iface_on_subnet = false
		for iface in source_dev.network_interfaces.values():
			if iface.ipv4_address != "" and iface.is_configured():
				if IPv4Address.is_same_subnet(iface.ipv4_address, dest_ip, iface.subnet_mask):
					src_iface_on_subnet = true
				if iface.gateway != "":
					has_route = true
		if not src_iface_on_subnet and not has_route:
			result.error = "Network unreachable: %s is not on any local subnet and no gateway is configured" % dest_ip
			result.error_type = "no_route"
		else:
			result.error = "No route to host %s (check links, power, and intermediate devices)" % dest_ip
			result.error_type = "no_path"
		return result
		
	# Check firewall on path and apply NAT at routers
	for hop in path:
		var dev = engine.get_device(hop.device_id)
		if dev is FirewallDevice:
			var allowed = dev.check_packet("icmp", "any", dest_ip, -1)
			if not allowed:
				result.error = "Destination unreachable: packet filtered by firewall %s" % dev.display_name
				result.error_type = "firewall"
				return result
		elif dev is RouterDevice and dev.nat_enabled:
			var src_dev = engine.get_device(source_device_id)
			if src_dev:
				var src_ip = _get_primary_ip(src_dev)
				if src_ip != "" and RouterDevice.is_private_ip(src_ip):
					dev.nat_translate_outbound(src_ip)
				
	var hop_count = max(1, path.size() - 1)
	# Compute latency from actual link latencies along the path (with congestion penalty)
	var base_latency = 0.0
	for i in range(path.size() - 1):
		var l = engine.get_link_between(path[i].device_id, path[i + 1].device_id)
		base_latency += l.get_congested_latency() if l else 1.0
	if base_latency <= 0.0:
		base_latency = hop_count * 1.5
	
	# Record traffic on each link for utilization tracking, and learn ARP
	for i in range(path.size() - 1):
		var l = engine.get_link_between(path[i].device_id, path[i + 1].device_id)
		if l:
			l.record_traffic(84 * count * 2)  # request+reply per packet
		# Learn ARP: each device learns the MAC of its neighbor on the shared link
		var dev_a = engine.get_device(path[i].device_id)
		var dev_b = engine.get_device(path[i + 1].device_id)
		if dev_a and dev_b:
			_learn_arp(dev_a, dev_b)
			_learn_arp(dev_b, dev_a)
	
	# Apply packet loss from links along the path
	var loss_chance = 0.0
	for i in range(path.size() - 1):
		var l = engine.get_link_between(path[i].device_id, path[i + 1].device_id)
		if l:
			loss_chance += l.packet_loss_percent
	loss_chance = minf(loss_chance, 100.0)
	
	for i in range(count):
		if loss_chance > 0.0 and randf() * 100.0 < loss_chance:
			result.results.append({"seq": i + 1, "time_ms": -1.0, "ttl": 0, "lost": true})
			continue
		var time_ms = snapped(base_latency + (i * 0.1), 0.1)
		result.results.append({"seq": i + 1, "time_ms": time_ms, "ttl": 64 - hop_count, "lost": false})
		result.stats.received += 1
		
	result.success = result.stats.received > 0
	result.stats.lost_percent = 100.0 * (count - result.stats.received) / count
	
	# Record packets for capture view
	var src_dev = engine.get_device(source_device_id)
	if src_dev:
		var src_ip = _get_primary_ip(src_dev)
		for r in result.results:
			PacketCapture.record(src_ip, dest_ip, "ICMP", 84, "echo request seq=%d" % r.seq)
			PacketCapture.record(dest_ip, src_ip, "ICMP", 84, "echo reply seq=%d" % r.seq)
	
	# Trigger packet animations along the path
	_animate_path_traffic(path, "ICMP")
	
	return result

func check_tcp_connection(source_device_id: String, dest_ip: String, dest_port: int) -> Dictionary:
	var path = find_path(source_device_id, dest_ip)
	if path.is_empty():
		return {"success": false, "message": "No route to host"}
		
	for hop in path:
		var dev = engine.get_device(hop.device_id)
		if dev is FirewallDevice:
			var allowed = dev.check_packet("tcp", "any", dest_ip, dest_port)
			if not allowed:
				return {"success": false, "message": "Connection filtered by firewall"}

	# Learn ARP along the path
	for i in range(path.size() - 1):
		var dev_a = engine.get_device(path[i].device_id)
		var dev_b = engine.get_device(path[i + 1].device_id)
		if dev_a and dev_b:
			_learn_arp(dev_a, dev_b)
			_learn_arp(dev_b, dev_a)

	var dest_dev = _find_device_by_ip(dest_ip)
	if dest_dev and "services" in dest_dev:
		var has_service = false
		for s in dest_dev.services:
			if s.port == dest_port and s.is_running:
				has_service = true
				break
		if not has_service:
			return {"success": false, "message": "Connection refused"}
			
	return {"success": true, "message": "Connected", "path": path}

func http_request(source_device_id: String, dest_ip: String, port: int = 80, path: String = "/") -> Dictionary:
	var tcp_check = check_tcp_connection(source_device_id, dest_ip, port)
	if not tcp_check.success:
		return {"success": false, "status_code": 0, "body": "", "error": tcp_check.message}
		
	var dest_dev = _find_device_by_ip(dest_ip)
	if dest_dev and "services" in dest_dev:
		for s in dest_dev.services:
			if s.port == port and s.is_running:
				var req_data = {"path": path, "method": "GET"}
				var response = s.handle_request(req_data)
				var src_dev2 = engine.get_device(source_device_id)
				var src_ip2 = _get_primary_ip(src_dev2) if src_dev2 else ""
				if response is Dictionary:
					var status = response.get("status", 200)
					var body = response.get("body", "")
					PacketCapture.record(src_ip2, dest_ip, "TCP", 64, "SYN %d->%d" % [0, port])
					PacketCapture.record(dest_ip, src_ip2, "TCP", int(str(body).length()) + 64, "SYN-ACK %d->%d HTTP %d" % [port, 0, status])
					if tcp_check.has("path"):
						_animate_path_traffic(tcp_check.path, "HTTP")
					return {"success": status == 200, "status_code": status, "body": str(body), "error": "" if status == 200 else str(body)}
				else:
					PacketCapture.record(src_ip2, dest_ip, "TCP", 64, "SYN %d->%d" % [0, port])
					PacketCapture.record(dest_ip, src_ip2, "TCP", 64, "SYN-ACK %d->%d" % [port, 0])
					if tcp_check.has("path"):
						_animate_path_traffic(tcp_check.path, "HTTP")
					return {"success": true, "status_code": 200, "body": str(response), "error": ""}
				
	return {"success": false, "status_code": 500, "body": "", "error": "Internal Error"}

func _find_device_by_ip(ip: String):
	for dev in engine.get_all_devices():
		for iface in dev.network_interfaces.values():
			if iface.ipv4_address == ip and iface.is_enabled:
				return dev
	return null

func _get_primary_ip(dev) -> String:
	for iface in dev.network_interfaces.values():
		if iface.ipv4_address != "" and iface.is_enabled:
			return iface.ipv4_address
	return ""

func _learn_arp(learner, neighbor) -> void:
	# Learner learns neighbor's IP->MAC on their shared link
	var shared_ips: Array = []
	var shared_macs: Array = []
	for iface_l in learner.network_interfaces.values():
		for iface_n in neighbor.network_interfaces.values():
			if iface_l.link and iface_l.link == iface_n.link:
				if iface_n.ipv4_address != "" and iface_n.is_enabled:
					shared_ips.append(iface_n.ipv4_address)
					shared_macs.append(iface_n.mac_address)
	for j in range(shared_ips.size()):
		learner.arp_table.add_entry(shared_ips[j], shared_macs[j])

func _is_on_same_subnet(ip1: String, mask: String, ip2: String) -> bool:
	return IPv4Address.is_same_subnet(ip1, ip2, mask)

func _trace_through_network(source_device_id: String, dest_device_id: String, dest_ip: String = "") -> Array:
	# Each queue item tracks dev, path so far, and the ingress interface on that device (for VLAN checks)
	var queue: Array = [{"dev_id": source_device_id, "path": [{"device_id": source_device_id, "interface_name": ""}], "ingress": ""}]
	var visited: Dictionary = {}
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var curr_dev_id = current.dev_id
		var curr_path = current.path
		var ingress_iface: String = current.ingress
		
		if curr_dev_id == dest_device_id:
			return curr_path
			
		# Mark (device, ingress_iface) visited to allow revisiting via different VLANs/ports
		var visit_key = curr_dev_id + "|" + ingress_iface
		if visited.has(visit_key):
			continue
		visited[visit_key] = true
		
		var dev = engine.get_device(curr_dev_id)
		if not dev or not dev.is_powered_on:
			continue
			
		# If router, optionally inspect routing table for next hop
		if dev is RouterDevice and dest_ip != "" and curr_dev_id != source_device_id:
			dev.auto_generate_routes()
			dev.route_packet(dest_ip)
			
		for conn in engine.get_connections_for_device(curr_dev_id):
			if not conn.is_enabled:
				continue
			var other_id = conn.get_other_device_id(curr_dev_id)
			var my_iface = conn.source_interface_name if conn.source_device_id == curr_dev_id else conn.dest_interface_name
			
			# VLAN check: if we entered a switch via ingress_iface, the outgoing port must be allowed
			if dev is SwitchDevice and ingress_iface != "":
				if not dev.can_forward_between(ingress_iface, my_iface):
					continue
			
			var other_dev = engine.get_device(other_id)
			if not other_dev or not other_dev.is_powered_on:
				continue
				
			var other_ingress = conn.get_other_interface_name(curr_dev_id)
			var new_path = curr_path.duplicate()
			new_path.append({"device_id": other_id, "interface_name": other_ingress})
			queue.append({"dev_id": other_id, "path": new_path, "ingress": other_ingress})
				
	return []

func _animate_path_traffic(path: Array, protocol: String) -> void:
	if path.size() < 2:
		return
	var tree = Engine.get_main_loop()
	if not tree or not tree.root:
		return
		
	# Find workspace connection lines to trigger animations
	var workspace = tree.root.find_child("Workspace", true, false)
	if workspace and "connection_lines" in workspace:
		for i in range(path.size() - 1):
			var d1 = path[i].device_id
			var d2 = path[i+1].device_id
			for link_id in workspace.connection_lines:
				var cline = workspace.connection_lines[link_id]
				if cline and cline.link_ref:
					var l = cline.link_ref
					if (l.source_device_id == d1 and l.dest_device_id == d2) or (l.source_device_id == d2 and l.dest_device_id == d1):
						cline.show_packet_animation(protocol)
