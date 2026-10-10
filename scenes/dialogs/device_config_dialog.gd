extends Window

var _device_id: String = ""
var _name_input: LineEdit
var _content: VBoxContainer

func setup(device_id: String) -> void:
	_device_id = device_id

func _ready() -> void:
	title = "Device Configuration"
	size = Vector2i(520, 560)
	min_size = Vector2i(420, 380)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)

	close_requested.connect(queue_free)
	_rebuild()

func _get_device():
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	return engine.get_device(_device_id) if engine else null

func _rebuild() -> void:
	for child in _content.get_children():
		child.queue_free()

	var dev = _get_device()
	if not dev:
		var lbl = Label.new()
		lbl.text = "Device not found."
		_content.add_child(lbl)
		return

	_section_header("GENERAL")

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(grid)

	grid.add_child(_field_label("Name:"))
	_name_input = LineEdit.new()
	_name_input.text = dev.display_name
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_name_input)

	grid.add_child(_field_label("Type:"))
	grid.add_child(_field_label(dev.get_device_type_display()))

	grid.add_child(_field_label("ID:"))
	grid.add_child(_field_label(dev.id))

	grid.add_child(_field_label("Status:"))
	grid.add_child(_field_label("Powered On" if dev.is_powered_on else "Powered Off"))

	var btn_apply_name = Button.new()
	btn_apply_name.text = " Apply Name "
	btn_apply_name.pressed.connect(_on_apply_name)
	_content.add_child(btn_apply_name)

	_content.add_child(HSeparator.new())

	if dev is Computer and not (dev is Server):
		_section_header("HARDWARE")
		var comp = dev as Computer
		var hw = GridContainer.new()
		hw.columns = 2
		hw.add_theme_constant_override("h_separation", 12)
		hw.add_theme_constant_override("v_separation", 6)
		_content.add_child(hw)
		hw.add_child(_field_label("CPU cores:"))
		hw.add_child(_field_label(str(comp.cpu_cores)))
		hw.add_child(_field_label("RAM:"))
		hw.add_child(_field_label("%.0f MB" % comp.ram_mb))
		hw.add_child(_field_label("Storage:"))
		hw.add_child(_field_label("%d MB" % comp.storage_mb))
		_content.add_child(HSeparator.new())

	if dev is RouterDevice:
		_section_header("ROUTER")
		var router = dev as RouterDevice
		var chk = CheckButton.new()
		chk.text = "DHCP Server"
		chk.button_pressed = router.dhcp_enabled
		chk.toggled.connect(func(p):
			router.dhcp_enabled = p
		)
		_content.add_child(chk)

		var btn_routes = Button.new()
		btn_routes.text = " Regenerate Connected Routes "
		btn_routes.pressed.connect(func():
			router.auto_generate_routes()
		)
		_content.add_child(btn_routes)

		var btn_static = Button.new()
		btn_static.text = " Manage Static Routes… "
		btn_static.pressed.connect(func():
			var tree = Engine.get_main_loop()
			var dlg_class = load("res://scenes/dialogs/routes_dialog.gd")
			if dlg_class:
				var win = Window.new()
				win.set_script(dlg_class)
				tree.root.add_child(win)
				if win.has_method("setup"): win.setup(_device_id)
				win.popup_centered()
		)
		_content.add_child(btn_static)

		var routes = router.routing_table.get_all_routes() if router.routing_table else []
		if routes.size() > 0:
			var rl = Label.new()
			rl.text = "Routes (%d):" % routes.size()
			rl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
			_content.add_child(rl)
			for r in routes:
				var gw = r.gateway if r.gateway != "" else "(direct)"
				_content.add_child(_field_label("  %s/%d via %s [%s]" % [r.network, r.cidr, gw, r.interface_name]))

		var nat_chk = CheckButton.new()
		nat_chk.text = "NAT (masquerade private clients out %s)" % router.wan_interface
		nat_chk.button_pressed = router.nat_enabled
		nat_chk.toggled.connect(func(p):
			router.nat_enabled = p
			if EventBus: EventBus.device_updated.emit(router.id)
		)
		_content.add_child(nat_chk)

		var wan_row = HBoxContainer.new()
		wan_row.add_theme_constant_override("separation", 6)
		var wan_lbl = Label.new()
		wan_lbl.text = "WAN interface:"
		wan_row.add_child(wan_lbl)
		var wan_opt = OptionButton.new()
		for key in router.network_interfaces:
			wan_opt.add_item(key)
			if key == router.wan_interface:
				wan_opt.select(wan_opt.item_count - 1)
		wan_opt.item_selected.connect(func(idx):
			router.wan_interface = wan_opt.get_item_text(idx)
		)
		wan_row.add_child(wan_opt)
		_content.add_child(wan_row)

		if router.nat_table.size() > 0:
			var nl = Label.new()
			nl.text = "NAT translations (%d):" % router.nat_table.size()
			nl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
			_content.add_child(nl)
			for internal_ip in router.nat_table:
				var entry = router.nat_table[internal_ip]
				_content.add_child(_field_label("  %s -> %s  (%d pkts)" % [internal_ip, entry.external_ip, int(entry.hits)]))
			var nat_clear_btn = Button.new()
			nat_clear_btn.text = " Clear NAT table "
			nat_clear_btn.pressed.connect(func():
				router.nat_clear()
				_rebuild()
			)
			_content.add_child(nat_clear_btn)
		_content.add_child(HSeparator.new())

	if dev is FirewallDevice:
		_section_header("FIREWALL RULES (%d)" % dev.rules.size())
		var idx = 0
		for rule in dev.rules:
			var row = HBoxContainer.new()
			var rl = Label.new()
			rl.text = "%d. %s %s %s→%s%s" % [idx, str(rule.action).to_upper(), rule.protocol, rule.src_ip, rule.dst_ip, ("" if int(rule.dst_port) == -1 else ":" + str(rule.dst_port))]
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rl)
			if idx > 0:
				var rm = Button.new()
				rm.text = "✕"
				rm.custom_minimum_size = Vector2(26, 24)
				var r_idx = idx
				rm.pressed.connect(func():
					dev.remove_rule(r_idx)
					_rebuild()
				)
				row.add_child(rm)
			_content.add_child(row)
			idx += 1

		var add_row = HBoxContainer.new()
		add_row.add_theme_constant_override("separation", 6)
		var proto = OptionButton.new()
		for p in ["any", "tcp", "udp", "icmp"]:
			proto.add_item(p)
		var port = LineEdit.new()
		port.placeholder_text = "port"
		port.custom_minimum_size.x = 60
		var add_btn = Button.new()
		add_btn.text = "Deny port"
		add_btn.pressed.connect(func():
			var port_txt = port.text.strip_edges()
			dev.add_rule("deny", proto.get_item_text(proto.selected), "any", "any", int(port_txt) if port_txt.is_valid_int() else -1, 100)
			_rebuild()
		)
		add_row.add_child(proto)
		add_row.add_child(port)
		add_row.add_child(add_btn)
		_content.add_child(add_row)
		_content.add_child(HSeparator.new())

	if dev is StorageDevice:
		_section_header("STORAGE")
		var sg = GridContainer.new()
		sg.columns = 2
		sg.add_theme_constant_override("h_separation", 12)
		sg.add_theme_constant_override("v_separation", 6)
		_content.add_child(sg)
		sg.add_child(_field_label("Capacity:"))
		sg.add_child(_field_label("%d GB" % (dev.total_capacity_mb / 1024)))
		sg.add_child(_field_label("Used:"))
		sg_child_usage(sg, dev)
		sg.add_child(_field_label("Shares:"))
		sg.add_child(_field_label(str(dev.shares.size())))

		var btn_shares = Button.new()
		btn_shares.text = " Manage Shares… "
		btn_shares.pressed.connect(func():
			var tree = Engine.get_main_loop()
			var dlg_class = load("res://scenes/dialogs/shares_dialog.gd")
			if dlg_class:
				var win = Window.new()
				win.set_script(dlg_class)
				tree.root.add_child(win)
				if win.has_method("setup"): win.setup(_device_id)
				win.popup_centered()
		)
		_content.add_child(btn_shares)
		_content.add_child(HSeparator.new())

	if "services" in dev and dev.services.size() > 0:
		_section_header("SERVICES")
		for s in dev.services:
			var srow = HBoxContainer.new()
			var sname = Label.new()
			sname.text = "%s :%d" % [s.service_name.to_upper(), s.port]
			sname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			srow.add_child(sname)
			var stog = Button.new()
			stog.text = "Stop" if s.is_running else "Start"
			stog.pressed.connect(func():
				if s.is_running: s.stop()
				else: s.start()
				_rebuild()
			)
			srow.add_child(stog)
			_content.add_child(srow)
		_content.add_child(HSeparator.new())

	if dev is SwitchDevice:
		_section_header("VLANs")
		var vlan_grid = GridContainer.new()
		vlan_grid.columns = 4
		vlan_grid.add_theme_constant_override("h_separation", 8)
		vlan_grid.add_theme_constant_override("v_separation", 4)
		vlan_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content.add_child(vlan_grid)
		var hdr_font_color = Color(0.55, 0.65, 0.8)
		for h in ["Port", "VLAN", "Trunk", ""]:
			var hl = Label.new()
			hl.text = h
			hl.add_theme_color_override("font_color", hdr_font_color)
			vlan_grid.add_child(hl)
		var sw = dev as SwitchDevice
		for port_name in sw.network_interfaces.keys():
			var plbl = Label.new()
			plbl.text = port_name
			plbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
			vlan_grid.add_child(plbl)
			var vlan_spin = SpinBox.new()
			vlan_spin.min_value = 1
			vlan_spin.max_value = 4094
			vlan_spin.value = sw.get_port_vlan(port_name)
			vlan_spin.custom_minimum_size.x = 64
			vlan_spin.value_changed.connect(func(v):
				sw.set_port_vlan(port_name, int(v))
				if EventBus: EventBus.device_updated.emit(sw.id)
			)
			vlan_grid.add_child(vlan_spin)
			var trunk_chk = CheckBox.new()
			trunk_chk.button_pressed = sw.is_trunk(port_name)
			trunk_chk.toggled.connect(func(p):
				sw.set_trunk(port_name, p)
			)
			vlan_grid.add_child(trunk_chk)
			vlan_grid.add_child(Control.new())
		_content.add_child(HSeparator.new())

	_section_header("NETWORK INTERFACES")
	for iface in dev.network_interfaces.values():
		var if_box = VBoxContainer.new()
		if_box.add_theme_constant_override("separation", 2)

		var iname = Label.new()
		iname.text = "%s  %s" % [iface.iface_name, "[linked]" if iface.is_linked else "[free]"]
		iname.add_theme_font_size_override("font_size", 12)
		if_box.add_child(iname)

		var ip_str = iface.ipv4_address if iface.ipv4_address != "" else "(none)"
		var mask_str = "/" + str(iface.get_cidr()) if iface.get_cidr() > 0 else ""
		var ipl = Label.new()
		ipl.text = "  %s%s  gw %s" % [ip_str, mask_str, iface.gateway if iface.gateway != "" else "—"]
		ipl.add_theme_font_size_override("font_size", 11)
		ipl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
		if_box.add_child(ipl)

		var mac_lbl = Label.new()
		mac_lbl.text = "  MAC " + iface.mac_address
		mac_lbl.add_theme_font_size_override("font_size", 10)
		mac_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		if_box.add_child(mac_lbl)

		var if_name = iface.iface_name
		var btn_cfg = Button.new()
		btn_cfg.text = "Configure IP"
		btn_cfg.pressed.connect(func(): _open_ip_config(if_name))
		if_box.add_child(btn_cfg)

		_content.add_child(if_box)

	_content.add_child(HSeparator.new())

	var pwr = Button.new()
	pwr.text = " Power Off " if dev.is_powered_on else " Power On "
	pwr.pressed.connect(func():
		if dev.is_powered_on: dev.power_off()
		else: dev.power_on()
		if EventBus: EventBus.device_updated.emit(dev.id)
		_rebuild()
	)
	_content.add_child(pwr)

