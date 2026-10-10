extends PanelContainer

var _tab_container: TabContainer
var _console_output: RichTextLabel
var _log_output: RichTextLabel
var _debug_content: VBoxContainer
var _timer: float = 0.0
var _debug_labels: Dictionary = {}

func _ready() -> void:
	custom_minimum_size.y = 170

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tab_container)

	var cons_bg = StyleBoxFlat.new()
	cons_bg.bg_color = Color(0.05, 0.05, 0.07)
	cons_bg.content_margin_left = 8
	cons_bg.content_margin_right = 8
	cons_bg.content_margin_top = 6
	cons_bg.content_margin_bottom = 6

	_console_output = RichTextLabel.new()
	_console_output.name = "Console"
	_console_output.bbcode_enabled = true
	_console_output.scroll_following = true
	_console_output.selection_enabled = true
	_console_output.add_theme_stylebox_override("normal", cons_bg)
	_tab_container.add_child(_console_output)

	_log_output = RichTextLabel.new()
	_log_output.name = "Logs"
	_log_output.bbcode_enabled = true
	_log_output.scroll_following = true
	_log_output.selection_enabled = true
	_log_output.add_theme_stylebox_override("normal", cons_bg)
	_tab_container.add_child(_log_output)

	_debug_content = VBoxContainer.new()
	_debug_content.name = "Debug"
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_right", 10)
	m.add_child(_debug_content)
	_tab_container.add_child(m)

	for key in ["Sim Time", "Device Count", "Connection Count", "Speed", "State"]:
		var l = Label.new()
		l.text = key + ": "
		_debug_content.add_child(l)
		_debug_labels[key] = l

	if EventBus.has_signal("log_created"):
		EventBus.log_created.connect(_on_log_created)
	if EventBus.has_signal("command_executed"):
		EventBus.command_executed.connect(_on_command_executed)

func add_console_message(text: String, color: Color = Color.WHITE) -> void:
	_console_output.append_text("[color=#" + color.to_html(false) + "]" + text + "[/color]\n")

func _on_command_executed(description: String) -> void:
	add_console_message("✓ " + description, Color(0.5, 0.85, 0.6))

func _on_log_created(device_id: String, entry: Dictionary) -> void:
	var color = Color(0.85, 0.85, 0.85)
	if entry.level == "WARNING":
		color = Color.YELLOW
	elif entry.level == "ERROR":
		color = Color(1, 0.3, 0.3)

	var text = "[%s] [%s] %s: %s" % [entry.timestamp, entry.level, device_id, entry.message]
	_log_output.append_text("[color=#" + color.to_html(false) + "]" + text + "[/color]\n")

func update_debug() -> void:
	if SimTime and SimTime.has_method("get_formatted_time"):
		_debug_labels["Sim Time"].text = "Sim Time: " + SimTime.get_formatted_time()
	if SimEngine:
		if SimEngine.has_method("get_all_devices"):
			_debug_labels["Device Count"].text = "Device Count: " + str(SimEngine.get_all_devices().size())
		if "connections" in SimEngine:
			_debug_labels["Connection Count"].text = "Connection Count: " + str(SimEngine.connections.size())
		if "speed" in SimEngine:
			_debug_labels["Speed"].text = "Speed: " + str(SimEngine.speed) + "x"
		if "is_running" in SimEngine:
			_debug_labels["State"].text = "State: " + ("Running" if SimEngine.is_running else "Paused/Stopped")

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.5:
		_timer = 0.0
		update_debug()
