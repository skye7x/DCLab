extends Control

var _start_screen: Control = null
var _app_container: Control = null
var _workspace: Node2D = null
var _toolbar: Control = null
var _toolbox: Control = null
var _inspector: Control = null
var _bottom_panel: Control = null
var _menu_bar: MenuBar = null
var _is_in_workspace: bool = false

func _ready() -> void:
	_apply_dark_theme()
	show_start_screen()

func _flat_sb(color: Color, radius: int = 3, border_col: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if border_w > 0:
		sb.border_color = border_col
		sb.border_width_left = border_w
		sb.border_width_right = border_w
		sb.border_width_top = border_w
		sb.border_width_bottom = border_w
	return sb

func _apply_dark_theme() -> void:
	var dark_theme = Theme.new()
	dark_theme.default_font_size = 13

	var bg := Color(0.12, 0.12, 0.14)
	var bg_hover := Color(0.17, 0.17, 0.20)
	var bg_pressed := Color(0.09, 0.09, 0.11)
	var border := Color(0.25, 0.26, 0.30)
	var accent := Color(0.30, 0.55, 0.95)
	var text := Color(0.88, 0.88, 0.90)
	var text_dim := Color(0.60, 0.60, 0.65)

	var panel_style = _flat_sb(bg, 4, border, 1)
	dark_theme.set_stylebox("panel", "Panel", panel_style)
	dark_theme.set_stylebox("panel", "PanelContainer", panel_style)
	dark_theme.set_stylebox("panel", "MarginContainer", panel_style)

	var btn_normal = _flat_sb(bg, 3, border, 1)
	btn_normal.content_margin_left = 10
	btn_normal.content_margin_right = 10
	btn_normal.content_margin_top = 4
	btn_normal.content_margin_bottom = 4
	dark_theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = _flat_sb(bg_hover, 3, accent.lightened(0.2), 1)
	btn_hover.content_margin_left = 10
	btn_hover.content_margin_right = 10
	btn_hover.content_margin_top = 4
	btn_hover.content_margin_bottom = 4
	dark_theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed = _flat_sb(bg_pressed, 3, accent, 1)
	btn_pressed.content_margin_left = 10
	btn_pressed.content_margin_right = 10
	btn_pressed.content_margin_top = 4
	btn_pressed.content_margin_bottom = 4
	dark_theme.set_stylebox("pressed", "Button", btn_pressed)

	var btn_focus = StyleBoxFlat.new()
	btn_focus.bg_color = Color.TRANSPARENT
	btn_focus.border_color = accent
	btn_focus.set_border_width_all(1)
	btn_focus.set_corner_radius_all(3)
	dark_theme.set_stylebox("focus", "Button", btn_focus)

	var btn_disabled = _flat_sb(Color(0.10, 0.10, 0.11), 3, Color(0.18, 0.18, 0.20), 1)
	dark_theme.set_stylebox("disabled", "Button", btn_disabled)

	dark_theme.set_color("font_color", "Button", text)
	dark_theme.set_color("font_hover_color", "Button", Color.WHITE)
	dark_theme.set_color("font_pressed_color", "Button", text)
	dark_theme.set_color("font_focus_color", "Button", text)
	dark_theme.set_color("font_disabled_color", "Button", text_dim)

	var line_edit = _flat_sb(Color(0.10, 0.10, 0.12), 3, border, 1)
	line_edit.content_margin_left = 8
	line_edit.content_margin_right = 8
	line_edit.content_margin_top = 4
	line_edit.content_margin_bottom = 4
	dark_theme.set_stylebox("normal", "LineEdit", line_edit)
	var line_edit_focus = _flat_sb(Color(0.10, 0.10, 0.12), 3, accent, 1)
	line_edit_focus.content_margin_left = 8
	line_edit_focus.content_margin_right = 8
	line_edit_focus.content_margin_top = 4
	line_edit_focus.content_margin_bottom = 4
	dark_theme.set_stylebox("focus", "LineEdit", line_edit_focus)
	dark_theme.set_color("font_color", "LineEdit", text)
	dark_theme.set_color("font_placeholder_color", "LineEdit", text_dim)

	var tab_bg = _flat_sb(Color(0.10, 0.10, 0.12), 3)
	dark_theme.set_stylebox("panel", "TabContainer", tab_bg)
	dark_theme.set_stylebox("tab_selected", "TabContainer", _flat_sb(bg, 3, border, 1))
	dark_theme.set_stylebox("tab_unselected", "TabContainer", _flat_sb(Color(0.09, 0.09, 0.10), 3))
	dark_theme.set_color("font_color", "TabContainer", text_dim)
	dark_theme.set_color("font_selected_color", "TabContainer", text)

	var popup_bg = _flat_sb(Color(0.13, 0.13, 0.15), 4, border, 1)
	dark_theme.set_stylebox("panel", "PopupMenu", popup_bg)
	dark_theme.set_stylebox("hover", "PopupMenu", _flat_sb(accent.darkened(0.5), 2))
	dark_theme.set_color("font_color", "PopupMenu", text)
	dark_theme.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	dark_theme.set_stylebox("panel", "TooltipPanel", popup_bg)
	dark_theme.set_color("font_color", "TooltipLabel", text)

	var menu_bg = _flat_sb(bg, 2)
	dark_theme.set_stylebox("panel", "MenuBar", menu_bg)
	dark_theme.set_stylebox("hover", "MenuBar", _flat_sb(bg_hover, 2))
	dark_theme.set_color("font_color", "MenuBar", text)
	dark_theme.set_color("font_hover_color", "MenuBar", Color.WHITE)

	var scroll_bg = StyleBoxEmpty.new()
	dark_theme.set_stylebox("scrollbar", "ScrollBar", scroll_bg)
	dark_theme.set_stylebox("grabber", "HScrollBar", _flat_sb(Color(0.35, 0.35, 0.40), 3))
	dark_theme.set_stylebox("grabber_highlight", "HScrollBar", _flat_sb(accent, 3))
	dark_theme.set_stylebox("grabber", "VScrollBar", _flat_sb(Color(0.35, 0.35, 0.40), 3))
	dark_theme.set_stylebox("grabber_highlight", "VScrollBar", _flat_sb(accent, 3))

	var option_bg = _flat_sb(bg, 3, border, 1)
	option_bg.content_margin_left = 8
	option_bg.content_margin_right = 8
	option_bg.content_margin_top = 3
	option_bg.content_margin_bottom = 3
	dark_theme.set_stylebox("normal", "OptionButton", option_bg)
	dark_theme.set_stylebox("hover", "OptionButton", _flat_sb(bg_hover, 3, accent.lightened(0.2), 1))
	dark_theme.set_stylebox("pressed", "OptionButton", _flat_sb(bg_pressed, 3, accent, 1))
	dark_theme.set_color("font_color", "OptionButton", text)

	dark_theme.set_color("font_color", "Label", text)
	dark_theme.set_color("font_color", "RichTextLabel", text)
	dark_theme.set_color("default_color", "RichTextLabel", text)
	dark_theme.set_color("font_color", "CheckBox", text)
	dark_theme.set_color("font_color", "CheckButton", text)
	dark_theme.set_constant("separation", "VBoxContainer", 4)
	dark_theme.set_constant("separation", "HBoxContainer", 6)

	self.theme = dark_theme

func show_start_screen() -> void:
	for child in get_children():
		child.queue_free()
	
	_is_in_workspace = false
	var start_screen_class = load("res://scenes/start_screen.gd")
	if start_screen_class:
		_start_screen = Control.new()
		_start_screen.set_script(start_screen_class)
		add_child(_start_screen)
		_start_screen.new_project_requested.connect(_on_new_project)
		_start_screen.open_project_requested.connect(_on_open_project)
		_start_screen.open_sample_requested.connect(_on_open_sample)
		_start_screen.set_anchors_preset(15)  # Control.PRESET_FULL_RECT

func show_workspace(project_name: String = "") -> void:
	for child in get_children():
		child.queue_free()
	
	_is_in_workspace = true
	
	_app_container = VBoxContainer.new()
	_app_container.set_anchors_preset(15)  # Control.PRESET_FULL_RECT
	add_child(_app_container)
	
	var top_hbox = HBoxContainer.new()
	_app_container.add_child(top_hbox)
	
	_menu_bar = MenuBar.new()
	_menu_bar.size_flags_horizontal = SIZE_EXPAND_FILL
	top_hbox.add_child(_menu_bar)
	
	var file_menu = PopupMenu.new()
	file_menu.name = "File"
	file_menu.add_item("New Project", 0)
	file_menu.add_item("Open Project", 1)
	file_menu.add_item("Save", 2)
	file_menu.add_item("Save As...", 3)
	file_menu.add_separator()
	file_menu.add_item("Exit", 4)
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	_menu_bar.add_child(file_menu)
	
	var edit_menu = PopupMenu.new()
	edit_menu.name = "Edit"
	edit_menu.add_item("Undo", 0)
	edit_menu.add_item("Redo", 1)
	edit_menu.add_separator()
	edit_menu.add_item("Delete", 2)
	edit_menu.add_item("Select All", 3)
	edit_menu.id_pressed.connect(_on_edit_menu_pressed)
	_menu_bar.add_child(edit_menu)
	
	var view_menu = PopupMenu.new()
	view_menu.name = "View"
	view_menu.add_item("Toggle Grid", 0)
	view_menu.add_item("Toggle Snap to Grid", 1)
	view_menu.add_separator()
	view_menu.add_item("Zoom to Fit", 2)
	view_menu.add_item("Reset View", 3)
	view_menu.id_pressed.connect(_on_view_menu_pressed)
	_menu_bar.add_child(view_menu)
	
	var sim_menu = PopupMenu.new()
	sim_menu.name = "Simulation"
	sim_menu.add_item("Start", 0)
	sim_menu.add_item("Pause", 1)
	sim_menu.add_item("Stop", 2)
	sim_menu.id_pressed.connect(_on_sim_menu_pressed)
	_menu_bar.add_child(sim_menu)
	
	var tools_menu = PopupMenu.new()
	tools_menu.name = "Tools"
	tools_menu.add_item("Subnet Calculator…", 0)
	tools_menu.add_item("Packet Capture…", 1)
	tools_menu.id_pressed.connect(_on_tools_menu_pressed)
	_menu_bar.add_child(tools_menu)
	
	var help_menu = PopupMenu.new()
	help_menu.name = "Help"
	help_menu.add_item("Instructions…", 1)
	help_menu.add_item("About DCLab", 0)
	help_menu.id_pressed.connect(func(id):
		if id == 1:
			_show_instructions()
		else:
			var dlg = AcceptDialog.new()
			dlg.title = "About DCLab"
			dlg.dialog_text = "DCLab - Interactive IT Infrastructure Simulator\nVersion 0.1.0\nEducational sandbox simulation application."
			add_child(dlg)
			dlg.popup_centered()
	)
	_menu_bar.add_child(help_menu)
	
	var toolbar_class = load("res://scenes/panels/toolbar.gd")
	if toolbar_class:
		_toolbar = HBoxContainer.new()
		_toolbar.set_script(toolbar_class)
		_app_container.add_child(_toolbar)
	
	var split_vertical = VSplitContainer.new()
	split_vertical.size_flags_vertical = SIZE_EXPAND_FILL
	_app_container.add_child(split_vertical)
	
	var split_horizontal = HSplitContainer.new()
	split_horizontal.size_flags_vertical = SIZE_EXPAND_FILL
	split_vertical.add_child(split_horizontal)
	
	var toolbox_class = load("res://scenes/panels/toolbox.gd")
	if toolbox_class:
		_toolbox = PanelContainer.new()
		_toolbox.set_script(toolbox_class)
		split_horizontal.add_child(_toolbox)
	
	var split_center_right = HSplitContainer.new()
	split_center_right.size_flags_horizontal = SIZE_EXPAND_FILL
	split_horizontal.add_child(split_center_right)
	
	var viewport_container = SubViewportContainer.new()
	viewport_container.size_flags_horizontal = SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = SIZE_EXPAND_FILL
	viewport_container.stretch = true
	split_center_right.add_child(viewport_container)
	
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1000, 600)
	viewport_container.add_child(viewport)
	
	var workspace_class = load("res://scenes/workspace/workspace.gd")
	if workspace_class:
		_workspace = Node2D.new()
		_workspace.set_script(workspace_class)
		viewport.add_child(_workspace)
	
	if _toolbox:
		_toolbox.set("_workspace_ref", _workspace)

	if _toolbar and "_workspace_ref" in _toolbar:
		_toolbar.set("_workspace_ref", _workspace)
		if _toolbar.has_method("sync_view_buttons"):
			_toolbar.sync_view_buttons()
	
	var inspector_class = load("res://scenes/panels/inspector.gd")
	if inspector_class:
		_inspector = PanelContainer.new()
		_inspector.set_script(inspector_class)
		_inspector.set("_workspace_ref", _workspace)
		split_center_right.add_child(_inspector)
	
	var console_class = load("res://scenes/panels/console_panel.gd")
	if console_class:
		_bottom_panel = PanelContainer.new()
		_bottom_panel.set_script(console_class)
		split_vertical.add_child(_bottom_panel)

