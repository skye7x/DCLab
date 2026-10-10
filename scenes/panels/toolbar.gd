extends HBoxContainer

var play_btn: Button
var pause_btn: Button
var stop_btn: Button
var speed_selector: OptionButton
var time_label: Label
var device_count_label: Label
var link_count_label: Label
var zoom_label: Label
var grid_btn: Button
var snap_btn: Button

var _workspace_ref = null

func _ready() -> void:
	custom_minimum_size.y = 38
	add_theme_constant_override("separation", 6)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 5)
	m.add_theme_constant_override("margin_bottom", 5)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	m.add_child(hbox)
	add_child(m)

	play_btn = _make_btn("▶", "Start simulation")
	play_btn.pressed.connect(func(): SimEngine.start_simulation())
	hbox.add_child(play_btn)

	pause_btn = _make_btn("⏸", "Pause simulation")
	pause_btn.pressed.connect(func(): SimEngine.pause_simulation())
	hbox.add_child(pause_btn)

	stop_btn = _make_btn("⏹", "Stop simulation")
	stop_btn.pressed.connect(func(): SimEngine.stop_simulation())
	hbox.add_child(stop_btn)

	hbox.add_child(VSeparator.new())

	speed_selector = OptionButton.new()
	speed_selector.add_item("0.5x")
	speed_selector.add_item("1x")
	speed_selector.add_item("2x")
	speed_selector.add_item("5x")
	speed_selector.add_item("10x")
	speed_selector.select(1)
	speed_selector.item_selected.connect(_on_speed_selected)
	speed_selector.tooltip_text = "Simulation speed"
	hbox.add_child(speed_selector)

	hbox.add_child(VSeparator.new())

	time_label = Label.new()
	time_label.text = "00:00:00"
	time_label.tooltip_text = "Simulation time"
	hbox.add_child(time_label)

	hbox.add_child(VSeparator.new())

	device_count_label = Label.new()
	device_count_label.text = "Devices: 0"
	hbox.add_child(device_count_label)

	link_count_label = Label.new()
	link_count_label.text = "Links: 0"
	hbox.add_child(link_count_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# --- View controls ---
	var zoom_out_btn = _make_btn("−", "Zoom out (−)")
	zoom_out_btn.pressed.connect(func(): _cam_op("zoom_out"))
	hbox.add_child(zoom_out_btn)

	zoom_label = Label.new()
	zoom_label.text = "100%"
	zoom_label.custom_minimum_size.x = 44
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(zoom_label)

	var zoom_in_btn = _make_btn("+", "Zoom in (+)")
	zoom_in_btn.pressed.connect(func(): _cam_op("zoom_in"))
	hbox.add_child(zoom_in_btn)

	var fit_btn = _make_btn("⤢", "Zoom to fit (F)")
	fit_btn.pressed.connect(func(): _ws_op("zoom_to_fit"))
	hbox.add_child(fit_btn)

	var home_btn = _make_btn("⌂", "Reset view (0)")
	home_btn.pressed.connect(func(): _cam_op("reset_view"))
	hbox.add_child(home_btn)

	hbox.add_child(VSeparator.new())

	grid_btn = _make_btn("▦", "Toggle grid (G)")
	grid_btn.toggle_mode = true
	grid_btn.button_pressed = true
	grid_btn.toggled.connect(_on_grid_toggled)
	hbox.add_child(grid_btn)

	snap_btn = _make_btn("🧲", "Toggle snap to grid (N)")
	snap_btn.toggle_mode = true
	snap_btn.button_pressed = true
	snap_btn.toggled.connect(_on_snap_toggled)
	hbox.add_child(snap_btn)

func _make_btn(text: String, tip: String) -> Button:
	var b = Button.new()
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(30, 26)
	return b

func _cam_op(op: String) -> void:
	if _workspace_ref and "_camera" in _workspace_ref and _workspace_ref._camera:
		_workspace_ref._camera.call(op)

func _ws_op(op: String) -> void:
	if _workspace_ref and _workspace_ref.has_method(op):
		_workspace_ref.call(op)

func _on_grid_toggled(pressed: bool) -> void:
	if _workspace_ref and _workspace_ref.has_method("toggle_grid"):
		_workspace_ref.show_grid = pressed
		_workspace_ref.toggle_grid()

func _on_snap_toggled(pressed: bool) -> void:
	if _workspace_ref and "snap_to_grid" in _workspace_ref:
		_workspace_ref.snap_to_grid = pressed

func _on_speed_selected(idx: int) -> void:
	var speeds = [0.5, 1.0, 2.0, 5.0, 10.0]
	SimEngine.set_speed(speeds[idx])

func sync_view_buttons() -> void:
	if _workspace_ref and "show_grid" in _workspace_ref:
		grid_btn.set_pressed_no_signal(_workspace_ref.show_grid)
	if _workspace_ref and "snap_to_grid" in _workspace_ref:
		snap_btn.set_pressed_no_signal(_workspace_ref.snap_to_grid)

func update_status() -> void:
	if SimTime and SimTime.has_method("get_formatted_time"):
		time_label.text = SimTime.get_formatted_time()
	if SimEngine:
		if SimEngine.has_method("get_all_devices"):
			device_count_label.text = "Devices: " + str(SimEngine.get_all_devices().size())
		elif SimEngine.has_method("get_device_count"):
			device_count_label.text = "Devices: " + str(SimEngine.get_device_count())
		if "connections" in SimEngine:
			link_count_label.text = "Links: " + str(SimEngine.connections.size())
	if zoom_label and _workspace_ref and _workspace_ref.has_method("get_zoom"):
		zoom_label.text = "%d%%" % int(round(_workspace_ref.get_zoom() * 100.0))
