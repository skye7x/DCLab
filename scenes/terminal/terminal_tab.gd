extends VBoxContainer
class_name TerminalTab
## One shell session: scrollback, prompt + input, status footer.
##
## Layout (top to bottom):  output (expands) | prompt + input | status footer
## Output is written through RichTextLabel's push/add API, never as BBCode, so
## brackets in command output or user input can never be parsed as markup.

const T := preload("res://scenes/terminal/terminal_theme.gd")
const Processor := preload("res://scenes/terminal/command_processor.gd")

signal session_changed(device_id: String)
signal title_changed(title: String)
signal prompt_changed(prompt: String)
signal tab_close_requested()

const HISTORY_MAX := 500
const SCROLLBACK_MAX := 3000
## Commands whose arguments are file-system paths / user names (for Tab completion).
const PATH_COMMANDS := ["ls", "cd", "cat", "mkdir", "touch", "rm", "tail"]
const USER_COMMANDS := ["su", "passwd", "userdel"]
## Output lines containing these (and shaped like a diagnostic) are shown in red.
const ERROR_MARKERS := [
	"command not found", "no such file", "permission denied", "cannot access",
	"not a directory", "is a directory", "does not exist", "not permitted",
	"not found", "no route", "nxdomain", "unknown host", "invalid", "failed", "refused", "unreachable", "timed out",
	"100% packet loss",
]

var device_id: String = ""            # device whose shell is currently active (changes on ssh)
var origin_device_id: String = ""     # device this tab was opened for
var command_processor = null

var _output: RichTextLabel
var _edit: LineEdit
var _input_row: PanelContainer
var _prompt_user: Label
var _prompt_sep: Label
var _prompt_path: Label
var _prompt_sym: Label
var _status_dot: Label
var _status_text: Label
var _hint: Label

var _history: Array = []
var _history_index: int = 0
var _draft: String = ""
var _sessions: Array = []             # ssh stack: [{device_id, processor, os, user}]
var _su_stack: Array = []             # su stack: [{os, user, cwd, depth}] (depth = ssh depth when pushed)
var _logs_on: bool = false
var _built: bool = false
var _want_start: bool = false

static var _re_ip: RegEx
static var _re_prompt: RegEx
static var _re_diag: RegEx


# ----------------------------------------------------------------------------
# Lifecycle
# ----------------------------------------------------------------------------

func setup(p_device_id: String) -> void:
	device_id = p_device_id
	origin_device_id = p_device_id
	if _built:
		_start()
	else:
		_want_start = true


func _ready() -> void:
	_build_ui()
	_built = true
	if EventBus:
		EventBus.device_removed.connect(_on_device_removed)
		EventBus.device_power_changed.connect(_on_device_power_changed)
	if _want_start:
		_start()


func _exit_tree() -> void:
	if EventBus:
		if EventBus.device_removed.is_connected(_on_device_removed):
			EventBus.device_removed.disconnect(_on_device_removed)
		if EventBus.device_power_changed.is_connected(_on_device_power_changed):
			EventBus.device_power_changed.disconnect(_on_device_power_changed)
		if EventBus.log_created.is_connected(_on_log_created):
			EventBus.log_created.disconnect(_on_log_created)


func _request_close() -> void:
	tab_close_requested.emit()


func focus_input() -> void:
	if _edit and _edit.editable:
		_edit.grab_focus()


func get_title() -> String:
	var dev = _device(device_id)
	return dev.display_name if dev else device_id


func get_prompt_text() -> String:
	if command_processor and command_processor.has_method("get_prompt"):
		return command_processor.get_prompt().strip_edges()
	return ""


func set_logs_enabled(on: bool, announce: bool = true) -> void:
	if on == _logs_on:
		return
	_logs_on = on
	if on:
		EventBus.log_created.connect(_on_log_created)
	elif EventBus.log_created.is_connected(_on_log_created):
		EventBus.log_created.disconnect(_on_log_created)
	if announce:
		_writeln("logs %s" % ("on: simulator events for this device will appear here" if on else "off"), T.MUTE)


func _start() -> void:
	_want_start = false
	_connect_processor()
	_print_banner()
	_refresh_prompt()
	_refresh_status()
	title_changed.emit(get_title())
	focus_input()


