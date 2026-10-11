extends VBoxContainer
class_name TerminalTab

signal session_changed(device_id: String)
signal tab_close_requested()

var device_id: String = ""
var command_processor = null
var _output: RichTextLabel
var _input: LineEdit
var _prompt_label: Label
var _history: Array = []
var _history_index: int = -1
var _session_stack: Array = []
var _pending_text: String = ""
var _scroll_at_bottom: bool = true

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	_connect_processor()
	_print_banner()

func _connect_processor() -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(device_id) if engine else null
	if not device or not ("operating_system" in device) or not device.operating_system:
		_append_ansi("[color=#ff6b6b]No OS available on this device.[/color]\n")
		return
	var cp_class = load("res://terminal/command_processor.gd")
	if cp_class:
		command_processor = cp_class.new(device_id, device.operating_system)
		command_processor.engine_ref = engine
	if _prompt_label and command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()

func _print_banner() -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(device_id) if engine else null
	if not device:
		return
	var ip_str = ""
	if "network_interfaces" in device:
		for iface in device.network_interfaces.values():
			if iface.ipv4_address != "":
				ip_str = iface.ipv4_address
				break
	var banner = "[color=#74c7ec][b]%s[/b][/color] [color=#a6adc8]%s[/color]" % [device.display_name, device_id]
	if ip_str != "":
		banner += "  [color=#89b4fa]%s[/color]" % ip_str
	banner += "\n[color=#6c7086]Type 'help' for commands, Tab to complete, Ctrl+L to clear[/color]\n\n"
	_append_ansi(banner)

func _ready() -> void:
	# Output area with custom styling
	var output_container = VBoxContainer.new()
	output_container.v_size_flags = Control.SIZE_EXPAND_FILL
	add_child(output_container)
	
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.context_menu_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", Color("#cdd6f4"))
	_output.add_theme_color_override("selection_color", Color("#45475a"))
	_output.add_theme_color_override("selection_font_color", Color("#cdd6f4"))
	output_container.add_child(_output)
	
	# Scroll to bottom when new content added
	_output.connect("text_changed", _on_output_changed)
	
	# Status bar
	var status_bar = HBoxContainer.new()
	status_bar.add_theme_constant_override("separation", 8)
	add_child(status_bar)
	
	var spacer = Control.new()
	spacer.h_size_flags = Control.SIZE_EXPAND_FILL
	status_bar.add_child(spacer)
	
	var _device_label = Label.new()
	_device_label.add_theme_color_override("font_color", Color("#6c7086"))
	_device_label.add_theme_font_size_override("font_size", 11)
	_device_label.text = "Device: %s" % device_id
	status_bar.add_child(_device_label)
	
	# Input area
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_theme_constant_override("margin_top", 4)
	hbox.add_theme_constant_override("margin_bottom", 4)
	add_child(hbox)
	
	_prompt_label = Label.new()
	_prompt_label.add_theme_color_override("font_color", Color("#a6e3a1"))
	_prompt_label.add_theme_font_size_override("font_size", 13)
	_prompt_label.custom_minimum_size.x = 100
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(_prompt_label)
	
	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = "type a command…"
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#1e1e2e")
	sb.border_color = Color("#313244")
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_bottom_right = 4
	_input.add_theme_stylebox_override("normal", sb)
	_input.add_theme_stylebox_override("focus", sb)
	_input.add_theme_color_override("font_color", Color("#cdd6f4"))
	_input.add_theme_color_override("selection_color", Color("#f5e0dc"))
	hbox.add_child(_input)
	
	_input.text_submitted.connect(_on_command_entered)
	_input.gui_input.connect(_on_input_gui_input)
	
	if command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()
	
	_input.grab_focus()

func _on_output_changed() -> void:
	if _scroll_at_bottom:
		call_deferred(_scroll_to_bottom)

func _scroll_to_bottom() -> void:
	var scroll = _output.get_v_scroll_bar()
	if scroll:
		scroll.value = scroll.max_value

func focus_input() -> void:
	if _input:
		_input.grab_focus()

func _on_command_entered(text: String) -> void:
	var prompt = command_processor.get_prompt() if command_processor and command_processor.has_method("get_prompt") else "> "
	if text.strip_edges().is_empty():
		_append_ansi("[color=#6c7086]%s[/color]\n" % prompt)
		_input.text = ""
		return

	_history.append(text)
	_history_index = _history.size()

	_append_ansi("[color=#6c7086]%s[/color]%s\n" % [prompt, text])

	if command_processor and command_processor.has_method("process_input"):
		var result = command_processor.process_input(text)
		if result == "[CLEAR]":
			_output.clear()
		elif result.begins_with("[SSH_SESSION:"):
			var parts = result.trim_prefix("[SSH_SESSION:").trim_suffix("]").split(":", true, 1)
			var target_dev_id = parts[0]
			var login_user = parts[1] if parts.size() > 1 else "root"
			_switch_ssh_session(target_dev_id, login_user)
		elif result == "[SSH_EXIT]":
			_exit_ssh_session()
		elif not result.is_empty():
			_append_ansi(result + "\n")
	else:
		_append_ansi("[color=#f38ba8]Command processor not available.[/color]\n")

	if command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()

	_input.text = ""
	_input.grab_focus()

