extends Window

var _table: ItemList
var _status_lbl: Label
var _timer: Timer

func _ready() -> void:
	title = "Packet Capture"
	size = Vector2i(720, 480)
	min_size = Vector2i(560, 360)
	close_requested.connect(queue_free)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(btn_row)

	var btn_start = Button.new()
	btn_start.text = " Start Capture "
	btn_start.pressed.connect(func():
		PacketCapture.start_capture()
		_refresh_status()
	)
	btn_row.add_child(btn_start)

	var btn_stop = Button.new()
	btn_stop.text = " Stop "
	btn_stop.pressed.connect(func():
		PacketCapture.stop_capture()
		_refresh_status()
	)
	btn_row.add_child(btn_stop)

	var btn_clear = Button.new()
	btn_clear.text = " Clear "
	btn_clear.pressed.connect(func():
		PacketCapture.clear()
		_refresh()
	)
	btn_row.add_child(btn_clear)

	_status_lbl = Label.new()
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	btn_row.add_child(_status_lbl)

	_table = ItemList.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_table.add_theme_font_size_override("font_size", 12)
	vb.add_child(_table)

	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.autostart = true
	_timer.timeout.connect(_refresh)
	add_child(_timer)

	_refresh_status()
	_refresh()

func _refresh_status() -> void:
	_status_lbl.text = "CAPTURING (%d packets)" % PacketCapture.packets.size() if PacketCapture.is_capturing else "Idle (%d packets)" % PacketCapture.packets.size()

func _refresh() -> void:
	_refresh_status()
	_table.clear()
	for p in PacketCapture.packets:
		var line = "[%7.2fs]  %-15s → %-15s  %-5s  %4dB  %s" % [p.time, p.src, p.dst, p.protocol, p.size, p.info]
		_table.add_item(line)
	if _table.item_count > 0:
		_table.select(_table.item_count - 1)
		_table.ensure_current_is_visible()
