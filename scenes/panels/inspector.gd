extends PanelContainer

var _current_device: Device = null
var _content: VBoxContainer
var _no_selection_label: Label
var _update_timer: float = 0.0
var _workspace_ref = null

func _ready() -> void:
	custom_minimum_size.x = 260
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(margin)
	
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 6)
	margin.add_child(_content)
	
	_no_selection_label = Label.new()
	_no_selection_label.text = "No device selected"
	_no_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_selection_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_content.add_child(_no_selection_label)
	
	if EventBus.has_signal("device_selected"):
		EventBus.device_selected.connect(_on_device_selected)
	if EventBus.has_signal("selection_cleared"):
		EventBus.selection_cleared.connect(_on_selection_cleared)
	if EventBus.has_signal("device_updated"):
		EventBus.device_updated.connect(_on_device_updated)

func _on_device_updated(device_id: String) -> void:
	if _current_device and _current_device.id == device_id:
		_rebuild_inspector()

func _on_device_selected(device_or_id) -> void:
	if device_or_id is String:
		_current_device = SimEngine.get_device(device_or_id)
	elif device_or_id is Device:
		_current_device = device_or_id
	else:
		_current_device = null
	_rebuild_inspector()

func _on_selection_cleared() -> void:
	_current_device = null
	_show_no_selection()

func _show_no_selection() -> void:
	for child in _content.get_children():
		child.queue_free()
	
	var lbl = Label.new()
	lbl.text = "No device selected"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_content.add_child(lbl)

