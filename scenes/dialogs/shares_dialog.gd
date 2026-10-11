extends Window

var _device_id: String = ""
var _list_box: VBoxContainer
var _status: Label

var _info_label: Label

func setup(device_id: String) -> void:
	_device_id = device_id
	if _list_box:
		_rebuild()

func _ready() -> void:
	title = "Manage Shares"
	size = Vector2i(460, 420)
	min_size = Vector2i(380, 300)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 12)
	m.add_theme_constant_override("margin_bottom", 12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	m.add_child(vbox)

	_info_label = Label.new()
	_info_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vbox.add_child(_info_label)

	vbox.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_box)

	vbox.add_child(HSeparator.new())

	var add_row = HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 6)
	vbox.add_child(add_row)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "share name"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(name_input)

	var size_input = LineEdit.new()
	size_input.placeholder_text = "MB"
	size_input.custom_minimum_size.x = 70
	add_row.add_child(size_input)

	var ro_chk = CheckBox.new()
	ro_chk.text = "RO"
	add_row.add_child(ro_chk)

	var add_btn = Button.new()
	add_btn.text = "Add"
	add_btn.pressed.connect(func():
		var sname = name_input.text.strip_edges()
		var size_txt = size_input.text.strip_edges()
		if sname == "" or not size_txt.is_valid_int():
			_status.text = "Enter a name and integer MB size."
			return
		var d = _get_device()
		if d:
			var err = d.add_share(sname, int(size_txt), ro_chk.button_pressed)
			_status.text = err if err != "" else "Share '%s' added." % sname
			if err == "":
				name_input.text = ""
				size_input.text = ""
				if EventBus: EventBus.device_updated.emit(d.id)
				_rebuild()
	)
	add_row.add_child(add_btn)

	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	vbox.add_child(_status)

	close_requested.connect(queue_free)
	if _device_id != "":
		_rebuild()

func _get_device():
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	return engine.get_device(_device_id) if engine else null

func _rebuild() -> void:
	for child in _list_box.get_children():
		child.queue_free()

	var dev = _get_device()
	if not dev:
		if _info_label:
			_info_label.text = "Device not found."
		return

	if _info_label and "total_capacity_mb" in dev:
		_info_label.text = "%s — %d GB total, %d MB used, %.1f%%" % [dev.display_name, dev.total_capacity_mb / 1024, dev.used_mb, dev.get_usage_percent()]

	if not ("shares" in dev):
		return

	if dev.shares.is_empty():
		var empty = Label.new()
		empty.text = "No shares."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_list_box.add_child(empty)
		return

	for s in dev.shares:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var lbl = Label.new()
		lbl.text = "%s  (%s, %d MB%s)" % [s.name, s.path, int(s.size_mb), ", read-only" if s.get("read_only", false) else ""]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var rm = Button.new()
		rm.text = "Remove"
		var sname = s.name
		rm.pressed.connect(func():
			var d = _get_device()
			if d:
				var err = d.remove_share(sname)
				_status.text = err if err != "" else "Share '%s' removed." % sname
				if err == "":
					if EventBus: EventBus.device_updated.emit(d.id)
					_rebuild()
		)
		row.add_child(rm)
		_list_box.add_child(row)
