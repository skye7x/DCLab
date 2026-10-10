class_name CommandProcessor extends RefCounted

var device_id: String
var current_directory: String = "/"
var os_ref: OperatingSystem
var commands: Dictionary = {}
var engine_ref = null

func _init(p_device_id: String, p_os: OperatingSystem):
	device_id = p_device_id
	os_ref = p_os
	
	if os_ref and os_ref.current_user:
		current_directory = os_ref.current_user.home_directory
	
	commands["help"] = _cmd_help
	commands["clear"] = _cmd_clear
	commands["pwd"] = _cmd_pwd
	commands["ls"] = _cmd_ls
	commands["cd"] = _cmd_cd
	commands["cat"] = _cmd_cat
	commands["mkdir"] = _cmd_mkdir
	commands["touch"] = _cmd_touch
	commands["rm"] = _cmd_rm
	commands["echo"] = _cmd_echo
	commands["whoami"] = _cmd_whoami
	commands["hostname"] = _cmd_hostname
	commands["ps"] = _cmd_ps
	commands["kill"] = _cmd_kill
	commands["ip"] = _cmd_ip
	commands["ping"] = _cmd_ping
	commands["service"] = _cmd_service
	commands["curl"] = _cmd_curl
	commands["ifconfig"] = _cmd_ifconfig
	commands["route"] = _cmd_route
	commands["dhclient"] = _cmd_dhclient
	commands["df"] = _cmd_df
	commands["shares"] = _cmd_shares
	commands["share"] = _cmd_share
	commands["mount"] = _cmd_mount
	commands["traceroute"] = _cmd_traceroute
	commands["tracert"] = _cmd_traceroute
	commands["nat"] = _cmd_nat

func _get_engine():
	if engine_ref:
		return engine_ref
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("SimEngine"):
		return tree.root.get_node("SimEngine")
	return null

func process_input(input_text: String) -> String:
	input_text = input_text.strip_edges()
	if input_text == "":
		return ""
		
	var args: Array = []
	var raw_parts = input_text.split(" ", false)
	for part in raw_parts:
		if part != "":
			args.append(part)
			
	if args.size() == 0:
		return ""
		
	var cmd = args[0]
	if commands.has(cmd):
		return commands[cmd].call(args)
	else:
		return "bash: %s: command not found" % cmd

func get_prompt() -> String:
	var user = os_ref.current_user.username if os_ref and os_ref.current_user else "root"
	var host = os_ref.hostname if os_ref else "localhost"
	var cwd = current_directory
	var home = os_ref.current_user.home_directory if os_ref and os_ref.current_user else "/root"
	if cwd.begins_with(home):
		cwd = "~" + cwd.substr(home.length())
	var symbol = "#" if user == "root" else "$"
	return "%s@%s:%s%s " % [user, host, cwd, symbol]

func _cmd_help(args: Array) -> String:
	var output = "Available commands:\n"
	output += "  Files:   help clear pwd ls cd cat mkdir touch rm echo\n"
	output += "  System:  whoami hostname ps kill df mount\n"
	output += "  Network: ip ifconfig route ping curl traceroute nat\n"
	output += "  DHCP:    dhclient <iface>        request an address\n"
	output += "  IP set:  ip addr add <ip>/<cidr> dev <iface>\n"
	output += "           ip addr del dev <iface>\n"
	output += "  Services:service <name> <start|stop|restart|status>\n"
	output += "  NAS:     shares                  list shares\n"
	output += "           share add <name> <MB>   create a share\n"
	output += "           share rm <name>         delete a share\n"
	output += "\nExamples:\n"
	output += "  ping 192.168.10.1 -c 4\n"
	output += "  ip addr add 192.168.10.50/24 dev eth0\n"
	output += "  curl http://192.168.10.10/"
	return output

func _cmd_clear(args: Array) -> String:
	return "[CLEAR]"

func _cmd_pwd(args: Array) -> String:
	return current_directory