func _on_new_project() -> void:
	if ProjectMgr.has_method("new_project"):
		ProjectMgr.new_project("New Project")
	show_workspace("New Project")

func _on_open_project() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	if ProjectMgr.has_method("get_save_directory"):
		dialog.current_dir = ProjectMgr.get_save_directory()
	dialog.add_filter("*.dclabproj", "DCLab Projects")
	dialog.add_filter("*.json", "JSON Projects")
	dialog.file_selected.connect(func(path):
		if ProjectMgr.has_method("load_project"):
			ProjectMgr.load_project(path)
		show_workspace()
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)

func _on_save_project() -> void:
	if ProjectMgr.get("current_path") == null or ProjectMgr.current_path == "":
		_on_save_project_as()
	else:
		if ProjectMgr.has_method("save_project"):
			ProjectMgr.save_project(ProjectMgr.current_path)

func _on_save_project_as() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	if ProjectMgr.has_method("get_save_directory"):
		dialog.current_dir = ProjectMgr.get_save_directory()
	dialog.add_filter("*.dclabproj", "DCLab Projects")
	dialog.add_filter("*.json", "JSON Projects")
	dialog.file_selected.connect(func(path):
		if not path.ends_with(".dclabproj") and not path.ends_with(".json"):
			path += ".dclabproj"
		if ProjectMgr.has_method("save_project"):
			ProjectMgr.save_project(path)
	)
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)

