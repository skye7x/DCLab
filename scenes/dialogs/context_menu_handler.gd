extends Node

var _popup: PopupMenu
var _target_device_id: String = ""
var _workspace_ref = null

func _ready() -> void:
	_popup = PopupMenu.new()
	add_child(_popup)
	_popup.id_pressed.connect(_on_menu_item_selected)

func show_device_menu(device_id: String, screen_pos: Vector2) -> void:
	_target_device_id = device_id
	_popup.clear()

	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(device_id) if engine else null
	var dtype = device.device_type if device else ""

	_popup.add_item("Configure…", 7)
	if device and ("operating_system" in device and device.operating_system or dtype == "storage"):
		_popup.add_item("Open Terminal", 0)
	_popup.add_item("Configure IP", 1)
	if device and device.network_interfaces.size() > 0:
		_popup.add_item("Connect", 2)
	if dtype == "storage" and device and "shares" in device:
		_popup.add_separator("Storage")
		_popup.add_item("Shares…", 8)
		_popup.add_item("Format…", 9)
	if device and "services" in device and device.services.size() > 0:
		_popup.add_separator("Services")
		for s in device.services:
			var s_id = 100 + device.services.find(s)
			var state = "Stop" if s.is_running else "Start"
			_popup.add_item("%s %s" % [state, s.service_name], s_id)
	_popup.add_separator()
	_popup.add_item("Rename", 3)
	_popup.add_item("Duplicate", 4)
	_popup.add_separator()

	if device and "is_powered_on" in device and device.is_powered_on:
		_popup.add_item("Power Off", 5)
	else:
		_popup.add_item("Power On", 5)

	_popup.add_separator()
	_popup.add_item("Delete", 6)

	_popup.position = Vector2i(int(screen_pos.x), int(screen_pos.y))
	_popup.popup()

func show_workspace_menu(screen_pos: Vector2) -> void:
	_target_device_id = ""
	_popup.clear()
	_popup.add_item("Select All", 20)
	_popup.add_item("Zoom to Fit", 21)
	_popup.add_item("Toggle Grid", 22)
	_popup.add_item("Toggle Snap to Grid", 23)
	_popup.position = Vector2i(int(screen_pos.x), int(screen_pos.y))
	_popup.popup()