func _cmd_ls(args: Array) -> String:
	var target_dir = current_directory
	if args.size() > 1:
		target_dir = os_ref.file_system.resolve_path(current_directory, args[1])
	
	if not os_ref.file_system.exists(target_dir):
		return "ls: cannot access '%s': No such file or directory" % (args[1] if args.size() > 1 else target_dir)
	if not os_ref.file_system.is_dir(target_dir):
		var parts = target_dir.split("/")
		return parts[parts.size()-1]
		
	var children = os_ref.file_system.list_directory(target_dir)
	var output = []
	for child in children:
		var name = child.node_name
		if child.is_directory:
			name += "/"
		output.append(name)
	return "  ".join(output)

func _cmd_cd(args: Array) -> String:
	var target_dir = "~"
	if args.size() > 1:
		target_dir = args[1]
		
	if target_dir == "~":
		target_dir = os_ref.current_user.home_directory if os_ref and os_ref.current_user else "/root"
		
	var resolved = os_ref.file_system.resolve_path(current_directory, target_dir)
	
	if not os_ref.file_system.exists(resolved):
		return "bash: cd: %s: No such file or directory" % target_dir
	if not os_ref.file_system.is_dir(resolved):
		return "bash: cd: %s: Not a directory" % target_dir
		
	current_directory = resolved
	return ""

func _cmd_cat(args: Array) -> String:
	if args.size() < 2:
		return ""
	var resolved = os_ref.file_system.resolve_path(current_directory, args[1])
	var result = os_ref.file_system.read_file(resolved)
	if result == "File not found" or result == "Is a directory":
		return "cat: %s: %s" % [args[1], result]
	return result

func _cmd_mkdir(args: Array) -> String:
	if args.size() < 2:
		return "mkdir: missing operand"
	var resolved = os_ref.file_system.resolve_path(current_directory, args[1])
	var err = os_ref.file_system.create_directory(resolved)
	if err != "":
		return "mkdir: cannot create directory '%s': %s" % [args[1], err]
	return ""

func _cmd_touch(args: Array) -> String:
	if args.size() < 2:
		return "touch: missing file operand"
	var resolved = os_ref.file_system.resolve_path(current_directory, args[1])
	if os_ref.file_system.exists(resolved):
		return ""
	var err = os_ref.file_system.create_file(resolved)
	if err != "":
		return "touch: cannot touch '%s': %s" % [args[1], err]
	return ""

func _cmd_rm(args: Array) -> String:
	if args.size() < 2:
		return "rm: missing operand"
	
	var recursive = false
	var target = ""
	
	for i in range(1, args.size()):
		if args[i] == "-r" or args[i] == "-rf":
			recursive = true
		else:
			target = args[i]
			
	if target == "":
		return "rm: missing operand"
		
	var resolved = os_ref.file_system.resolve_path(current_directory, target)
	
	if resolved == "/":
		return "rm: it is dangerous to operate recursively on '/'"
		
	if os_ref.file_system.is_dir(resolved) and not recursive:
		return "rm: cannot remove '%s': Is a directory" % target
		
	var err = os_ref.file_system.delete_node(resolved)
	if err != "":
		return "rm: cannot remove '%s': %s" % [target, err]
	return ""

func _cmd_echo(args: Array) -> String:
	var redirect_idx = -1
	for i in range(args.size()):
		if args[i] == ">" or args[i] == ">>":
			redirect_idx = i
			break
			
	if redirect_idx != -1:
		if redirect_idx + 1 >= args.size():
			return "bash: syntax error near unexpected token `newline'"
			
		var text = " ".join(args.slice(1, redirect_idx))
		var file_path = os_ref.file_system.resolve_path(current_directory, args[redirect_idx + 1])
		var err = os_ref.file_system.write_file(file_path, text + "\n")
		if err != "":
			return "bash: %s: %s" % [args[redirect_idx + 1], err]
		return ""
	else:
		return " ".join(args.slice(1, args.size()))