func _on_open_sample() -> void:
	if ProjectMgr.has_method("create_sample_project"):
		var sample = ProjectMgr.create_sample_project()
		var serializer_class = load("res://projects/project_serializer.gd")
		if serializer_class and serializer_class.has_method("deserialize_project"):
			serializer_class.deserialize_project(sample, SimEngine)
		show_workspace("Small Office")

func _on_file_menu_pressed(id: int) -> void:
	match id:
		0: _on_new_project()
		1: _on_open_project()
		2: _on_save_project()
		3: _on_save_project_as()
		4: get_tree().quit()

func _on_edit_menu_pressed(id: int) -> void:
	match id:
		0:
			if ProjectMgr.has_method("undo"): ProjectMgr.undo()
		1:
			if ProjectMgr.has_method("redo"): ProjectMgr.redo()
		2:
			if _workspace and _workspace.has_method("delete_selected"):
				_workspace.delete_selected()
		3:
			if _workspace and _workspace.has_method("select_all"):
				_workspace.select_all()

func _on_view_menu_pressed(id: int) -> void:
	match id:
		0:
			if _workspace and _workspace.has_method("toggle_grid"):
				_workspace.toggle_grid()
				if _toolbar and _toolbar.has_method("sync_view_buttons"):
					_toolbar.sync_view_buttons()
		1:
			if _workspace and _workspace.has_method("toggle_snap"):
				_workspace.toggle_snap()
				if _toolbar and _toolbar.has_method("sync_view_buttons"):
					_toolbar.sync_view_buttons()
		2:
			if _workspace and _workspace.has_method("zoom_to_fit"):
				_workspace.zoom_to_fit()
		3:
			if _workspace and "_camera" in _workspace and _workspace._camera:
				_workspace._camera.reset_view()

