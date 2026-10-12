extends Window
class_name TerminalWindow
## Terminal window: a tab strip on top, one TerminalTab per shell below.
##
## Opened by the workspace, inspector and context menu as
##     win = Window.new(); win.set_script(...); add_child(win); win.setup(id); win.popup_centered()
## The embedded frame (title bar, border) comes from the Window theme in
## terminal_theme.gd; this script only adds the content inside it.

const T := preload("res://scenes/terminal/terminal_theme.gd")
const TabScript := preload("res://scenes/terminal/terminal_tab.gd")

const MAX_TABS := 8
const DEFAULT_SIZE := Vector2i(920, 580)
const MIN_SIZE := Vector2i(560, 360)

var device_id: String = ""

var _bar: TabBar
var _stack: TabContainer
var _logs_btn: Button
var _built: bool = false
var _started: bool = false


func setup(p_device_id: String) -> void:
	device_id = p_device_id
	if _built and not _started:
		_start()


func _ready() -> void:
	title = "Terminal"
	size = DEFAULT_SIZE
	min_size = MIN_SIZE
	unresizable = false
	theme = T.build_theme()
	close_requested.connect(queue_free)
	focus_entered.connect(_focus_current)
	_build_ui()
	_built = true
	if device_id != "":
		_start()


func _start() -> void:
	_started = true
	_add_tab(device_id)
	_focus_current.call_deferred()


# ----------------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------------

func _build_ui() -> void:
	var root := PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_stylebox_override("panel", T.flat(T.CANVAS))
	add_child(root)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	root.add_child(col)

	# Chrome: tabs on the left, actions on the right, hairline underneath.
	var chrome := PanelContainer.new()
	chrome.add_theme_stylebox_override("panel",
		T.flat(T.SURFACE, 0, T.HAIRLINE, Vector4(0, 0, 0, 1), Vector4(8, 4, 8, 0)))
	col.add_child(chrome)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chrome.add_child(row)

	_bar = TabBar.new()
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.focus_mode = Control.FOCUS_NONE
	_bar.clip_tabs = true
	_bar.max_tab_width = 200
	_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	_bar.drag_to_rearrange_enabled = false
	_bar.tab_changed.connect(_on_tab_changed)
	_bar.tab_close_pressed.connect(_close_tab)
	row.add_child(_bar)

	var new_btn := _chrome_button("+", "New tab  (Ctrl+T)")
	new_btn.custom_minimum_size = Vector2(28, 26)
	new_btn.pressed.connect(_new_tab)
	row.add_child(new_btn)

	_logs_btn = _chrome_button("Logs", "Show simulator events for this device in the terminal")
	_logs_btn.toggle_mode = true
	_logs_btn.toggled.connect(_on_logs_toggled)
	row.add_child(_logs_btn)

	_stack = TabContainer.new()
	_stack.tabs_visible = false
	_stack.focus_mode = Control.FOCUS_NONE
	_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_stack)


func _chrome_button(label: String, tip: String) -> Button:
	var b := Button.new()
	b.text = label
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


# ----------------------------------------------------------------------------
# Tabs
# ----------------------------------------------------------------------------

func _add_tab(p_device_id: String) -> void:
	if _stack.get_tab_count() >= MAX_TABS:
		return
	var tab: TerminalTab = TabScript.new()
	_stack.add_child(tab)                       # builds the tab UI (_ready)
	tab.set_logs_enabled(_logs_btn.button_pressed, false)
	tab.title_changed.connect(_on_tab_title_changed.bind(tab))
	tab.prompt_changed.connect(_on_tab_prompt_changed.bind(tab))
	tab.tab_close_requested.connect(_on_tab_close_requested.bind(tab))
	_bar.add_tab(_title_for(p_device_id))
	_bar.current_tab = _stack.get_tab_count() - 1
	tab.setup(p_device_id)                      # connects the shell, prints the banner
	_select(_stack.get_tab_count() - 1)


func _title_for(p_device_id: String) -> String:
	var dev = SimEngine.get_device(p_device_id) if SimEngine else null
	return dev.display_name if dev else p_device_id


func _new_tab() -> void:
	var cur := _current_tab()
	_add_tab(cur.origin_device_id if cur else device_id)


func _current_tab() -> TerminalTab:
	return _stack.get_current_tab_control() as TerminalTab


func _select(index: int) -> void:
	if index < 0 or index >= _stack.get_tab_count():
		return
	_bar.current_tab = index
	_stack.current_tab = index
	_update_title()
	_focus_current.call_deferred()


func _on_tab_changed(index: int) -> void:
	_stack.current_tab = index
	_update_title()
	_focus_current.call_deferred()


func _cycle(step: int) -> void:
	var n := _stack.get_tab_count()
	if n > 1:
		_select((_stack.current_tab + step + n) % n)


func _close_tab(index: int) -> void:
	if index < 0 or index >= _stack.get_tab_count():
		return
	if _stack.get_tab_count() <= 1:
		queue_free()
		return
	var tab := _stack.get_tab_control(index)
	_stack.remove_child(tab)
	tab.queue_free()
	_bar.remove_tab(index)
	_select(clampi(_bar.current_tab, 0, _stack.get_tab_count() - 1))


func _index_of(tab: Control) -> int:
	for i in _stack.get_tab_count():
		if _stack.get_tab_control(i) == tab:
			return i
	return -1


func _on_tab_title_changed(p_title: String, tab: TerminalTab) -> void:
	var i := _index_of(tab)
	if i >= 0:
		_bar.set_tab_title(i, p_title)
	if tab == _current_tab():
		_update_title()


func _on_tab_prompt_changed(_prompt: String, tab: TerminalTab) -> void:
	if tab == _current_tab():
		_update_title()


func _on_tab_close_requested(tab: TerminalTab) -> void:
	var i := _index_of(tab)
	if i >= 0:
		_close_tab(i)


func _update_title() -> void:
	var tab := _current_tab()
	if tab == null:
		return
	var prompt := tab.get_prompt_text()
	title = tab.get_title() if prompt == "" else "%s   %s" % [tab.get_title(), prompt]


func _focus_current() -> void:
	var tab := _current_tab()
	if tab:
		tab.focus_input()


func _on_logs_toggled(on: bool) -> void:
	for i in _stack.get_tab_count():
		(_stack.get_tab_control(i) as TerminalTab).set_logs_enabled(on)
	_focus_current.call_deferred()


# ----------------------------------------------------------------------------
# Shortcuts (handled before the focused LineEdit sees them)
# ----------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k := event as InputEventKey
	if not k.is_command_or_control_pressed():
		return
	match k.keycode:
		KEY_T:
			_new_tab()
		KEY_W:
			if k.shift_pressed:
				queue_free()
			else:
				_close_tab(_stack.current_tab)
		KEY_TAB:
			_cycle(-1 if k.shift_pressed else 1)
		KEY_PAGEUP:
			_cycle(-1)
		KEY_PAGEDOWN:
			_cycle(1)
		_:
			return
	set_input_as_handled()
