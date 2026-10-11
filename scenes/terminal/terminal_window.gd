extends Window
class_name TerminalWindow

var device_id: String
var _tabs: TabContainer
var _tab_script: Resource
var _show_logs: bool = true

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	title = "Terminal"
	size = Vector2i(900, 550)
	min_size = Vector2i(500, 350)
	unresizable = false

	_tab_script = load("res://scenes/terminal/terminal_tab.gd")

	# Main background
	var bg = ColorRect.new()
	bg.color = Color("#11111b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title bar with window controls
	var title_bar = HBoxContainer.new()
	title_bar.add_theme_constant_override("separation", 6)
	title_bar.add_theme_constant_override("margin_left", 8)
	title_bar.add_theme_constant_override("margin_right", 8)
	vbox.add_child(title_bar)

	var title_label = Label.new()
	title_label.text = "Terminal"
	title_label.add_theme_color_override("font_color", Color("#cdd6f4"))
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(title_label)

	var _device_label = Label.new()
	_device_label.add_theme_color_override("font_color", Color("#6c7086"))
	_device_label.add_theme_font_size_override("font_size", 11)
	title_bar.add_child(_device_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_bar.add_child(spacer)

	# Logs toggle
	var logs_toggle = CheckButton.new()
	logs_toggle.text = "Logs"
	logs_toggle.button_pressed = _show_logs
	logs_toggle.toggled.connect(_on_logs_toggled)
	logs_toggle.tooltip_text = "Toggle simulator logs visibility"
	title_bar.add_child(logs_toggle)

	# Close tab button
	var close_btn = Button.new()
	close_btn.text = "×"
	close_btn.tooltip_text = "Close window (Ctrl+Shift+W)"
	close_btn.custom_minimum_size = Vector2(28, 24)
	close_btn.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	close_btn.add_theme_color_override("font_color", Color("#f38ba8"))
	close_btn.pressed.connect(queue_free)
	title_bar.add_child(close_btn)

	# Tab bar
	var tab_bar_box = HBoxContainer.new()
	tab_bar_box.add_theme_constant_override("separation", 2)
	vbox.add_child(tab_bar_box)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_bar_box.add_child(_tabs)

	# "+ New Tab" button
	var new_tab_btn = Button.new()
	new_tab_btn.text = "+"
	new_tab_btn.tooltip_text = "New terminal tab (Ctrl+T)"
	new_tab_btn.custom_minimum_size = Vector2(28, 28)
	new_tab_btn.add_theme_stylebox_override("normal", StyleBoxFlat.new())
	new_tab_btn.add_theme_color_override("font_color", Color("#89b4fa"))
	new_tab_btn.pressed.connect(_on_new_tab_pressed)
	tab_bar_box.add_child(new_tab_btn)

	_tab_script = load("res://scenes/terminal/terminal_tab.gd")

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
	tab.name = _tab_title_for(new_device_id)

func _on_logs_toggled(pressed: bool) -> void:
	_show_logs = pressed
	if EventBus:
		EventBus.logs_visibility_toggled.emit(pressed)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var vp = get_viewport()
	if vp:
		var fo = vp.gui_get_focus_owner()
		if fo and not is_ancestor_of(fo) and fo != self:
			return
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_T:
			_on_new_tab_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_W and event.shift_pressed:
			queue_free()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_W:
			_close_current_tab()
			get_viewport().set_input_as_handled()

func _close_current_tab() -> void:
	if _tabs.get_tab_count() <= 1:
		queue_free()
		return
	var current = _tabs.get_current_tab_control()
	if current:
		current.queue_free()