func sg_child_usage(sg: GridContainer, dev) -> void:
	var usage = Label.new()
	usage.text = "%d MB (%.1f%%)" % [dev.used_mb, dev.get_usage_percent()]
	sg.add_child(usage)

func _section_header(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8))
	_content.add_child(lbl)

func _field_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	return l

func _on_apply_name() -> void:
	var dev = _get_device()
	if not dev:
		return
	var new_name = _name_input.text.strip_edges()
	if new_name == "" or new_name == dev.display_name:
		return
	var cmd_hist = load("res://commands/command_history.gd")
	if ProjectMgr and cmd_hist and cmd_hist.RenameDeviceCommand:
		ProjectMgr.execute_command(cmd_hist.RenameDeviceCommand.new(dev.id, dev.display_name, new_name))
	else:
		dev.display_name = new_name
	if EventBus:
		EventBus.device_updated.emit(dev.id)

func _open_ip_config(iface_name: String) -> void:
	var dev = _get_device()
	if not dev:
		return
	var tree = Engine.get_main_loop()
	var cfg_class = load("res://scenes/dialogs/ip_config_dialog.gd")
	if cfg_class:
		var win = Window.new()
		win.set_script(cfg_class)
		tree.root.add_child(win)
		var iface = dev.get_interface(iface_name)
		if win.has_method("setup") and iface:
			win.setup(_device_id, iface_name, iface.ipv4_address, iface.subnet_mask, iface.gateway)
		win.popup_centered()
