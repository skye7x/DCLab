extends Window

var device_id: String
var _command_processor = null
var _output: RichTextLabel
var _input: LineEdit
var _history: Array = []
var _history_index: int = -1
var _prompt_label: Label

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	var tree = Engine.get_main_loop()
	var engine = tree.root.get_node_or_null("SimEngine") if tree and tree.root else null
	var device = engine.get_device(device_id) if engine else null
	if not device: return

	if "operating_system" in device and device.operating_system:
		var cp_class = load("res://terminal/command_processor.gd")
		if cp_class:
			_command_processor = cp_class.new(device_id, device.operating_system)
			_command_processor.engine_ref = engine

	title = "Terminal — " + (device.display_name if "display_name" in device else device_id)

	if _command_processor and _command_processor.has_method("get_prompt") and _prompt_label:
		_prompt_label.text = _command_processor.get_prompt()

	if _output:
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
		_append_output(banner)

func _ready() -> void:
	title = "Terminal"
	size = Vector2i(760, 460)
	min_size = Vector2i(420, 300)
	unresizable = false

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

	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_output)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

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
	close_requested.connect(queue_free)

	if _command_processor and _command_processor.has_method("get_prompt"):
		_prompt_label.text = _command_processor.get_prompt()

	_input.grab_focus.call_deferred()

func _on_command_entered(text: String) -> void:
	var prompt = _command_processor.get_prompt() if _command_processor and _command_processor.has_method("get_prompt") else "> "
	if text.strip_edges().is_empty():
		_append_output(prompt + "\n")
		_input.text = ""
		return

	_history.append(text)
	_history_index = _history.size()

	_append_output("[color=#7a7a85]" + prompt + "[/color]" + text + "\n")

	if _command_processor and _command_processor.has_method("process_input"):
		var result = _command_processor.process_input(text)
		if result == "[CLEAR]":
			_output.clear()
		elif not result.is_empty():
			_append_output(result + "\n")
	else:
		_append_output("[color=#d06060]Command processor not available.[/color]\n")

	if _command_processor and _command_processor.has_method("get_prompt"):
		_prompt_label.text = _command_processor.get_prompt()

	_input.text = ""
	_input.grab_focus()

func _append_output(text: String) -> void:
	_output.append_text(text)

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
	if not _command_processor or not ("commands" in _command_processor):
		return
	var text = _input.text
	if text.strip_edges() == "" or text.contains(" "):
		return
	var matches: Array = []
	for cmd in _command_processor.commands.keys():
		if cmd.begins_with(text):
			matches.append(cmd)
	if matches.size() == 1:
		_input.text = matches[0] + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		var prompt = _command_processor.get_prompt()
		_append_output("[color=#7a7a85]" + prompt + "[/color]" + text + "\n")
		_append_output("  " + "  ".join(matches) + "\n")
