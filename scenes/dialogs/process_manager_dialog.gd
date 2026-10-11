extends Window

var _device_id: String = ""
var _list: ItemList
var _info_lbl: Label

func setup(device_id: String) -> void:
	_device_id = device_id
	if _list:
		_refresh()

func _get_os():
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dev = engine.get_device(_device_id) if engine else null
	return dev.operating_system if dev and "operating_system" in dev else null

func _ready() -> void:
	title = "Process Manager"
	size = Vector2i(520, 440)
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

	_info_lbl = Label.new()
	_info_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vb.add_child(_info_lbl)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_font_size_override("font_size", 12)
	vb.add_child(_list)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(btn_row)

	var kill_btn = Button.new()
	kill_btn.text = " Kill Selected "
	kill_btn.pressed.connect(_on_kill)
	btn_row.add_child(kill_btn)

	var spawn_btn = Button.new()
	spawn_btn.text = " Spawn Test Process "
	spawn_btn.pressed.connect(func():
		var os = _get_os()
		if os:
			os.add_process("user_task", randf() * 5.0, randf() * 100.0)
			_refresh()
	)
	btn_row.add_child(spawn_btn)

	var refresh_btn = Button.new()
	refresh_btn.text = " Refresh "
	refresh_btn.pressed.connect(_refresh)
	btn_row.add_child(refresh_btn)

	if _device_id != "":
		_refresh()

func _refresh() -> void:
	var os = _get_os()
	_list.clear()
	if not os:
		_info_lbl.text = "No OS on this device."
		return
	var procs = os.get_processes()
	var total_cpu = 0.0
	var total_ram = 0.0
	for p in procs:
		total_cpu += p.cpu_percent
		total_ram += p.ram_mb
		_list.add_item("PID %-6d %-20s CPU %.1f%%  RAM %.1fMB  [%s]" % [p.pid, p.process_name, p.cpu_percent, p.ram_mb, p.owner])
		_list.set_item_metadata(_list.item_count - 1, p.pid)
	_info_lbl.text = "%s - %d processes  |  Total CPU %.1f%%  Total RAM %.1f MB" % [os.hostname, procs.size(), total_cpu, total_ram]

func _on_kill() -> void:
	var os = _get_os()
	if not os:
		return
	var selected = _list.get_selected_items()
	for idx in selected:
		var pid = _list.get_item_metadata(idx)
		os.remove_process(int(pid))
	_refresh()