func _cmd_whoami(args: Array) -> String:
	if os_ref and os_ref.current_user:
		return os_ref.current_user.username
	return "root"

func _cmd_hostname(args: Array) -> String:
	if os_ref:
		return os_ref.hostname
	return "localhost"

func _cmd_ps(args: Array) -> String:
	var output = "  PID TTY          TIME CMD\n"
	if os_ref:
		for p in os_ref.get_processes():
			output += "%5d ?        00:00:00 %s\n" % [p.pid, p.process_name]
	return output.strip_edges()

func _cmd_kill(args: Array) -> String:
	if args.size() < 2:
		return "kill: usage: kill <pid>"
	if os_ref:
		os_ref.remove_process(int(args[1]))
	return ""

func _notify_device_updated() -> void:
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("EventBus"):
		tree.root.get_node("EventBus").device_updated.emit(device_id)

func _cmd_ip(args: Array) -> String:
	var engine = _get_engine()
	if not engine:
		return "Error: Cannot access simulation engine"
		
	var device = engine.get_device(device_id)
	if not device:
		return "Error: Device not found"
		
	var output = ""
	var i = 1
	
	if args.size() >= 3 and args[1] == "addr" and args[2] == "show":
		var iface_name = args[3] if args.size() > 3 else ""
		if iface_name != "" and device.network_interfaces.has(iface_name):
			var iface = device.network_interfaces[iface_name]
			output += "%d: %s: <UP> mtu 1500\n" % [i, iface.iface_name]
			var cidr = iface.get_cidr()
			var cidr_str = str(cidr) if cidr > 0 else "24"
			output += "    link/ether %s\n" % iface.mac_address
			output += "    inet %s/%s\n" % [iface.ipv4_address, cidr_str]
		else:
			return "Device '%s' does not exist." % iface_name
	elif args.size() >= 4 and args[1] == "addr" and args[2] == "add":
		var spec = args[3]
		var iface_name = "eth0"
		for idx in range(args.size()):
			if args[idx] == "dev" and idx + 1 < args.size():
				iface_name = args[idx + 1]
		if not device.network_interfaces.has(iface_name):
			return "Device '%s' does not exist." % iface_name
		var ip_part = spec
		var cidr = 24
		if spec.contains("/"):
			var parts = spec.split("/")
			ip_part = parts[0]
			cidr = int(parts[1]) if parts.size() > 1 and parts[1].is_valid_int() else 24
		if not IPv4Address.is_valid(ip_part):
			return "Error: invalid address '%s'" % ip_part
		var iface = device.network_interfaces[iface_name]
		iface.configure(ip_part, IPv4Address.cidr_to_mask(cidr), iface.gateway)
		_notify_device_updated()
		return ""
	elif args.size() >= 3 and args[1] == "addr" and args[2] == "del":
		var iface_name = "eth0"
		for idx in range(args.size()):
			if args[idx] == "dev" and idx + 1 < args.size():
				iface_name = args[idx + 1]
		if not device.network_interfaces.has(iface_name):
			return "Device '%s' does not exist." % iface_name
		var iface = device.network_interfaces[iface_name]
		iface.configure("", "", "")
		_notify_device_updated()
		return ""
	else:
		for key in device.network_interfaces:
			var iface = device.network_interfaces[key]
			var state = "<UP>" if iface.is_enabled else "<DOWN>"
			output += "%d: %s: %s mtu 1500\n" % [i, iface.iface_name, state]
			output += "    link/ether %s\n" % iface.mac_address
			if iface.ipv4_address != "":
				var cidr = iface.get_cidr()
				var cidr_str = str(cidr) if cidr > 0 else "24"
				output += "    inet %s/%s\n" % [iface.ipv4_address, cidr_str]
			i += 1
			
	return output.strip_edges()

