extends Window

var _link_id: String = ""
var _bw_spin: SpinBox
var _lat_spin: SpinBox
var _loss_spin: SpinBox
var _enable_chk: CheckButton
var _info_lbl: Label
var _util_lbl: Label
var _util_timer: Timer

var _content: VBoxContainer

func setup(link_id: String) -> void:
	_link_id = link_id
	if _content:
		_build_ui()

func _get_link():
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	if not engine:
		return null
	for conn in engine.connections:
		if conn.id == _link_id:
			return conn
	return null

func _ready() -> void:
	title = "Link Configuration"
	size = Vector2i(360, 300)
	close_requested.connect(queue_free)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	m.add_child(_content)

	if _link_id != "":
		_build_ui()

func _build_ui() -> void:
	for c in _content.get_children():
		c.queue_free()

	var link = _get_link()
	if not link:
		var lbl = Label.new()
		lbl.text = "Link not found."
		_content.add_child(lbl)
		return

	_info_lbl = Label.new()
	_info_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	_content.add_child(_info_lbl)
	_refresh_info(link)

	_util_lbl = Label.new()
	_util_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.6))
	_content.add_child(_util_lbl)

	if not _util_timer:
		_util_timer = Timer.new()
		_util_timer.wait_time = 0.5
		_util_timer.autostart = true
		_util_timer.timeout.connect(_refresh_util)
		add_child(_util_timer)
	_refresh_util()

	_enable_chk = CheckButton.new()
	_enable_chk.text = "Link enabled"
	_enable_chk.button_pressed = link.is_enabled
	_enable_chk.toggled.connect(func(p):
		link.is_enabled = p
	)
	_content.add_child(_enable_chk)

	var bw_row = HBoxContainer.new()
	bw_row.add_theme_constant_override("separation", 8)
	var bw_lbl = Label.new()
	bw_lbl.text = "Bandwidth (Mbps):"
	bw_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bw_row.add_child(bw_lbl)
	_bw_spin = SpinBox.new()
	_bw_spin.min_value = 1
	_bw_spin.max_value = 100000
	_bw_spin.step = 10
	_bw_spin.value = link.bandwidth_mbps
	bw_row.add_child(_bw_spin)
	_content.add_child(bw_row)

	var lat_row = HBoxContainer.new()
	lat_row.add_theme_constant_override("separation", 8)
	var lat_lbl = Label.new()
	lat_lbl.text = "Latency (ms):"
	lat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lat_row.add_child(lat_lbl)
	_lat_spin = SpinBox.new()
	_lat_spin.min_value = 0.1
	_lat_spin.max_value = 5000.0
	_lat_spin.step = 0.1
	_lat_spin.value = link.latency_ms
	lat_row.add_child(_lat_spin)
	_content.add_child(lat_row)

	var loss_row = HBoxContainer.new()
	loss_row.add_theme_constant_override("separation", 8)
	var loss_lbl = Label.new()
	loss_lbl.text = "Packet loss (%):"
	loss_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loss_row.add_child(loss_lbl)
	_loss_spin = SpinBox.new()
	_loss_spin.min_value = 0.0
	_loss_spin.max_value = 100.0
	_loss_spin.step = 0.5
	_loss_spin.value = link.packet_loss_percent
	loss_row.add_child(_loss_spin)
	_content.add_child(loss_row)

	var apply_btn = Button.new()
	apply_btn.text = " Apply "
	apply_btn.pressed.connect(_on_apply)
	_content.add_child(apply_btn)

func _refresh_info(link) -> void:
	var engine = Engine.get_main_loop().root.get_node_or_null("SimEngine")
	if not engine:
		return
	var src = engine.get_device(link.source_device_id)
	var dst = engine.get_device(link.dest_device_id)
	_info_lbl.text = "%s:%s  <->  %s:%s\nLink ID: %s" % [
		src.display_name if src else "?", link.source_interface_name,
		dst.display_name if dst else "?", link.dest_interface_name,
		link.id
	]

func _refresh_util() -> void:
	var link = _get_link()
	if not link or not _util_lbl:
		return
	var util = link.get_utilization()
	var eff_lat = link.get_congested_latency()
	_util_lbl.text = "Utilization: %.1f%%  |  Effective latency: %.1f ms  |  Total transferred: %d KB" % [
		util * 100.0, eff_lat, link.bytes_transferred / 1024
	]

func _on_apply() -> void:
	var link = _get_link()
	if not link:
		return
	link.is_enabled = _enable_chk.button_pressed
	link.bandwidth_mbps = int(_bw_spin.value)
	link.latency_ms = _lat_spin.value
	link.packet_loss_percent = _loss_spin.value
	var tree = Engine.get_main_loop()
	if tree and tree.root and tree.root.has_node("EventBus"):
		var eb = tree.root.get_node("EventBus")
		if eb.has_signal("connection_updated"):
			eb.connection_updated.emit(link)
	queue_free()
