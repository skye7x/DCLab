extends Window

var device_id: String
var _tabs: TabContainer
var _tab_script = null

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	title = "Terminal"
	size = Vector2i(760, 460)
	min_size = Vector2i(420, 300)
	unresizable = false

	_tab_script = load("res://scenes/terminal/terminal_tab.gd")

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Tab bar with + button
	var tab_bar_box = HBoxContainer.new()
	tab_bar_box.add_theme_constant_override("separation", 2)
	vbox.add_child(tab_bar_box)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab_bar_box.add_child(_tabs)

	# "+ New Tab" button
	var new_tab_btn = Button.new()
	new_tab_btn.text = "+"
	new_tab_btn.tooltip_text = "New terminal tab (Ctrl+T)"
	new_tab_btn.custom_minimum_size = Vector2(28, 28)
	new_tab_btn.pressed.connect(_on_new_tab_pressed)
	tab_bar_box.add_child(new_tab_btn)

	# Initial tab
	_add_tab(device_id)

	close_requested.connect(queue_free)

func _add_tab(p_device_id: String) -> void:
	if not _tab_script:
		return
	var tab = _tab_script.new()
	tab.name = _tab_title_for(p_device_id)
	_tabs.add_child(tab)
	tab.setup(p_device_id)
	tab.session_changed.connect(_on_tab_session_changed.bind(tab))
	_tabs.current_tab = _tabs.get_tab_count() - 1
	tab.focus_input()

func _tab_title_for(p_device_id: String) -> String:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dev = engine.get_device(p_device_id) if engine else null
	return dev.display_name if dev else p_device_id

func _on_new_tab_pressed() -> void:
	_add_tab(device_id)

func _on_tab_session_changed(new_device_id: String, tab) -> void:
	# Update tab title to reflect current SSH target
	tab.name = _tab_title_for(new_device_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_T:
			_on_new_tab_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_W:
			_close_current_tab()
			get_viewport().set_input_as_handled()

func _close_current_tab() -> void:
	if _tabs.get_tab_count() <= 1:
		# Last tab: close the window
		queue_free()
		return
	var current = _tabs.get_current_tab_control()
	if current:
		current.queue_free()
