extends Window

var _device_id: String = ""
var _content: VBoxContainer

func setup(device_id: String) -> void:
	_device_id = device_id

func _get_router():
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	return engine.get_device(_device_id) if engine else null

func _ready() -> void:
	title = "Static Routes"
	size = Vector2i(560, 480)
	min_size = Vector2i(480, 360)
	close_requested.connect(queue_free)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	scroll.add_child(_content)

	_rebuild()

func _rebuild() -> void:
	for child in _content.get_children():
		child.queue_free()

	var router = _get_router()
	if not router or not (router is RouterDevice):
		_content.add_child(_mk_label("Not a router or not found."))
		return

	_content.add_child(_mk_label("Static routes on %s:" % router.display_name))

	var routes = router.routing_table.get_all_routes() if router.routing_table else []
	var idx = 0
	for r in routes:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var gw = r.gateway if r.gateway != "" else "(direct)"
		var lbl = Label.new()
		lbl.text = "%d. %s/%d via %s dev %s metric %d" % [idx, r.network, r.cidr, gw, r.interface_name, r.metric]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		row.add_child(lbl)
		var rm = Button.new()
		rm.text = "✕"
		rm.custom_minimum_size = Vector2(28, 24)
		var r_idx = idx
		rm.pressed.connect(func():
			router.remove_route(r.network, r.cidr)
			_rebuild()
		)
		row.add_child(rm)
		_content.add_child(row)
		idx += 1

	if routes.is_empty():
		_content.add_child(_mk_label("  (no routes — connected routes are auto-generated on link up)"))

	_content.add_child(HSeparator.new())
	_content.add_child(_mk_label("Add static route:"))

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	_content.add_child(grid)

	var net_input = LineEdit.new()
	net_input.placeholder_text = "Network (e.g. 172.16.0.0)"
	net_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(_mk_label("Network:"))
	grid.add_child(net_input)

	var cidr_spin = SpinBox.new()
	cidr_spin.min_value = 0
	cidr_spin.max_value = 32
	cidr_spin.value = 16
	grid.add_child(_mk_label("CIDR:"))
	grid.add_child(cidr_spin)

	var gw_input = LineEdit.new()
	gw_input.placeholder_text = "Gateway (blank = direct)"
	grid.add_child(_mk_label("Gateway:"))
	grid.add_child(gw_input)

	var iface_opt = OptionButton.new()
	for key in router.network_interfaces:
		iface_opt.add_item(key)
	grid.add_child(_mk_label("Interface:"))
	grid.add_child(iface_opt)

	var metric_spin = SpinBox.new()
	metric_spin.min_value = 0
	metric_spin.max_value = 9999
	metric_spin.value = 100
	grid.add_child(_mk_label("Metric:"))
	grid.add_child(metric_spin)

	var add_btn = Button.new()
	add_btn.text = " Add Route "
	add_btn.pressed.connect(func():
		var net = net_input.text.strip_edges()
		if not IPv4Address.is_valid(net):
			_flash("Invalid network address")
			return
		var gw = gw_input.text.strip_edges()
		if gw != "" and not IPv4Address.is_valid(gw):
			_flash("Invalid gateway")
			return
		router.add_route(net, int(cidr_spin.value), iface_opt.get_item_text(iface_opt.selected), gw, int(metric_spin.value))
		if EventBus:
			EventBus.device_updated.emit(router.id)
		_rebuild()
	)
	_content.add_child(add_btn)

	var regen_btn = Button.new()
	regen_btn.text = " Regenerate Connected Routes (keeps static) "
	regen_btn.pressed.connect(func():
		# Only regenerate connected; static routes with a gateway survive
		router.auto_generate_routes()
		if EventBus:
			EventBus.device_updated.emit(router.id)
		_rebuild()
	)
	_content.add_child(regen_btn)

func _mk_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	return l

func _flash(msg: String) -> void:
	var lbl = _mk_label(msg)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	_content.add_child(lbl)