func _append_ansi(text: String) -> void:
	if not _output:
		_pending_text += text
		return
	_output.append_text(_parse_ansi(text))

func _parse_ansi(text: String) -> String:
	# Convert basic ANSI escape codes to BBCode
	var result = text
	# Reset
	result = result.replace("\x1b[0m", "[/color]")
	# Bold
	result = result.replace("\x1b[1m", "[b]")
	# Colors - basic 16 colors
	var colors = {
		"\x1b[30m": "[color=#45475a]",   # Black
		"\x1b[31m": "[color=#f38ba8]",   # Red
		"\x1b[32m": "[color=#a6e3a1]",   # Green
		"\x1b[33m": "[color=#f9e2af]",   # Yellow
		"\x1b[34m": "[color=#89b4fa]",   # Blue
		"\x1b[35m": "[color=#f5c2e7]",   # Magenta
		"\x1b[36m": "[color=#94e2d5]",   # Cyan
		"\x1b[37m": "[color=#cdd6f4]",   # White
		"\x1b[90m": "[color=#6c7086]",   # Bright Black
		"\x1b[91m": "[color=#f38ba8]",   # Bright Red
		"\x1b[92m": "[color=#a6e3a1]",   # Bright Green
		"\x1b[93m": "[color=#f9e2af]",   # Bright Yellow
		"\x1b[94m": "[color=#89b4fa]",   # Bright Blue
		"\x1b[95m": "[color=#f5c2e7]",   # Bright Magenta
		"\x1b[96m": "[color=#94e2d5]",   # Bright Cyan
		"\x1b[97m": "[color=#cdd6f4]",   # Bright White
	}
	for code in colors:
		result = result.replace(code, colors[code])
	# Background colors
	var bg_colors = {
		"\x1b[40m": "[color=#1e1e2e]",
		"\x1b[41m": "[color=#f38ba8]",
		"\x1b[42m": "[color=#a6e3a1]",
		"\x1b[43m": "[color=#f9e2af]",
		"\x1b[44m": "[color=#89b4fa]",
		"\x1b[45m": "[color=#f5c2e7]",
		"\x1b[46m": "[color=#94e2d5]",
		"\x1b[47m": "[color=#cdd6f4]",
	}
	for code in bg_colors:
		result = result.replace(code, bg_colors[code])
	return result

func _switch_ssh_session(target_dev_id: String, login_user: String) -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dest_dev = engine.get_device(target_dev_id) if engine else null
	if not dest_dev or not ("operating_system" in dest_dev) or not dest_dev.operating_system:
		_append_ansi("[color=#f38ba8]ssh: target OS unavailable[/color]\n")
		return
	_session_stack.append({"device_id": device_id, "processor": command_processor})
	device_id = target_dev_id
	var os = dest_dev.operating_system
	os.switch_user(login_user)
	var cp_class = load("res://terminal/command_processor.gd")
	command_processor = cp_class.new(target_dev_id, os)
	command_processor.engine_ref = engine
	_append_ansi("[color=#89b4fa]Connected to %s (%s) as %s[/color]\n" % [dest_dev.display_name, target_dev_id, login_user])
	_append_ansi("[color=#6c7086]Type 'exit' to return.[/color]\n")
	if _prompt_label and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()
	session_changed.emit(device_id)

func _exit_ssh_session() -> void:
	if _session_stack.is_empty():
		_append_ansi("logout\n")
		return
	var prev = _session_stack.pop_back()
	device_id = prev.device_id
	command_processor = prev.processor
	_append_ansi("[color=#89b4fa]Disconnected from remote session.[/color]\n")
	if _prompt_label and command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()
	session_changed.emit(device_id)

func _on_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			if _history.size() > 0:
				_history_index = clampi(_history_index - 1, 0, _history.size() - 1)
				_input.text = _history[_history_index]
				_input.caret_column = _input.text.length()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			if _history.size() > 0:
				_history_index = clampi(_history_index + 1, 0, _history.size())
				if _history_index < _history.size():
					_input.text = _history[_history_index]
				else:
					_input.text = ""
				_input.caret_column = _input.text.length()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L and event.ctrl_pressed:
			_output.clear()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			_try_autocomplete()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C and event.ctrl_pressed:
			# Copy selection
			if _output.get_selection_text() != "":
				DisplayServer.clipboard_set(_output.get_selection_text())
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V and event.ctrl_pressed:
			# Paste
			var clip = DisplayServer.clipboard_get()
			if clip != "":
				_input.text += clip
			get_viewport().set_input_as_handled()

func _try_autocomplete() -> void:
	if not command_processor or not ("commands" in command_processor):
		return
	var text = _input.text
	if text.strip_edges() == "" or text.contains(" "):
		return
	var matches: Array = []
	for cmd in command_processor.commands.keys():
		if cmd.begins_with(text):
			matches.append(cmd)
	if matches.size() == 1:
		_input.text = matches[0] + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		var prompt = command_processor.get_prompt()
		_append_ansi("[color=#6c7086]%s[/color]%s\n" % [prompt, text])
		_append_ansi("  [color=#89b4fa]%s[/color]\n" % "  ".join(matches))

func _on_output_scrolled() -> void:
	var scroll = _output.get_v_scroll_bar()
	if scroll:
		_scroll_at_bottom = (scroll.value >= scroll.max_value - 10)