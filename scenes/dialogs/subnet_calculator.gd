extends Window

var _ip_input: LineEdit
var _cidr_input: SpinBox
var _result: TextEdit

func _ready() -> void:
	title = "Subnet Calculator"
	size = Vector2i(380, 480)
	min_size = Vector2i(340, 400)
	close_requested.connect(queue_free)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)

	var lbl1 = Label.new()
	lbl1.text = "IP:"
	row.add_child(lbl1)
	_ip_input = LineEdit.new()
	_ip_input.text = "192.168.1.100"
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_ip_input)

	var lbl2 = Label.new()
	lbl2.text = "CIDR:"
	row.add_child(lbl2)
	_cidr_input = SpinBox.new()
	_cidr_input.min_value = 0
	_cidr_input.max_value = 32
	_cidr_input.value = 24
	_cidr_input.custom_minimum_size.x = 64
	row.add_child(_cidr_input)

	var btn = Button.new()
	btn.text = " Calculate "
	btn.pressed.connect(_calculate)
	vb.add_child(btn)

	_ip_input.text_submitted.connect(func(_t): _calculate())
	_cidr_input.value_changed.connect(func(_v): _calculate())

	_result = TextEdit.new()
	_result.editable = false
	_result.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_result.add_theme_font_size_override("font_size", 13)
	vb.add_child(_result)

	_calculate()

func _calculate() -> void:
	var ip = _ip_input.text.strip_edges()
	if not IPv4Address.is_valid(ip):
		_result.text = "Invalid IP address: " + ip
		return
	var cidr = int(_cidr_input.value)
	var mask = IPv4Address.cidr_to_mask(cidr)
	var network = IPv4Address.get_network(ip, mask)
	var broadcast = IPv4Address.get_broadcast(ip, mask)
	var net_int = IPv4Address.to_int(network)
	var bcast_int = IPv4Address.to_int(broadcast)
	var total = 1 << (32 - cidr)
	var usable = max(0, total - 2) if cidr < 31 else total
	var first_host = IPv4Address.from_int(net_int + 1) if cidr < 31 else network
	var last_host = IPv4Address.from_int(bcast_int - 1) if cidr < 31 else broadcast
	var wildcard_parts = mask.split(".")
	var wildcard = []
	for p in wildcard_parts:
		wildcard.append(str(255 - p.to_int()))
	var cls = ""
	var ip_first_octet = ip.split(".")[0].to_int()
	if ip_first_octet < 128: cls = "A"
	elif ip_first_octet < 192: cls = "B"
	elif ip_first_octet < 224: cls = "C"
	elif ip_first_octet < 240: cls = "D (multicast)"
	else: cls = "E (reserved)"
	var private_net = false
	if ip.begins_with("10.") or ip.begins_with("192.168.") or (ip.begins_with("172.") and ip.split(".")[1].to_int() >= 16 and ip.split(".")[1].to_int() <= 31):
		private_net = true

	var out = ""
	out += "Address:        %s\n" % ip
	out += "Netmask:        %s  (/%d)\n" % [mask, cidr]
	out += "Wildcard:       %s\n" % ".".join(wildcard)
	out += "Network:        %s/%d\n" % [network, cidr]
	out += "Broadcast:      %s\n" % broadcast
	out += "First host:     %s\n" % first_host
	out += "Last host:      %s\n" % last_host
	out += "Total hosts:    %d\n" % total
	out += "Usable hosts:   %d\n" % usable
	out += "Class:          %s\n" % cls
	out += "Scope:          %s\n" % ("Private (RFC1918)" if private_net else "Public")
	_result.text = out