func _cmd_ping(args: Array) -> String:
	if args.size() < 2:
		return "Usage: ping <ip>"
		
	var target_ip = args[args.size() - 1]
	var count = 4
	for i in range(args.size()):
		if args[i] == "-c" and i + 1 < args.size():
			count = int(args[i+1])
			
	var engine = _get_engine()
	if not engine or not engine.network_sim:
		return "Error: Network simulator not available"
		
	var res = engine.network_sim.ping(device_id, target_ip, count)
	if not res.get("success", false):
		return "PING %s\nRequest timeout.\n\n--- %s ping statistics ---\n%d packets transmitted, 0 received, 100%% packet loss" % [target_ip, target_ip, count]
		
	var out = "PING %s (%s) 56(84) bytes of data.\n" % [target_ip, target_ip]
	for r in res.results:
		out += "64 bytes from %s: icmp_seq=%d ttl=%d time=%.1f ms\n" % [target_ip, r.seq, r.ttl, r.time_ms]
		
	out += "\n--- %s ping statistics ---\n" % target_ip
	out += "%d packets transmitted, %d received, %d%% packet loss" % [
		res.stats.sent,
		res.stats.received,
		int(res.stats.lost_percent)
	]
	return out

func _cmd_service(args: Array) -> String:
	if args.size() < 3:
		return "Usage: service <name> <start|stop|restart|status>"
		
	var service_name = args[1]
	var action = args[2]
	
	var engine = _get_engine()
	if not engine:
		return "Error: No engine"
	var device = engine.get_device(device_id)
	
	if not device or not ("services" in device):
		return "%s: unrecognized service" % service_name
		
	# Alias nginx -> http
	var lookup_name = service_name
	if service_name == "nginx" or service_name == "apache":
		lookup_name = "http"
		
	for s in device.services:
		if s.service_name == lookup_name or s.service_name == service_name:
			if action == "start":
				s.start()
				return "%s is started" % service_name
			elif action == "stop":
				s.stop()
				return "%s is stopped" % service_name
			elif action == "restart":
				s.stop()
				s.start()
				return "%s restarted" % service_name
			elif action == "status":
				return "%s is %s" % [service_name, "running" if s.is_running else "stopped"]
	
	return "%s: unrecognized service" % service_name

func _cmd_curl(args: Array) -> String:
	if args.size() < 2:
		return "curl: try 'curl --help' for more information"
		
	var url = args[1]
	if url.begins_with("http://"):
		url = url.substr(7)
	
	var ip = url
	var port = 80
	var path = "/"
	
	var slash_idx = url.find("/")
	if slash_idx != -1:
		path = url.substr(slash_idx)
		ip = url.substr(0, slash_idx)
		
	var colon_idx = ip.find(":")
	if colon_idx != -1:
		port = int(ip.substr(colon_idx + 1))
		ip = ip.substr(0, colon_idx)
		
	var engine = _get_engine()
	if not engine or not engine.network_sim:
		return "Error: Network simulator not available"
		
	var res = engine.network_sim.http_request(device_id, ip, port, path)
	if res.get("success", false):
		return res.get("body", "")
	else:
		return "curl: (7) Failed to connect to %s port %d: %s" % [ip, port, res.get("error", "Connection failed")]

func _cmd_ifconfig(args: Array) -> String:
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device: return "Error"
	
	if args.size() == 1:
		var output = ""
		for key in device.network_interfaces:
			var iface = device.network_interfaces[key]
			output += "%s: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500\n" % iface.iface_name
			if iface.ipv4_address != "":
				output += "        inet %s  netmask %s\n" % [iface.ipv4_address, iface.subnet_mask]
			output += "        ether %s  txqueuelen 1000 (Ethernet)\n" % iface.mac_address
		return output.strip_edges()
	elif args.size() >= 3:
		var iface_name = args[1]
		var ip = args[2]
		var netmask = "255.255.255.0"
		for i in range(args.size()):
			if args[i] == "netmask" and i + 1 < args.size():
				netmask = args[i+1]
				
		if device.network_interfaces.has(iface_name):
			device.network_interfaces[iface_name].ipv4_address = ip
			device.network_interfaces[iface_name].subnet_mask = netmask
			_notify_device_updated()
			return ""
		else:
			return "SIOCSIFADDR: No such device"
			
	return "Usage: ifconfig [interface] [ip] [netmask mask]"