func _on_tools_menu_pressed(id: int) -> void:
	match id:
		0:
			var calc_class = load("res://scenes/dialogs/subnet_calculator.gd")
			if calc_class:
				var win = Window.new()
				win.set_script(calc_class)
				get_tree().root.add_child(win)
				win.popup_centered()
		1:
			var cap_class = load("res://scenes/dialogs/packet_capture_dialog.gd")
			if cap_class:
				var win = Window.new()
				win.set_script(cap_class)
				get_tree().root.add_child(win)
				win.popup_centered()

func _on_sim_menu_pressed(id: int) -> void:
	match id:
		0: SimEngine.start_simulation()
		1: SimEngine.pause_simulation()
		2: SimEngine.stop_simulation()

func _show_instructions() -> void:
	var win = Window.new()
	win.title = "DCLab Instructions"
	win.size = Vector2i(680, 560)
	win.min_size = Vector2i(480, 400)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_child(margin)

	var rich = RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.scroll_following = true
	rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich.text = """[b]GETTING STARTED[/b]
1. Click a device in the left [color=#8fb6ff]Device Library[/color], then click on the canvas to place it.
2. Right-click a device for its menu: [i]Configure…, Open Terminal, Configure IP, Connect, Rename, Duplicate, Power, Delete[/i].
3. Save your work via [i]File → Save[/i] — projects use the .dclabproj format.

[b]HOW TO CONNECT TWO DEVICES[/b]
• Right-click a device → [i]Connect[/i], then click the target device. A free interface is picked automatically.
• Or select a device and press the [i]Connect Cable[/i] button in the Inspector (right panel).
• Press [color=#ffcc66]Esc[/color] to cancel a pending connection.

[b]NETWORKING & DHCP[/b]
• Routers run a DHCP server by default. When you cable a PC/NAS to a switch or router, it receives an IP automatically (pool .100–.199).
• Manually set an IP: right-click → [i]Configure IP[/i], or in a terminal: [color=#9fe0a0]ip addr add 192.168.10.50/24 dev eth0[/color].
• Request DHCP from the terminal: [color=#9fe0a0]dhclient eth0[/color].
• Changes made in the terminal appear instantly in the Inspector.

[b]TERMINAL COMMANDS[/b]
[color=#9fe0a0]help[/color]                          — full command list
[color=#9fe0a0]ip[/color] / [color=#9fe0a0]ifconfig[/color]                   — show interfaces; [color=#9fe0a0]ip addr add <ip>/<cidr> dev <iface>[/color]
[color=#9fe0a0]dhclient <iface>[/color]              — request a DHCP address
[color=#9fe0a0]ping <ip> [-c n][/color]              — test connectivity
[color=#9fe0a0]curl http://<ip>/[/color]              — fetch a web page from a server
[color=#9fe0a0]route[/color]                          — routing table (routers)
[color=#9fe0a0]service <name> start|stop[/color]      — manage http/ssh/database
[color=#9fe0a0]ls, cd, cat, mkdir, touch, rm[/color]  — file system
[color=#9fe0a0]shares / share add <name> <MB>[/color]  — NAS shares (on storage devices)
[color=#9fe0a0]df[/color]                            — disk usage
[color=#9fe0a0]Tab[/color]                           — autocomplete, [color=#9fe0a0]↑/↓[/color] history, [color=#9fe0a0]Ctrl+L[/color] clear

[b]NAS / STORAGE[/b]
• Right-click a NAS → [i]Shares…[/i] to create/remove shares; [i]Format…[/i] wipes data.
• Open its terminal for [color=#9fe0a0]shares[/color], [color=#9fe0a0]share[/color], [color=#9fe0a0]df[/color] and normal network commands.

[b]VIEW & SHORTCUTS[/b]
[color=#ffcc66]Mouse wheel[/color] zoom · [color=#ffcc66]Middle-drag / Space+drag[/color] pan
[color=#ffcc66]F[/color] zoom-to-fit · [color=#ffcc66]G[/color] grid · [color=#ffcc66]N[/color] snap · [color=#ffcc66]0[/color] reset view
[color=#ffcc66]Ctrl+A[/color] select all · [color=#ffcc66]Ctrl+Z/Y[/color] undo/redo · [color=#ffcc66]Del[/color] delete
[color=#ffcc66]Esc[/color] cancel connection / placement / deselect"""
	rich.add_theme_font_size_override("normal_font_size", 13)
	margin.add_child(rich)

	var close_btn = Button.new()
	close_btn.text = " Close "
	close_btn.pressed.connect(win.queue_free)
	margin.add_child(close_btn)

	win.close_requested.connect(win.queue_free)
	add_child(win)
	win.popup_centered()

func _process(delta: float) -> void:
	if _is_in_workspace and _toolbar and _toolbar.has_method("update_status"):
		_toolbar.update_status()