func _on_menu_item_selected(id: int) -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null

	if id >= 100:
		var dev = engine.get_device(_target_device_id) if engine else null
		if dev and "services" in dev:
			var s = dev.services[id - 100]
			if s.is_running: s.stop()
			else: s.start()
		return

	match id:
		0: # Open Terminal
			_open_terminal(_target_device_id)
		1: # Configure IP
			var cfg_class = load("res://scenes/dialogs/ip_config_dialog.gd")
			if cfg_class:
				var win = Window.new()
				win.set_script(cfg_class)
				tree.root.add_child(win)
				var dev = engine.get_device(_target_device_id) if engine else null
				if dev and "network_interfaces" in dev and dev.network_interfaces.size() > 0:
					var iface = dev.network_interfaces.values()[0]
					if win.has_method("setup"): win.setup(_target_device_id, iface.iface_name, iface.ipv4_address, iface.subnet_mask, iface.gateway)
				win.popup_centered()
		2: # Connect
			if _workspace_ref and _workspace_ref.has_method("start_connection"):
				var dev = engine.get_device(_target_device_id) if engine else null
				if dev and "network_interfaces" in dev and dev.network_interfaces.size() > 0:
					var iface = dev.network_interfaces.values()[0]
					_workspace_ref.start_connection(_target_device_id, iface.iface_name)
		3: # Rename
			var dev = engine.get_device(_target_device_id) if engine else null
			if dev:
				var dlg = ConfirmationDialog.new()
				dlg.title = "Rename Device"
				var input = LineEdit.new()
				input.text = dev.display_name
				input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				dlg.add_child(input)
				dlg.confirmed.connect(func():
					var new_name = input.text.strip_edges()
					if new_name != "":
						var old_name = dev.display_name
						var cmd_hist = load("res://commands/command_history.gd")
						if ProjectMgr and cmd_hist and cmd_hist.RenameDeviceCommand:
							ProjectMgr.execute_command(cmd_hist.RenameDeviceCommand.new(dev.id, old_name, new_name))
						else:
							dev.display_name = new_name
						if _workspace_ref and dev.id in _workspace_ref.device_nodes:
							_workspace_ref.device_nodes[dev.id].update_visual()
				)
				tree.root.add_child(dlg)
				dlg.popup_centered(Vector2i(300, 100))
		4: # Duplicate
			var dev = engine.get_device(_target_device_id) if engine else null
			if dev:
				var dev_dict = dev.to_dict()
				var new_id = engine.generate_id()
				dev_dict["id"] = new_id
				dev_dict["display_name"] = dev.display_name + " (Copy)"
				var pos = dev.position + Vector2(40, 40)
				dev_dict["position"] = {"x": pos.x, "y": pos.y}
				if dev_dict.has("network_interfaces"):
					for if_name in dev_dict["network_interfaces"]:
						dev_dict["network_interfaces"][if_name]["mac_address"] = IPv4Address.generate_mac()
						dev_dict["network_interfaces"][if_name]["is_linked"] = false
				var new_dev = ProjectSerializer._create_device_from_dict(dev_dict)
				if new_dev:
					new_dev.position = pos
					engine.add_device(new_dev)
		5: # Power
			var dev = engine.get_device(_target_device_id) if engine else null
			if dev:
				if dev.is_powered_on and dev.has_method("power_off"): dev.power_off()
				elif not dev.is_powered_on and dev.has_method("power_on"): dev.power_on()
		6: # Delete
			if _workspace_ref and _workspace_ref.has_method("delete_selected"):
				_workspace_ref.select_device(_target_device_id)
				_workspace_ref.delete_selected()
		7: # Configure…
			_open_config_dialog(_target_device_id)
		8: # Shares…
			_open_shares_dialog(_target_device_id)
		9: # Format…
			_open_format_dialog(_target_device_id)
		20: # Select All
			if _workspace_ref and _workspace_ref.has_method("select_all"):
				_workspace_ref.select_all()
		21: # Fit View
			if _workspace_ref and _workspace_ref.has_method("zoom_to_fit"):
				_workspace_ref.zoom_to_fit()
		22: # Toggle Grid
			if _workspace_ref and _workspace_ref.has_method("toggle_grid"):
				_workspace_ref.toggle_grid()
		23: # Toggle Snap
			if _workspace_ref and _workspace_ref.has_method("toggle_snap"):
				_workspace_ref.toggle_snap()

func _open_terminal(device_id: String) -> void:
	var tree = Engine.get_main_loop()
	var term_class = load("res://scenes/terminal/terminal_window.gd")
	if term_class:
		var win = Window.new()
		win.set_script(term_class)
		tree.root.add_child(win)
		if win.has_method("setup"): win.setup(device_id)
		win.popup_centered()

func _open_config_dialog(device_id: String) -> void:
	var tree = Engine.get_main_loop()
	var dlg_class = load("res://scenes/dialogs/device_config_dialog.gd")
	if dlg_class:
		var win = Window.new()
		win.set_script(dlg_class)
		tree.root.add_child(win)
		if win.has_method("setup"): win.setup(device_id)
		win.popup_centered()

func _open_shares_dialog(device_id: String) -> void:
	var tree = Engine.get_main_loop()
	var dlg_class = load("res://scenes/dialogs/shares_dialog.gd")
	if dlg_class:
		var win = Window.new()
		win.set_script(dlg_class)
		tree.root.add_child(win)
		if win.has_method("setup"): win.setup(device_id)
		win.popup_centered()

func _open_format_dialog(device_id: String) -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dev = engine.get_device(device_id) if engine else null
	if not dev or not ("total_capacity_mb" in dev):
		return
	var dlg = ConfirmationDialog.new()
	dlg.title = "Format Storage"
	dlg.dialog_text = "Wipe ALL data on %s?\nCapacity stays: %s" % [dev.display_name, "%.0f GB" % (dev.total_capacity_mb / 1024.0)]
	dlg.confirmed.connect(func():
		dev.used_mb = 0
		if "shares" in dev:
			dev.shares.clear()
		if EventBus:
			EventBus.device_updated.emit(dev.id)
	)
	tree.root.add_child(dlg)
	dlg.popup_centered()