func _cmd_route(args: Array) -> String:
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device: return "Error"
	
	if device is RouterDevice and device.routing_table:
		var routes = device.routing_table.get_all_routes()
		var out = "Kernel IP routing table\n"
		out += "Destination     Gateway         Genmask         Flags Metric Iface\n"
		for r in routes:
			var mask = IPv4Address.cidr_to_mask(r.cidr)
			var gw = r.gateway if r.gateway != "" else "0.0.0.0"
			out += "%-15s %-15s %-15s U     %-6d %s\n" % [r.network, gw, mask, r.metric, r.interface_name]
		return out.strip_edges()
	else:
		return "Default gateway configured on eth0"

func _cmd_dhclient(args: Array) -> String:
	var engine = _get_engine()
	if not engine:
		return "Error: Cannot access simulation engine"
	var device = engine.get_device(device_id)
	if not device:
		return "Error: Device not found"
	var iface_name = args[1] if args.size() > 1 else "eth0"
	if not device.network_interfaces.has(iface_name):
		return "Device '%s' does not exist." % iface_name
	var iface = device.network_interfaces[iface_name]
	if iface.is_configured():
		return "%s already has an address (%s)" % [iface_name, iface.ipv4_address]
	var offer = engine._find_dhcp_offer(device_id, iface_name)
	if offer.is_empty():
		return "DHCPDISCOVER on %s: no DHCP servers available" % iface_name
	iface.configure(offer.ip, offer.mask, offer.gateway)
	_notify_device_updated()
	return "DHCPOFFER %s\nbound to %s/%s via %s" % [offer.ip, offer.ip, iface.get_cidr(), offer.gateway]

func _cmd_df(args: Array) -> String:
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device: return "Error"
	var out = "Filesystem     Size  Used Avail Use%% Mounted on\n"
	if "total_capacity_mb" in device:
		var total_gb = device.total_capacity_mb / 1024.0
		var used_gb = device.used_mb / 1024.0
		var free_gb = maxf(0.0, total_gb - used_gb)
		out += "nas-pool      %5.0fG %4.0fG %4.0fG  %2.0f%% /volume1\n" % [total_gb, used_gb, free_gb, device.get_usage_percent()]
	if "storage_mb" in device and device is Computer:
		out += "rootfs        %5.0fG %4.0fG %4.0fG  %2.0f%% /\n" % [device.storage_mb / 1024.0, 3.2, device.storage_mb / 1024.0 - 3.2, 12.0]
	return out.strip_edges()

func _cmd_shares(args: Array) -> String:
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device: return "Error"
	if not ("shares" in device):
		return "No share support on this device"
	if device.shares.is_empty():
		return "No shares configured"
	var out = "NAME       PATH                 SIZE     MODE\n"
	for s in device.shares:
		out += "%-10s %-20s %6dMB  %s\n" % [s.name, s.path, int(s.size_mb), "ro" if s.get("read_only", false) else "rw"]
	return out.strip_edges()

func _cmd_share(args: Array) -> String:
	if args.size() < 2:
		return "Usage: share add <name> <MB> | share rm <name>"
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device: return "Error"
	if not ("shares" in device):
		return "No share support on this device"
	match args[1]:
		"add":
			if args.size() < 4:
				return "Usage: share add <name> <MB>"
			var err = device.add_share(args[2], int(args[3]) if args[3].is_valid_int() else 0)
			if err != "":
				return err
			_notify_device_updated()
			return "Share '%s' created (%s)" % [args[2], args[3]]
		"rm":
			if args.size() < 3:
				return "Usage: share rm <name>"
			var err = device.remove_share(args[2])
			if err != "":
				return err
			_notify_device_updated()
			return "Share '%s' removed" % args[2]
	return "Usage: share add <name> <MB> | share rm <name>"