# ----------------------------------------------------------------------------
# UI construction
# ----------------------------------------------------------------------------

func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)

	# Scrollback.
	_output = RichTextLabel.new()
	_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.bbcode_enabled = false
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.context_menu_enabled = true
	_output.deselect_on_focus_loss_enabled = false
	_output.focus_mode = Control.FOCUS_NONE
	_output.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_output.add_theme_font_override("normal_font", T.mono())
	_output.add_theme_font_override("bold_font", T.mono(true))
	_output.add_theme_font_override("mono_font", T.mono())
	_output.add_theme_font_size_override("normal_font_size", T.FONT_SIZE)
	_output.add_theme_font_size_override("bold_font_size", T.FONT_SIZE)
	_output.add_theme_font_size_override("mono_font_size", T.FONT_SIZE)
	_output.gui_input.connect(_on_output_gui_input)
	add_child(_output)

	# Prompt + input.
	_input_row = PanelContainer.new()
	_input_row.add_theme_stylebox_override("panel",
		T.flat(T.CANVAS, 0, T.HAIRLINE, Vector4(0, 1, 0, 0), Vector4(14, 9, 14, 9)))
	_input_row.gui_input.connect(_on_input_row_gui_input)
	add_child(_input_row)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_input_row.add_child(row)

	var prompt_box := HBoxContainer.new()
	prompt_box.add_theme_constant_override("separation", 0)
	prompt_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prompt_box)
	_prompt_user = _prompt_label(prompt_box, T.INK, true)
	_prompt_sep = _prompt_label(prompt_box, T.FAINT)
	_prompt_path = _prompt_label(prompt_box, T.ACCENT)
	_prompt_sym = _prompt_label(prompt_box, T.FAINT)

	_edit = LineEdit.new()
	_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit.placeholder_text = "type a command, or help"
	_edit.caret_blink = true
	_edit.keep_editing_on_text_submit = true
	_edit.context_menu_enabled = true
	_edit.add_theme_font_override("font", T.mono())
	_edit.add_theme_font_size_override("font_size", T.FONT_SIZE)
	_edit.text_submitted.connect(_on_submitted)
	_edit.gui_input.connect(_on_input_gui_input)
	row.add_child(_edit)

	# Status footer.
	var footer := PanelContainer.new()
	footer.add_theme_stylebox_override("panel",
		T.flat(T.SURFACE, 0, T.HAIRLINE, Vector4(0, 1, 0, 0), Vector4(14, 5, 14, 5)))
	add_child(footer)
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 6)
	footer.add_child(frow)

	_hint = Label.new()
	_hint.text = "Enter run   Tab complete   Up/Down history   Ctrl+L clear   Ctrl+C cancel"
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.clip_text = true
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	T.style_label(_hint, T.MUTE, T.FONT_SIZE_SMALL)
	frow.add_child(_hint)

	_status_dot = Label.new()
	T.style_label(_status_dot, T.OK, T.FONT_SIZE_SMALL)
	frow.add_child(_status_dot)
	_status_text = Label.new()
	T.style_label(_status_text, T.BODY, T.FONT_SIZE_SMALL)
	frow.add_child(_status_text)


func _prompt_label(parent: Control, color: Color, bold: bool = false) -> Label:
	var l := Label.new()
	T.style_label(l, color, T.FONT_SIZE, bold)
	parent.add_child(l)
	return l


# ----------------------------------------------------------------------------
# Device / processor plumbing
# ----------------------------------------------------------------------------

func _device(id: String):
	return SimEngine.get_device(id) if SimEngine and id != "" else null


func _command_processor_for(dev) -> Object:
	var cp = Processor.new(dev.id, dev.operating_system)
	cp.engine_ref = SimEngine
	return cp


## The simulator never creates /root (OperatingSystem.add_user skips root), so the
## first `ls` in a fresh shell fails. Create the logged-in user's home if it is missing.
func _ensure_home(os) -> void:
	if os == null or os.current_user == null or os.file_system == null:
		return
	var home: String = os.current_user.home_directory
	if home != "" and not os.file_system.exists(home):
		os.file_system.create_directory(home)