func _rebuild_inspector() -> void:
	for child in _content.get_children():
		child.queue_free()
	
	if not _current_device:
		_show_no_selection()
		return
	
	var header = Label.new()
	header.text = "INSPECTOR"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_content.add_child(header)
	
	var title = Label.new()
	title.text = _current_device.display_name
	title.add_theme_font_size_override("font_size", 16)
	_content.add_child(title)
	
	var type_lbl = Label.new()
	type_lbl.text = "Type: " + _current_device.get_device_type_display()
	type_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_content.add_child(type_lbl)
	
	var id_lbl = Label.new()
	id_lbl.text = "ID: " + _current_device.id
	id_lbl.add_theme_font_size_override("font_size", 10)
	id_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_content.add_child(id_lbl)
	
	var status = Label.new()
	var powered = _current_device.is_powered_on
	status.text = "Status: " + ("Running" if powered else "Powered Off")
	status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2) if powered else Color(0.8, 0.2, 0.2))
	_content.add_child(status)
	
	_content.add_child(HSeparator.new())
	
	if _current_device is Computer:
		var comp = _current_device as Computer
		var hw_lbl = Label.new()
		hw_lbl.text = "HARDWARE"
		hw_lbl.add_theme_font_size_override("font_size", 11)
		hw_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		_content.add_child(hw_lbl)
		
		var cpu = Label.new()
		cpu.text = "CPU: %d cores (%.1f%%)" % [comp.cpu_cores, comp.get_cpu_usage()]
		_content.add_child(cpu)
		
		var ram = Label.new()
		ram.text = "RAM: %.0f MB / %s" % [comp.get_ram_usage(), _format_bytes(comp.ram_mb)]
		_content.add_child(ram)
		
		var stor = Label.new()
		stor.text = "Storage: %s" % _format_bytes(comp.storage_mb)
		_content.add_child(stor)
		
		if comp.operating_system:
			_content.add_child(HSeparator.new())
			var os_lbl = Label.new()
			os_lbl.text = "OPERATING SYSTEM"
			os_lbl.add_theme_font_size_override("font_size", 11)
			os_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
			_content.add_child(os_lbl)
			
			var osn = Label.new()
			osn.text = "OS: " + comp.operating_system.os_name
			_content.add_child(osn)
			
			var hn = Label.new()
			hn.text = "Hostname: " + comp.operating_system.hostname
			_content.add_child(hn)
	
	if _current_device is Server:
		var srv = _current_device as Server
		_content.add_child(HSeparator.new())
		var srv_lbl = Label.new()
		srv_lbl.text = "SERVICES"
		srv_lbl.add_theme_font_size_override("font_size", 11)
		srv_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		_content.add_child(srv_lbl)
		
		for s in srv.services:
			var s_row = HBoxContainer.new()
			var s_name = Label.new()
			s_name.text = "%s :%d" % [s.service_name.to_upper(), s.port]
			s_name.size_flags_horizontal = SIZE_EXPAND_FILL
			s_row.add_child(s_name)
			
			var s_stat = Label.new()
			s_stat.text = s.get_status_string()
			s_stat.add_theme_color_override("font_color", Color.GREEN if s.is_running else Color.RED)
			s_row.add_child(s_stat)
			_content.add_child(s_row)
	
	if _current_device is RouterDevice:
		var router = _current_device as RouterDevice
		_content.add_child(HSeparator.new())
		var rt_lbl = Label.new()
		rt_lbl.text = "ROUTER / DHCP"
		rt_lbl.add_theme_font_size_override("font_size", 11)
		rt_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		_content.add_child(rt_lbl)
		
		var dhcp_state = Label.new()
		dhcp_state.text = "DHCP: " + ("ON (.%d–.%d)" % [router.dhcp_pool_start, router.dhcp_pool_end] if router.dhcp_enabled else "OFF")
		dhcp_state.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5) if router.dhcp_enabled else Color(0.8, 0.5, 0.4))
		_content.add_child(dhcp_state)
		
		var lease_lbl = Label.new()
		lease_lbl.text = "Leases: %d" % router.dhcp_leases.size()
		lease_lbl.add_theme_font_size_override("font_size", 11)
		_content.add_child(lease_lbl)
		for mac in router.dhcp_leases:
			var lease = Label.new()
			lease.text = "  %s → %s" % [mac, router.dhcp_leases[mac]]
			lease.add_theme_font_size_override("font_size", 10)
			lease.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
			_content.add_child(lease)
		
		var routes = router.routing_table.get_all_routes() if router.routing_table else []
		var routes_lbl = Label.new()
		routes_lbl.text = "Routes: %d" % routes.size()
		routes_lbl.add_theme_font_size_override("font_size", 11)
		_content.add_child(routes_lbl)
		for r in routes:
			var rl = Label.new()
			rl.text = "  %s/%d [%s]" % [r.network, r.cidr, r.interface_name]
			rl.add_theme_font_size_override("font_size", 10)
			rl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
			_content.add_child(rl)
	
	if _current_device is StorageDevice:
		var stor = _current_device as StorageDevice
		_content.add_child(HSeparator.new())
		var st_lbl = Label.new()
		st_lbl.text = "STORAGE"
		st_lbl.add_theme_font_size_override("font_size", 11)
		st_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		_content.add_child(st_lbl)
		
		var cap = Label.new()
		cap.text = "Capacity: %d GB" % (stor.total_capacity_mb / 1024)
		_content.add_child(cap)
		
		var used = Label.new()
		used.text = "Used: %d MB (%.1f%%)" % [stor.used_mb, stor.get_usage_percent()]
		_content.add_child(used)
		
		var sh_lbl = Label.new()
		sh_lbl.text = "Shares (%d):" % stor.shares.size()
		sh_lbl.add_theme_font_size_override("font_size", 11)
		_content.add_child(sh_lbl)
		for s in stor.shares:
			var sl = Label.new()
			sl.text = "  %s — %d MB" % [s.name, int(s.size_mb)]
			sl.add_theme_font_size_override("font_size", 10)
			sl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
			_content.add_child(sl)
		
		var btn_shares = Button.new()
		btn_shares.text = "Manage Shares…"
		btn_shares.pressed.connect(_open_shares)
		_content.add_child(btn_shares)
	
	_content.add_child(HSeparator.new())
	
	var net_lbl = Label.new()
	net_lbl.text = "NETWORK INTERFACES"
	net_lbl.add_theme_font_size_override("font_size", 11)
	net_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_content.add_child(net_lbl)
	
	for iface in _current_device.network_interfaces.values():
		var if_box = VBoxContainer.new()
		if_box.add_theme_constant_override("separation", 2)
		
		var if_name_lbl = Label.new()
		var link_tag = " [CONNECTED]" if iface.is_linked else " [UNLINKED]"
		if_name_lbl.text = iface.iface_name + link_tag
		if_name_lbl.add_theme_font_size_override("font_size", 12)
		if_box.add_child(if_name_lbl)
		
		var mac = Label.new()
		mac.text = "  MAC: " + iface.mac_address
		mac.add_theme_font_size_override("font_size", 10)
		mac.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		if_box.add_child(mac)
		
		var ip_str = iface.ipv4_address if iface.ipv4_address != "" else "(none)"
		var mask_str = "/" + str(iface.get_cidr()) if iface.get_cidr() > 0 else ""
		var ip_lbl = Label.new()
		ip_lbl.text = "  IP: " + ip_str + mask_str
		ip_lbl.add_theme_font_size_override("font_size", 11)
		if_box.add_child(ip_lbl)
		
		var btn_cfg = Button.new()
		btn_cfg.text = "Configure IP"
		var iname = iface.iface_name
		btn_cfg.pressed.connect(func(): _open_ip_config(iname))
		if_box.add_child(btn_cfg)
		
		_content.add_child(if_box)
	
	_content.add_child(HSeparator.new())
	
	var act_lbl = Label.new()
	act_lbl.text = "ACTIONS"
	act_lbl.add_theme_font_size_override("font_size", 11)
	act_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_content.add_child(act_lbl)
	
	if _current_device is Computer or _current_device is StorageDevice:
		var btn_term = Button.new()
		btn_term.text = "Open Terminal"
		btn_term.pressed.connect(_open_terminal)
		_content.add_child(btn_term)
	
	var btn_cfg = Button.new()
	btn_cfg.text = "Configure…"
	btn_cfg.pressed.connect(_open_config)
	_content.add_child(btn_cfg)
	
	var btn_pwr = Button.new()
	btn_pwr.text = "Power Off" if _current_device.is_powered_on else "Power On"
	btn_pwr.pressed.connect(_toggle_power)
	_content.add_child(btn_pwr)
	
	if _current_device.network_interfaces.size() > 0:
		var btn_conn = Button.new()
		btn_conn.text = "Connect Cable"
		btn_conn.pressed.connect(_start_connect)
		_content.add_child(btn_conn)