func _cmd_mount(args: Array) -> String:
	if args.size() < 2:
		var engine = _get_engine()
		if not engine: return "Error"
		var device = engine.get_device(device_id)
		if device and "shares" in device and device.shares.size() > 0:
			var out = ""
			for s in device.shares:
				out += "/mnt/%s on %s type nfs\n" % [s.name, s.path]
			return out.strip_edges()
		return "Usage: mount <share>"
	return "mount: /mnt/%s: share not found" % args[1]

func _cmd_traceroute(args: Array) -> String:
	if args.size() < 2:
		return "Usage: traceroute <ip>"
	var target_ip = args[args.size() - 1]
	var engine = _get_engine()
	if not engine or not engine.network_sim:
		return "Error: Network simulator not available"
	var path = engine.network_sim.find_path(device_id, target_ip)
	if path.is_empty():
		return "traceroute to %s, 30 hops max\n* * *\ntraceroute: no route to host" % target_ip
	var out = "traceroute to %s (%s), 30 hops max\n" % [target_ip, target_ip]
	var cumulative_ms := 0.0
	for i in range(path.size()):
		var hop_dev = engine.get_device(path[i].device_id)
		if not hop_dev:
			continue
		var hop_ip = _get_iface_ip_for_path(hop_dev, path, i)
		var hop_name = hop_dev.display_name if hop_dev.display_name != "" else hop_dev.id
		var link_ms := 0.0
		if i > 0:
			var link = engine.get_link_between(path[i - 1].device_id, path[i].device_id)
			if link:
				link_ms = link.latency_ms
			else:
				link_ms = 1.0
		cumulative_ms += link_ms + 0.2
		out += " %2d  %s (%s)  %.3f ms  %.3f ms  %.3f ms\n" % [
			i + 1, hop_name, hop_ip, cumulative_ms, cumulative_ms + 0.1, cumulative_ms + 0.2
		]
	return out.strip_edges()

func _get_iface_ip_for_path(dev, path: Array, idx: int) -> String:
	var iface_name: String = path[idx].get("interface_name", "")
	if iface_name != "" and "network_interfaces" in dev and dev.network_interfaces.has(iface_name):
		var iface = dev.network_interfaces[iface_name]
		if iface.ipv4_address != "":
			return iface.ipv4_address
	if "network_interfaces" in dev:
		for key in dev.network_interfaces:
			var iface = dev.network_interfaces[key]
			if iface.ipv4_address != "" and iface.is_enabled:
				return iface.ipv4_address
	return "0.0.0.0"

func _cmd_nat(args: Array) -> String:
	var engine = _get_engine()
	if not engine: return "Error"
	var device = engine.get_device(device_id)
	if not device or not (device is RouterDevice):
		return "nat: not a router"
	var router = device as RouterDevice
	var action = args[1] if args.size() > 1 else "show"
	match action:
		"on":
			router.nat_enabled = true
			_notify_device_updated()
			return "NAT enabled (WAN: %s)" % router.wan_interface
		"off":
			router.nat_enabled = false
			_notify_device_updated()
			return "NAT disabled"
		"clear":
			router.nat_clear()
			return "NAT table cleared"
		"wan":
			if args.size() < 3:
				return "Usage: nat wan <iface>"
			if not router.network_interfaces.has(args[2]):
				return "No such interface: %s" % args[2]
			router.wan_interface = args[2]
			return "WAN interface set to %s" % args[2]
		"show", _:
			var out = "NAT is %s (WAN: %s)\n" % ["enabled" if router.nat_enabled else "disabled", router.wan_interface]
			if router.nat_table.is_empty():
				out += "No translations"
			else:
				out += "INTERNAL        EXTERNAL        HITS\n"
				for internal_ip in router.nat_table:
					var e = router.nat_table[internal_ip]
					out += "%-15s %-15s %d\n" % [internal_ip, e.external_ip, int(e.hits)]
			return out.strip_edges()
	return ""