func _connect_processor() -> void:
	var dev = _device(device_id)
	if dev == null or not ("operating_system" in dev) or dev.operating_system == null:
		_writeln("No operating system on this device.", T.ERROR)
		_edit.editable = false
		_edit.placeholder_text = "this device has no shell"
		return
	_ensure_home(dev.operating_system)
	command_processor = _command_processor_for(dev)


func _print_banner() -> void:
	var dev = _device(device_id)
	if dev == null:
		return
	_write(dev.display_name, T.INK, true)
	_writeln("   " + device_id, T.MUTE)
	if "network_interfaces" in dev:
		for iface in dev.network_interfaces.values():
			if iface.ipv4_address == "":
				continue
			var cidr: int = iface.get_cidr()
			_write("  %-6s" % iface.iface_name, T.MUTE)
			_writeln(iface.ipv4_address + ("/%d" % cidr if cidr > 0 else ""), T.ACCENT)
	if not dev.is_powered_on:
		_writeln("This device is powered off.", T.WARN)
	_write("Type ", T.MUTE)
	_write("help", T.INK)
	_writeln(" to list commands.", T.MUTE)
	_write("\n")


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------

func _write(text: String, color: Color = T.OUT, bold: bool = false) -> void:
	if text.is_empty() or _output == null:
		return
	_output.push_color(color)
	if bold:
		_output.push_bold()
	_output.add_text(text)
	if bold:
		_output.pop()
	_output.pop()


func _writeln(text: String, color: Color = T.OUT, bold: bool = false) -> void:
	_write(text, color, bold)
	_write("\n")


## Echo a submitted line the way a shell does: coloured prompt, then the command.
func _echo(prompt: String, command: String) -> void:
	var p := _split_prompt(prompt)
	if p.is_empty():
		_write(prompt, T.MUTE)
	else:
		_write(p.user + "@" + p.host, T.INK, true)
		_write(":", T.FAINT)
		_write(p.path, T.ACCENT)
		_write(p.sym + " ", T.FAINT)
	_writeln(command, T.INK)


func _write_result(result: String, cmd: String) -> void:
	for line in result.trim_suffix("\n").split("\n"):
		_write_line(line, cmd)
	_trim_scrollback()


func _write_line(line: String, cmd: String) -> void:
	var tone := _classify(line)
	if tone != T.OUT:
		_writeln(line, tone)
		return
	if cmd == "ls":
		var parts := line.split(" ")
		for i in parts.size():
			_write(parts[i], T.ACCENT if parts[i].ends_with("/") else T.OUT)
			if i < parts.size() - 1:
				_write(" ")
		_write("\n")
		return
	# Highlight IPv4 addresses (with optional /cidr) so tables are scannable.
	var matches := _ip_regex().search_all(line)
	var pos := 0
	for m in matches:
		_write(line.substr(pos, m.get_start() - pos))
		_write(m.get_string(), T.ACCENT)
		pos = m.get_end()
	_write(line.substr(pos))
	_write("\n")


func _classify(line: String) -> Color:
	var s := line.lstrip(" \t")
	if s.is_empty():
		return T.OUT
	var low := s.to_lower()
	if low.begins_with("warning") or low.begins_with("usage:"):
		return T.WARN
	if low.begins_with("error"):
		return T.ERROR
	var diagnostic := _diag_regex().search(s) != null
	for marker in ERROR_MARKERS:
		if low.contains(marker):
			# Prose with these words (file contents, help text) stays neutral unless it
			# is shaped like a diagnostic ("bash: ...") or is a network failure line.
			if diagnostic or marker in ["unreachable", "timed out", "100% packet loss", "refused"]:
				return T.ERROR
	return T.OUT


func _trim_scrollback() -> void:
	var excess := _output.get_paragraph_count() - SCROLLBACK_MAX
	if excess > 100:
		for i in excess:
			_output.remove_paragraph(0, true)


func _clear_output() -> void:
	_output.clear()


func _stick_to_bottom() -> void:
	var sb := _output.get_v_scroll_bar()
	if sb:
		sb.value = sb.max_value


# ----------------------------------------------------------------------------
# Prompt / status
# ----------------------------------------------------------------------------

func _split_prompt(raw: String) -> Dictionary:
	var m := _prompt_regex().search(raw.strip_edges())
	if m == null:
		return {}
	return {"user": m.get_string(1), "host": m.get_string(2), "path": m.get_string(3), "sym": m.get_string(4)}


