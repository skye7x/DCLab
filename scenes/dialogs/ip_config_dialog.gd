extends Window

signal config_applied(device_id: String, iface_name: String, ip: String, mask: String, gateway: String)

var _device_id: String
var _iface_name: String
var _ip_input: LineEdit
var _mask_input: LineEdit
var _gateway_input: LineEdit
var _status_label: Label
var _init_ip: String = ""
var _init_mask: String = ""
var _init_gw: String = ""

func setup(device_id: String, iface_name: String, current_ip: String = "", current_mask: String = "", current_gw: String = "") -> void:
	_device_id = device_id
	_iface_name = iface_name
	_init_ip = current_ip
	_init_mask = current_mask
	_init_gw = current_gw
	
	if _ip_input: _ip_input.text = current_ip
	if _mask_input: _mask_input.text = current_mask
	if _gateway_input: _gateway_input.text = current_gw

func _ready() -> void:
	title = "Configure Network Interface"
	size = Vector2i(420, 320)
	min_size = Vector2i(380, 280)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	
	var vbox = VBoxContainer.new()
	m.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "Interface: " + _iface_name
	lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)
	
	var l1 = Label.new()
	l1.text = "IPv4 Address:"
	grid.add_child(l1)
	
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "192.168.10.10"
	_ip_input.text = _init_ip
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_ip_input)
	
	var l2 = Label.new()
	l2.text = "Subnet Mask:"
	grid.add_child(l2)
	
	_mask_input = LineEdit.new()
	_mask_input.placeholder_text = "255.255.255.0"
	_mask_input.text = _init_mask if _init_mask != "" else "255.255.255.0"
	_mask_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_mask_input)
	
	var l3 = Label.new()
	l3.text = "Gateway:"
	grid.add_child(l3)
	
	_gateway_input = LineEdit.new()
	_gateway_input.placeholder_text = "192.168.10.1"
	_gateway_input.text = _init_gw
	_gateway_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_gateway_input)
	
	vbox.add_child(HSeparator.new())
	
	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	vbox.add_child(_status_label)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(hbox)
	
	var btn_apply = Button.new()
	btn_apply.text = " Apply "
	btn_apply.pressed.connect(_on_apply)
	hbox.add_child(btn_apply)
	
	var btn_cancel = Button.new()
	btn_cancel.text = " Cancel "
	btn_cancel.pressed.connect(queue_free)
	hbox.add_child(btn_cancel)
	
	close_requested.connect(queue_free)

func _on_apply() -> void:
	var ip = _ip_input.text.strip_edges()
	var mask = _mask_input.text.strip_edges()
	var gw = _gateway_input.text.strip_edges()
	
	if ip != "" and not IPv4Address.is_valid(ip):
		_status_label.text = "Invalid IPv4 address format."
		return
	if mask != "" and not IPv4Address.is_valid(mask):
		_status_label.text = "Invalid Subnet Mask format."
		return
	if gw != "" and not IPv4Address.is_valid(gw):
		_status_label.text = "Invalid Gateway format."
		return
	
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(_device_id) if engine else null
	
	if device and device.has_method("get_interface"):
		var iface = device.get_interface(_iface_name)
		if iface:
			iface.ipv4_address = ip
			iface.subnet_mask = mask
			iface.gateway = gw
			if device is RouterDevice:
				device.auto_generate_routes()
			var tree2 = Engine.get_main_loop()
			if tree2 and tree2.root and tree2.root.has_node("EventBus"):
				tree2.root.get_node("EventBus").device_updated.emit(_device_id)
			
	config_applied.emit(_device_id, _iface_name, ip, mask, gw)
	queue_free()
