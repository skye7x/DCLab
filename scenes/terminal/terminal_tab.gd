extends VBoxContainer

signal session_changed(device_id: String)

var device_id: String = ""
var command_processor = null
var _output: RichTextLabel
var _input: LineEdit
var _prompt_label: Label
var _history: Array = []
var _history_index: int = -1
var _session_stack: Array = []

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	_connect_processor()
	_print_banner()

func _connect_processor() -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(device_id) if engine else null
	if not device or not ("operating_system" in device) or not device.operating_system:
		_append("[color=#d06060]No OS available on this device.[/color]\n")
		return
	var cp_class = load("res://terminal/command_processor.gd")
	if cp_class:
		command_processor = cp_class.new(device_id, device.operating_system)
		command_processor.engine_ref = engine
	if _prompt_label and command_processor.has_method("get_prompt"):
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
	var banner = "[color=#5a8fd8]%s[/color] %s" % [device.display_name, device_id]
	if ip_str != "":
		banner += "  [color=#7a7a85]%s[/color]" % ip_str
	banner += "\nType [color=#c8c8c8]help[/color] for commands, [color=#c8c8c8]Tab[/color] to complete.\n\n"
	_append(banner)

func _ready() -> void:
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
	add_child(_output)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)

	_prompt_label = Label.new()
	_prompt_label.add_theme_color_override("font_color", Color(0.35, 0.85, 0.4))
	_prompt_label.custom_minimum_size.x = 80
	hbox.add_child(_prompt_label)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.placeholder_text = "type a command…"
	var sb = StyleBoxEmpty.new()
	_input.add_theme_stylebox_override("normal", sb)
	_input.add_theme_stylebox_override("focus", sb)
	_input.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox.add_child(_input)

	_input.text_submitted.connect(_on_command_entered)
	_input.gui_input.connect(_on_input_gui_input)

	if command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()

func focus_input() -> void:
	if _input:
		_input.grab_focus()

func _on_command_entered(text: String) -> void:
	var prompt = command_processor.get_prompt() if command_processor and command_processor.has_method("get_prompt") else "> "
	if text.strip_edges().is_empty():
		_append(prompt + "\n")
		_input.text = ""
		return

	_history.append(text)
	_history_index = _history.size()

	_append("[color=#7a7a85]" + prompt + "[/color]" + text + "\n")

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
			_append(result + "\n")
	else:
		_append("[color=#d06060]Command processor not available.[/color]\n")

	if command_processor and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()

	_input.text = ""
	_input.grab_focus()

func _append(text: String) -> void:
	_output.append_text(text)

func _switch_ssh_session(target_dev_id: String, login_user: String) -> void:
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var dest_dev = engine.get_device(target_dev_id) if engine else null
	if not dest_dev or not ("operating_system" in dest_dev) or not dest_dev.operating_system:
		_append("[color=#d06060]ssh: target OS unavailable[/color]\n")
		return
	_session_stack.append({"device_id": device_id, "processor": command_processor})
	device_id = target_dev_id
	var os = dest_dev.operating_system
	os.switch_user(login_user)
	var cp_class = load("res://terminal/command_processor.gd")
	command_processor = cp_class.new(target_dev_id, os)
	command_processor.engine_ref = engine
	_append("[color=#5a8fd8]Connected to %s (%s) as %s[/color]\n" % [dest_dev.display_name, target_dev_id, login_user])
	_append("[color=#7a7a85]Type 'exit' to return.[/color]\n")
	if _prompt_label and command_processor.has_method("get_prompt"):
		_prompt_label.text = command_processor.get_prompt()
	session_changed.emit(device_id)

func _exit_ssh_session() -> void:
	if _session_stack.is_empty():
		_append("logout\n")
		return
	var prev = _session_stack.pop_back()
	device_id = prev.device_id
	command_processor = prev.processor
	_append("[color=#5a8fd8]Disconnected from remote session.[/color]\n")
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
		_append("[color=#7a7a85]" + prompt + "[/color]" + text + "\n")
		_append("  " + "  ".join(matches) + "\n")