func _refresh_prompt() -> void:
	var raw := get_prompt_text()
	var p := _split_prompt(raw)
	if p.is_empty():
		_prompt_user.text = raw if raw != "" else ">"
		_prompt_sep.text = ""
		_prompt_path.text = ""
		_prompt_sym.text = ""
	else:
		_prompt_user.text = p.user + "@" + p.host
		_prompt_sep.text = ":"
		_prompt_path.text = p.path
		_prompt_sym.text = p.sym
	prompt_changed.emit(raw)


func _refresh_status() -> void:
	var dev = _device(device_id)
	var on: bool = dev != null and dev.is_powered_on
	# Shape + colour, so state never relies on colour alone.
	_status_dot.text = "●" if on else "○"
	_status_dot.add_theme_color_override("font_color", T.OK if on else T.WARN)
	var label := get_title()
	if not _sessions.is_empty():
		label += "  via ssh from " + _device_name(_sessions[0].device_id)
	_status_text.text = label + ("" if on else "  (powered off)")


func _device_name(id: String) -> String:
	var dev = _device(id)
	return dev.display_name if dev else id


# ----------------------------------------------------------------------------
# Running commands
# ----------------------------------------------------------------------------

func _on_submitted(text: String) -> void:
	var line := text
	_edit.clear()
	_history_index = _history.size()
	_draft = ""
	var prompt := get_prompt_text() if command_processor else ">"
	_echo(prompt, line)
	if line.strip_edges().is_empty():
		_stick_to_bottom.call_deferred()
		return
	if _history.is_empty() or _history.back() != line:
		_history.append(line)
		if _history.size() > HISTORY_MAX:
			_history.pop_front()
	_history_index = _history.size()
	_run(line)
	_refresh_prompt()
	_stick_to_bottom.call_deferred()


func _run(line: String) -> void:
	if command_processor == null:
		_writeln("Command processor not available.", T.ERROR)
		return
	var cmd := line.strip_edges().split(" ", false)[0]
	var os = command_processor.os_ref
	var prev_user: String = os.current_user.username if os and os.current_user else ""
	var prev_cwd: String = command_processor.current_directory
	var raw = command_processor.process_input(line)
	var result: String = raw if raw is String else ("" if raw == null else str(raw))
	if result == "[CLEAR]":
		_clear_output()
	elif result.begins_with("[SSH_SESSION:"):
		var parts := result.trim_prefix("[SSH_SESSION:").trim_suffix("]").split(":", true, 1)
		_enter_ssh_session(parts[0], parts[1] if parts.size() > 1 else "root")
	elif result == "[SSH_EXIT]":
		_leave_shell_level()
	else:
		if cmd == "su" and result.begins_with("Now acting as"):
			_su_stack.append({"os": os, "user": prev_user, "cwd": prev_cwd, "depth": _sessions.size()})
		if not result.is_empty():
			_write_result(result, cmd)


## `exit` / Ctrl+D: leave the innermost level: an `su` user, else an ssh session,
## else the terminal tab itself.
func _leave_shell_level() -> void:
	if not _su_stack.is_empty() and _su_stack.back().depth == _sessions.size():
		var level: Dictionary = _su_stack.pop_back()
		level.os.switch_user(level.user)
		command_processor.current_directory = level.cwd
	elif not _sessions.is_empty():
		_exit_ssh_session()
	else:
		_writeln("logout", T.MUTE)
		_request_close.call_deferred()


# ----------------------------------------------------------------------------
# SSH sessions
# ----------------------------------------------------------------------------

func _enter_ssh_session(target_id: String, login_user: String) -> void:
	var dest = _device(target_id)
	if dest == null or not ("operating_system" in dest) or dest.operating_system == null:
		_writeln("ssh: target OS unavailable", T.ERROR)
		return
	var dest_os = dest.operating_system
	_sessions.append({
		"device_id": device_id,
		"processor": command_processor,
		"os": dest_os,
		"user": dest_os.current_user.username if dest_os.current_user else "",
	})
	dest_os.switch_user(login_user)
	_ensure_home(dest_os)
	device_id = target_id
	command_processor = _command_processor_for(dest)
	_write("Connected to ", T.MUTE)
	_write(dest.display_name, T.INK, true)
	_write(" as ", T.MUTE)
	_writeln(login_user, T.INK)
	_writeln("Type exit to return.", T.MUTE)
	_after_session_change()