func _format_bytes(mb: int) -> String:
	if mb >= 1024:
		return "%.1f GB" % (float(mb) / 1024.0)
	return "%d MB" % mb

func _open_terminal() -> void:
	if not _current_device: return
	var term_class = load("res://scenes/terminal/terminal_window.gd")
	if term_class:
		var win = Window.new()
		win.set_script(term_class)
		get_tree().root.add_child(win)
		if win.has_method("setup"):
			win.setup(_current_device.id)
		win.popup_centered()

func _open_config() -> void:
	if not _current_device: return
	var dlg_class = load("res://scenes/dialogs/device_config_dialog.gd")
	if dlg_class:
		var win = Window.new()
		win.set_script(dlg_class)
		get_tree().root.add_child(win)
		if win.has_method("setup"):
			win.setup(_current_device.id)
		win.popup_centered()

func _open_shares() -> void:
	if not _current_device: return
	var dlg_class = load("res://scenes/dialogs/shares_dialog.gd")
	if dlg_class:
		var win = Window.new()
		win.set_script(dlg_class)
		get_tree().root.add_child(win)
		if win.has_method("setup"):
			win.setup(_current_device.id)
		win.popup_centered()

func _toggle_power() -> void:
	if not _current_device: return
	if _current_device.is_powered_on:
		_current_device.power_off()
	else:
		_current_device.power_on()
	if EventBus:
		EventBus.device_updated.emit(_current_device.id)
	_rebuild_inspector()

func _open_ip_config(iface_name: String) -> void:
	if not _current_device: return
	var cfg_class = load("res://scenes/dialogs/ip_config_dialog.gd")
	if cfg_class:
		var win = Window.new()
		win.set_script(cfg_class)
		get_tree().root.add_child(win)
		var iface = _current_device.get_interface(iface_name)
		if win.has_method("setup") and iface:
			win.setup(_current_device.id, iface_name, iface.ipv4_address, iface.subnet_mask, iface.gateway)
		win.popup_centered()

func _start_connect() -> void:
	if not _current_device or not _workspace_ref: return
	if _current_device.network_interfaces.size() > 0:
		var first_iface = _current_device.network_interfaces.values()[0]
		_workspace_ref.start_connection(_current_device.id, first_iface.iface_name)

func _process(delta: float) -> void:
	if _current_device:
		_update_timer += delta
		if _update_timer >= 2.0:
			_update_timer = 0.0
			_rebuild_inspector()