func _exit_ssh_session(reason: String = "") -> void:
	if _sessions.is_empty():
		return
	var prev: Dictionary = _sessions.pop_back()
	_su_stack = _su_stack.filter(func(e): return e.depth <= _sessions.size())
	# Undo the login: the remote OS goes back to whoever was logged in before.
	if prev.os and prev.user != "":
		prev.os.switch_user(prev.user)
	device_id = prev.device_id
	command_processor = prev.processor
	_writeln(reason if reason != "" else "Connection closed.", T.MUTE)
	_after_session_change()


func _after_session_change() -> void:
	_refresh_prompt()
	_refresh_status()
	title_changed.emit(get_title())
	session_changed.emit(device_id)


# ----------------------------------------------------------------------------
# Keyboard
# ----------------------------------------------------------------------------

func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var k := event as InputEventKey
	var ctrl := k.is_command_or_control_pressed()
	if ctrl:
		match k.keycode:
			KEY_L:
				_clear_output()
				_edit.accept_event()
			KEY_C:
				var selected := _output.get_selected_text()
				if selected != "":
					DisplayServer.clipboard_set(selected)
					_edit.accept_event()
				elif not _edit.has_selection():
					_cancel_line()
					_edit.accept_event()
				# else: let LineEdit copy its own selection
			KEY_U:
				_set_input(_edit.text.substr(_edit.caret_column), 0)
				_edit.accept_event()
			KEY_K:
				_set_input(_edit.text.substr(0, _edit.caret_column), _edit.caret_column)
				_edit.accept_event()
			KEY_D:
				if _edit.text.is_empty() and (not _sessions.is_empty() or not _su_stack.is_empty()):
					_echo(get_prompt_text(), "exit")
					_leave_shell_level()
					_refresh_prompt()
					_edit.accept_event()
		return
	match k.keycode:
		KEY_UP:
			_history_step(-1)
			_edit.accept_event()
		KEY_DOWN:
			_history_step(1)
			_edit.accept_event()
		KEY_TAB:
			_complete()
			_edit.accept_event()
		KEY_PAGEUP, KEY_PAGEDOWN:
			var sb := _output.get_v_scroll_bar()
			if sb:
				sb.value += (-1 if k.keycode == KEY_PAGEUP else 1) * sb.page * 0.9
			_edit.accept_event()


func _cancel_line() -> void:
	var prompt := get_prompt_text() if command_processor else ">"
	_echo(prompt, _edit.text + "^C")
	_edit.clear()
	_history_index = _history.size()
	_draft = ""
	_stick_to_bottom.call_deferred()


func _set_input(text: String, caret: int) -> void:
	_edit.text = text
	_edit.caret_column = caret


func _history_step(dir: int) -> void:
	if _history.is_empty():
		return
	if _history_index == _history.size() and dir < 0:
		_draft = _edit.text          # keep what was being typed
	_history_index = clampi(_history_index + dir, 0, _history.size())
	var text: String = _draft if _history_index == _history.size() else _history[_history_index]
	_set_input(text, text.length())


# ----------------------------------------------------------------------------
# Tab completion
# ----------------------------------------------------------------------------

func _complete() -> void:
	if command_processor == null:
		return
	var text := _edit.text
	var before := text.substr(0, _edit.caret_column)
	var after := text.substr(_edit.caret_column)
	var split_at := before.rfind(" ")
	var head := before.substr(0, split_at + 1)
	var word := before.substr(split_at + 1)
	var first := head.strip_edges().split(" ", false)
	var candidates: Array = []
	if first.is_empty():
		for cname in _command_names():
			if cname.begins_with(word):
				candidates.append(cname)
	elif first[0] in PATH_COMMANDS:
		candidates = _path_candidates(word, first[0] == "cd")
	elif first[0] in USER_COMMANDS:
		for u in command_processor.os_ref.users:
			if u.username.begins_with(word):
				candidates.append(u.username)
	if candidates.is_empty():
		return
	candidates.sort()
	if candidates.size() == 1:
		var only: String = candidates[0]
		var done := head + only + ("" if only.ends_with("/") else " ")
		_set_input(done + after, done.length())
		return
	var common := _common_prefix(candidates)
	if common.length() > word.length():
		_set_input(head + common + after, (head + common).length())
		return
	# Nothing more to add: list the options, as a shell would.
	_echo(get_prompt_text(), text)
	for c in candidates:
		var shown: String = c.substr(c.rfind("/", c.length() - 2) + 1) if c.contains("/") else c
		_write(shown + "  ", T.ACCENT if shown.ends_with("/") else T.OUT)
	_write("\n")
	_stick_to_bottom.call_deferred()


func _command_names() -> Array:
	var names: Array = command_processor.commands.keys()
	var os = command_processor.os_ref
	if os:
		for a in os.aliases.keys():
			if a not in names:
				names.append(a)
	return names


func _path_candidates(word: String, dirs_only: bool) -> Array:
	var out: Array = []
	if word.begins_with("~") or command_processor.os_ref == null:
		return out
	var fs = command_processor.os_ref.file_system
	var slash := word.rfind("/")
	var dir_part := word.substr(0, slash + 1)
	var base := word.substr(slash + 1)
	var dir_path: String = fs.resolve_path(command_processor.current_directory, dir_part if dir_part != "" else ".")
	if not fs.exists(dir_path) or not fs.is_dir(dir_path):
		return out
	for child in fs.list_directory(dir_path):
		if dirs_only and not child.is_directory:
			continue
		if child.node_name.begins_with(base):
			out.append(dir_part + child.node_name + ("/" if child.is_directory else ""))
	return out


func _common_prefix(items: Array) -> String:
	var prefix: String = items[0]
	for item in items:
		while not (item as String).begins_with(prefix):
			prefix = prefix.substr(0, prefix.length() - 1)
	return prefix


# ----------------------------------------------------------------------------
# Mouse
# ----------------------------------------------------------------------------

func _on_output_gui_input(event: InputEvent) -> void:
	# Clicking the scrollback must not steal typing focus unless the user is selecting text.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_refocus_unless_selecting.call_deferred()


func _refocus_unless_selecting() -> void:
	if _output.get_selected_text().is_empty():
		focus_input()


func _on_input_row_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focus_input()


# ----------------------------------------------------------------------------
# Simulator events
# ----------------------------------------------------------------------------

func _on_log_created(log_device_id: String, entry: Dictionary) -> void:
	if log_device_id != device_id:
		return
	var level: String = entry.get("level", "INFO")
	var tone: Color = T.MUTE
	if level == "WARNING":
		tone = T.WARN
	elif level == "ERROR":
		tone = T.ERROR
	_writeln("%8.2f  %-7s %s" % [float(entry.get("timestamp", 0.0)), level, entry.get("message", "")], tone)
	_trim_scrollback()


func _on_device_removed(removed_id: String) -> void:
	if removed_id == origin_device_id:
		_request_close.call_deferred()
	elif removed_id == device_id:
		_writeln("Connection lost: device was removed.", T.ERROR)
		_exit_ssh_session("Returned to local shell.")


func _on_device_power_changed(dev, _powered_on: bool) -> void:
	if dev and dev.id == device_id:
		_refresh_status()
		if not dev.is_powered_on:
			_writeln("This device was powered off.", T.WARN)
		else:
			_writeln("This device was powered on.", T.MUTE)


# ----------------------------------------------------------------------------
# Regex (compiled once)
# ----------------------------------------------------------------------------

static func _ip_regex() -> RegEx:
	if _re_ip == null:
		_re_ip = RegEx.create_from_string("\\b\\d{1,3}(?:\\.\\d{1,3}){3}(?:/\\d{1,2})?\\b")
	return _re_ip


static func _prompt_regex() -> RegEx:
	if _re_prompt == null:
		_re_prompt = RegEx.create_from_string("^(.+?)@(.+?):(.*?)([#$])$")
	return _re_prompt


static func _diag_regex() -> RegEx:
	if _re_diag == null:
		_re_diag = RegEx.create_from_string("^[A-Za-z0-9_.\\-]+: ")
	return _re_diag
