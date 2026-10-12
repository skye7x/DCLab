extends Node2D

signal view_changed(zoom: float)
signal tool_mode_changed(mode: int)

enum ToolMode { POINTER, CONNECTOR, DELETE }

var device_nodes: Dictionary = {}
var connection_lines: Dictionary = {}
var selection: Array = []
var is_connecting: bool = false
var connect_source_device_id: String = ""
var connect_source_iface: String = ""
var tool_mode: int = ToolMode.POINTER
var grid_size: int = 32
var show_grid: bool = true
var snap_to_grid: bool = true

var placement_type: String = ""
var _placement_hint: Label = null

var _is_selecting_rect: bool = false
var _selection_rect_start: Vector2 = Vector2.ZERO
var _camera: CameraController
var _grid_renderer: GridRenderer
var _context_menu: Node

func _ready() -> void:
	name = "Workspace"

	_grid_renderer = GridRenderer.new()
	_grid_renderer.grid_size = grid_size
	add_child(_grid_renderer)

	_camera = CameraController.new()
	add_child(_camera)
	if _camera.has_signal("zoom_changed"):
		_camera.zoom_changed.connect(func(z): view_changed.emit(z))

	var ctx_script = load("res://scenes/dialogs/context_menu_handler.gd")
	if ctx_script:
		_context_menu = Node.new()
		_context_menu.set_script(ctx_script)
		_context_menu._workspace_ref = self
		add_child(_context_menu)

	if EventBus:
		EventBus.device_added.connect(_on_device_added)
		EventBus.device_removed.connect(_on_device_removed)
		EventBus.connection_created.connect(_on_connection_created)
		EventBus.connection_removed.connect(_on_connection_removed)
		EventBus.device_power_changed.connect(_on_device_power_changed)
		EventBus.device_updated.connect(_on_device_updated)

	if SimEngine:
		for dev in SimEngine.get_all_devices():
			add_device_visual(dev)
		for link in SimEngine.connections:
			add_connection_visual(link)

func is_camera_busy() -> bool:
	return _camera != null and (_camera.is_panning() or Input.is_key_pressed(KEY_SPACE))

func get_zoom() -> float:
	return _camera.zoom.x if _camera else 1.0

func _draw() -> void:
	if is_connecting and connect_source_device_id in device_nodes:
		var src_node = device_nodes[connect_source_device_id]
		draw_line(src_node.position, get_global_mouse_position(), Color(1.0, 0.8, 0.2, 0.8), 2.5 / maxf(get_zoom(), 0.2))

	if _is_selecting_rect:
		var rect = Rect2(_selection_rect_start, get_global_mouse_position() - _selection_rect_start).abs()
		draw_rect(rect, Color(0.2, 0.5, 0.8, 0.25), true)
		draw_rect(rect, Color(0.3, 0.6, 0.9, 0.8), false, 1.5 / maxf(get_zoom(), 0.2))

	if placement_type != "":
		var ghost_pos = snap_position(get_global_mouse_position())
		var icon_rect = Rect2(ghost_pos - Vector2(36, 36), Vector2(72, 72))
		var col = DeviceFactory.get_color(placement_type)
		var ghost_bg := StyleBoxFlat.new()
		ghost_bg.bg_color = Color(0.067, 0.067, 0.067, 0.7)
		ghost_bg.border_color = Color(0.196, 0.569, 1.0, 0.9)
		ghost_bg.set_border_width_all(1)
		ghost_bg.set_corner_radius_all(10)
		ghost_bg.anti_aliasing = true
		draw_style_box(ghost_bg, icon_rect)
		DevicePictograms.draw_device(self, placement_type, icon_rect.grow(-14.0), col, true)

func _input(event: InputEvent) -> void:
	if is_camera_busy():
		if _is_selecting_rect:
			_is_selecting_rect = false
			queue_redraw()
		return

	if event is InputEventMouseMotion:
		if is_connecting or _is_selecting_rect or placement_type != "":
			queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if placement_type != "":
					place_at(get_global_mouse_position())
					return
				var clicked_dev_id = get_device_at_position(get_global_mouse_position())
				if is_connecting:
					if clicked_dev_id != "" and clicked_dev_id != connect_source_device_id:
						var dst_dev = SimEngine.get_device(clicked_dev_id)
						if dst_dev:
							var free_iface = _find_free_interface(dst_dev)
							if free_iface != "":
								complete_connection(clicked_dev_id, free_iface)
							else:
								cancel_connection()
					else:
						cancel_connection()
				elif tool_mode == ToolMode.CONNECTOR and clicked_dev_id != "":
					_begin_connect_from_device(clicked_dev_id)
				elif tool_mode == ToolMode.DELETE and clicked_dev_id != "":
					_delete_device_at(clicked_dev_id)
				elif clicked_dev_id == "" and tool_mode == ToolMode.POINTER:
					# Check if clicking near a connection line → open link config
					var link_at = get_link_at_position(get_global_mouse_position())
					if link_at:
						_open_link_config(link_at.id)
						return
					if not Input.is_key_pressed(KEY_SHIFT) and not Input.is_key_pressed(KEY_CTRL):
						clear_selection()
					_is_selecting_rect = true
					_selection_rect_start = get_global_mouse_position()
			else:
				if _is_selecting_rect:
					_is_selecting_rect = false
					_apply_rect_selection(Rect2(_selection_rect_start, get_global_mouse_position() - _selection_rect_start).abs())
					queue_redraw()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if placement_type != "":
				cancel_placement()
			elif is_connecting:
				cancel_connection()
			else:
				var clicked_dev_id = get_device_at_position(get_global_mouse_position())
				if _context_menu:
					if clicked_dev_id != "":
						select_device(clicked_dev_id)
						_context_menu.show_device_menu(clicked_dev_id, event.global_position)
					else:
						_context_menu.show_workspace_menu(event.global_position)

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			delete_selected()
		elif event.keycode == KEY_A and event.ctrl_pressed:
			select_all()
		elif event.keycode == KEY_Z and event.ctrl_pressed:
			if ProjectMgr: ProjectMgr.undo()
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			if ProjectMgr: ProjectMgr.redo()
		elif event.keycode == KEY_F and not event.ctrl_pressed:
			zoom_to_fit()
		elif event.keycode == KEY_G and not event.ctrl_pressed:
			toggle_grid()
		elif event.keycode == KEY_N and not event.ctrl_pressed:
			toggle_snap()
		elif event.keycode == KEY_C and not event.ctrl_pressed:
			_handle_connect_key()
		elif event.keycode == KEY_V and not event.ctrl_pressed:
			set_tool_mode(ToolMode.POINTER)
		elif event.keycode == KEY_X and not event.ctrl_pressed:
			set_tool_mode(ToolMode.DELETE)
		elif event.keycode == KEY_F11:
			toggle_fullscreen()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			if ProjectMgr: ProjectMgr.save_project()
		elif event.keycode == KEY_O and event.ctrl_pressed:
			_open_load_project_dialog()
		elif event.keycode == KEY_D and event.ctrl_pressed:
			delete_selected()
		elif event.keycode == KEY_L and event.ctrl_pressed:
			toggle_logs_visibility()
		elif event.keycode == KEY_T and event.ctrl_pressed:
			if selection.size() == 1:
				var dev_id = selection[0]
				var dev = SimEngine.get_device(dev_id) if SimEngine else null
				if dev and (dev is Computer or dev is StorageDevice):
					var term_class = load("res://scenes/terminal/terminal_window.gd")
					if term_class:
						var win = Window.new()
						win.set_script(term_class)
						get_tree().root.add_child(win)
						if win.has_method("setup"): win.setup(dev_id)
						win.popup_centered()
		elif event.keycode == KEY_ESCAPE:
			if placement_type != "":
				cancel_placement()
			elif is_connecting:
				cancel_connection()
			elif tool_mode != ToolMode.POINTER:
				set_tool_mode(ToolMode.POINTER)
			else:
				clear_selection()

func _find_free_interface(dev: Device) -> String:
	for iface in dev.network_interfaces.values():
		if not iface.is_linked:
			return iface.iface_name
	# If none free, add one if allowed
	if dev is SwitchDevice:
		var port_num = dev.network_interfaces.size() + 1
		var pname = "port%d" % port_num
		dev.add_interface(pname)
		return pname
	elif dev is RouterDevice:
		var ifname = "eth%d" % dev.network_interfaces.size()
		dev.add_interface(ifname)
		return ifname
	return ""

func add_device_visual(device: Device) -> void:
	if device.id in device_nodes:
		return
	var DeviceNodeScript = load("res://scenes/devices/device_node.gd")
	if not DeviceNodeScript: return
	var d_node = DeviceNodeScript.new()
	add_child(d_node)
	d_node.setup(device)

	d_node.device_clicked.connect(_on_device_node_clicked)
	d_node.device_drag_ended.connect(_on_device_node_drag_ended)
	d_node.device_double_clicked.connect(_on_device_node_double_clicked)
	device_nodes[device.id] = d_node

func remove_device_visual(device_id: String) -> void:
	if device_id in device_nodes:
		var node = device_nodes[device_id]
		device_nodes.erase(device_id)
		node.queue_free()

func add_connection_visual(link: EthernetLink) -> void:
	if link.id in connection_lines:
		return
	var ConnLineScript = load("res://scenes/connections/connection_line.gd")
	if not ConnLineScript: return

	var c_line = ConnLineScript.new()
	add_child(c_line)
	move_child(c_line, 1) # Behind devices, in front of grid

	var src_node = device_nodes.get(link.source_device_id)
	var dst_node = device_nodes.get(link.dest_device_id)

	if src_node and dst_node:
		c_line.setup(link, src_node, dst_node)
		connection_lines[link.id] = c_line

func remove_connection_visual(link_id: String) -> void:
	if link_id in connection_lines:
		var c = connection_lines[link_id]
		connection_lines.erase(link_id)
		c.queue_free()

func update_connection_positions() -> void:
	for line in connection_lines.values():
		line.update_positions()

func select_device(device_id: String, add_to_selection: bool = false) -> void:
	if not add_to_selection:
		clear_selection()

	if device_id not in selection and device_id in device_nodes:
		selection.append(device_id)
		device_nodes[device_id].set_selected(true)
		if EventBus:
			var dev = SimEngine.get_device(device_id) if SimEngine else null
			EventBus.device_selected.emit(dev if dev else device_id)

func deselect_device(device_id: String) -> void:
	if device_id in selection:
		selection.erase(device_id)
		if device_id in device_nodes:
			device_nodes[device_id].set_selected(false)
		if EventBus:
			EventBus.device_deselected.emit(device_id)

func clear_selection() -> void:
	for id in selection:
		if id in device_nodes:
			device_nodes[id].set_selected(false)
	selection.clear()
	if EventBus:
		EventBus.selection_cleared.emit()

func select_all() -> void:
	for id in device_nodes.keys():
		select_device(id, true)

func _apply_rect_selection(rect: Rect2) -> void:
	for id in device_nodes:
		var node = device_nodes[id]
		if rect.has_point(node.position):
			select_device(id, true)

func delete_selected() -> void:
	var to_remove = selection.duplicate()
	clear_selection()
	var cmd_hist = load("res://commands/command_history.gd")
	for id in to_remove:
		var dev = SimEngine.get_device(id) if SimEngine else null
		if dev and cmd_hist and cmd_hist.RemoveDeviceCommand:
			var conns = SimEngine.get_connections_for_device(id) if SimEngine else []
			ProjectMgr.execute_command(cmd_hist.RemoveDeviceCommand.new(dev, conns))
		elif SimEngine:
			SimEngine.remove_device(id)

func snap_position(pos: Vector2) -> Vector2:
	if snap_to_grid and grid_size > 0:
		return Vector2(
			round(pos.x / grid_size) * grid_size,
			round(pos.y / grid_size) * grid_size
		)
	return pos

func toggle_snap() -> bool:
	snap_to_grid = not snap_to_grid
	return snap_to_grid

func toggle_grid() -> bool:
	show_grid = not show_grid
	if _grid_renderer:
		_grid_renderer.visible_grid = show_grid
	return show_grid

func start_connection(device_id: String, iface_name: String) -> void:
	is_connecting = true
	connect_source_device_id = device_id
	connect_source_iface = iface_name
	queue_redraw()

func set_tool_mode(mode: int) -> void:
	if tool_mode == mode:
		return
	tool_mode = mode
	if mode != ToolMode.CONNECTOR and is_connecting:
		cancel_connection()
	_set_cursor_for_mode()
	if EventBus and EventBus.has_signal("tool_mode_changed"):
		EventBus.tool_mode_changed.emit(mode)
	queue_redraw()

func get_tool_mode() -> int:
	return tool_mode

func is_pointer_mode() -> bool:
	return tool_mode == ToolMode.POINTER

func _set_cursor_for_mode() -> void:
	var shape := Input.CURSOR_ARROW
	match tool_mode:
		ToolMode.CONNECTOR:
			shape = Input.CURSOR_CROSS
		ToolMode.DELETE:
			shape = Input.CURSOR_FORBIDDEN
		_:
			shape = Input.CURSOR_ARROW
	Input.set_default_cursor_shape(shape)

func _handle_connect_key() -> void:
	# Press C: if a connection is pending, cancel it; otherwise start one
	# from the currently selected device, then pick a target by clicking it.
	if is_connecting:
		cancel_connection()
		return
	if selection.is_empty():
		return
	var dev_id: String = selection[0]
	var dev = SimEngine.get_device(dev_id) if SimEngine else null
	if not dev:
		return
	_begin_connect_from_device(dev_id)

func _begin_connect_from_device(dev_id: String) -> void:
	var dev = SimEngine.get_device(dev_id) if SimEngine else null
	if not dev:
		return
	var iface := _find_free_interface(dev)
	if iface == "":
		# No free port and device can't grow ports - fall back to first iface.
		if dev.network_interfaces.size() > 0:
			iface = dev.network_interfaces.values()[0].iface_name
		else:
			return
	select_device(dev_id)
	start_connection(dev_id, iface)

func _delete_device_at(dev_id: String) -> void:
	if dev_id in selection:
		deselect_device(dev_id)
	var dev = SimEngine.get_device(dev_id) if SimEngine else null
	if not dev:
		return
	var cmd_hist = load("res://commands/command_history.gd")
	if cmd_hist and cmd_hist.RemoveDeviceCommand:
		var conns = SimEngine.get_connections_for_device(dev_id) if SimEngine else []
		ProjectMgr.execute_command(cmd_hist.RemoveDeviceCommand.new(dev, conns))
	elif SimEngine:
		SimEngine.remove_device(dev_id)

func toggle_fullscreen() -> void:
	var win = get_tree().get_root() as Window
	if not win:
		return
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN

func complete_connection(dest_device_id: String, dest_iface_name: String) -> void:
	if is_connecting and SimEngine:
		var cmd_hist = load("res://commands/command_history.gd")
		var link = SimEngine.create_connection(connect_source_device_id, connect_source_iface, dest_device_id, dest_iface_name)
		if link and cmd_hist and cmd_hist.AddConnectionCommand:
			# Command history tracking
			pass
	cancel_connection()

func cancel_connection() -> void:
	is_connecting = false
	connect_source_device_id = ""
	connect_source_iface = ""
	queue_redraw()

func start_placement(device_type: String) -> void:
	placement_type = device_type
	cancel_connection()
	queue_redraw()

func cancel_placement() -> void:
	placement_type = ""
	queue_redraw()

func place_at(world_pos: Vector2) -> void:
	if placement_type == "" or not SimEngine:
		return
	var dtype = placement_type
	cancel_placement()
	var dev_id = SimEngine.generate_id()
	var device: Device = DeviceFactory.create(dtype, dev_id)
	if not device:
		return
	device.position = snap_position(world_pos)
	var cmd_hist = load("res://commands/command_history.gd")
	if cmd_hist and cmd_hist.AddDeviceCommand:
		ProjectMgr.execute_command(cmd_hist.AddDeviceCommand.new(device))
	else:
		SimEngine.add_device(device)

func get_device_at_position(pos: Vector2) -> String:
	for id in device_nodes:
		var node = device_nodes[id]
		var hit_rect = Rect2(node.position - node.icon_size / 2.0, node.icon_size)
		if hit_rect.has_point(pos):
			return id
	return ""

func get_link_at_position(pos: Vector2, max_dist: float = 12.0):
	var best_link = null
	var best_dist = max_dist
	for link_id in connection_lines:
		var cline = connection_lines[link_id]
		if not cline or cline.get_point_count() < 2:
			continue
		var a = cline.get_point_position(0)
		var b = cline.get_point_position(1)
		var d = _dist_point_to_segment(pos, a, b)
		if d < best_dist:
			best_dist = d
			best_link = cline.link_ref
	return best_link

func _dist_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var len_sq = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _open_link_config(link_id: String) -> void:
	var dlg_class = load("res://scenes/dialogs/link_config_dialog.gd")
	if not dlg_class:
		return
	var win = Window.new()
	win.set_script(dlg_class)
	get_tree().root.add_child(win)
	if win.has_method("setup"):
		win.setup(link_id)
	win.popup_centered()

func auto_layout() -> void:
	if SimEngine.get_device_count() == 0:
		return
	# Layered layout by device type: routers top, switches below, then endpoints
	var layers: Dictionary = {
		"router": [],
		"firewall": [],
		"switch": [],
		"server": [],
		"storage": [],
		"pc": [],
		"generic": []
	}
	for dev in SimEngine.get_all_devices():
		var t = dev.device_type
		if not layers.has(t):
			t = "generic"
		layers[t].append(dev)
	var layer_order = ["router", "firewall", "switch", "server", "storage", "pc", "generic"]
	var y = 200.0
	var x_spacing = 220.0
	for layer_type in layer_order:
		var devs = layers[layer_type]
		if devs.is_empty():
			continue
		var total_w = (devs.size() - 1) * x_spacing
		var x = -total_w / 2.0
		for dev in devs:
			dev.position = Vector2(x, y)
			if device_nodes.has(dev.id):
				device_nodes[dev.id].position = dev.position
			x += x_spacing
		y += 180.0
	# Refresh connection lines
	for link_id in connection_lines:
		var cline = connection_lines[link_id]
		if cline:
			cline.update_positions()
	zoom_to_fit()

func zoom_to_fit() -> void:
	if device_nodes.is_empty():
		if _camera:
			_camera.reset_view()
		return
	var rect: Rect2
	var first = true
	for id in device_nodes:
		var pos = device_nodes[id].position
		if first:
			rect = Rect2(pos, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(pos)
	if _camera and _camera.has_method("fit_to_rect"):
		_camera.fit_to_rect(rect.grow(160.0))
		view_changed.emit(get_zoom())

func get_view_center() -> Vector2:
	return _camera.position if _camera else Vector2.ZERO

func _on_device_added(device) -> void:
	add_device_visual(device)

func _on_device_removed(device_id: String) -> void:
	remove_device_visual(device_id)

func _on_connection_created(link) -> void:
	add_connection_visual(link)

func _on_connection_removed(link_id: String) -> void:
	remove_connection_visual(link_id)

func _on_device_power_changed(device, _is_on: bool) -> void:
	var dev_id = device.id if "id" in device else str(device)
	if dev_id in device_nodes:
		device_nodes[dev_id].update_visual()

func _on_device_updated(device_id: String) -> void:
	if device_id in device_nodes:
		device_nodes[device_id].update_visual()

func _on_device_node_clicked(device_id: String, event: InputEvent) -> void:
	var add_to_sel = Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_CTRL)
	if not (device_id in selection and not add_to_sel):
		select_device(device_id, add_to_sel)

func _on_device_node_double_clicked(device_id: String) -> void:
	var dev = SimEngine.get_device(device_id) if SimEngine else null
	if dev and (dev is Computer or dev is StorageDevice):
		var term_class = load("res://scenes/terminal/terminal_window.gd")
		if term_class:
			var win = Window.new()
			win.set_script(term_class)
			get_tree().root.add_child(win)
			if win.has_method("setup"):
				win.setup(device_id)
			win.popup_centered()

func _on_device_node_drag_ended(device_id: String, old_pos: Vector2, new_pos: Vector2) -> void:
	var snapped = snap_position(new_pos)
	if device_id in device_nodes:
		device_nodes[device_id].position = snapped
		var dev = SimEngine.get_device(device_id) if SimEngine else null
		if dev:
			dev.position = snapped

	if ProjectMgr:
		var cmd_hist = load("res://commands/command_history.gd")
		if cmd_hist and cmd_hist.MoveDeviceCommand:
			ProjectMgr.execute_command(cmd_hist.MoveDeviceCommand.new(device_id, old_pos, snapped))

	if EventBus:
		EventBus.device_moved.emit(device_id, snapped)
	update_connection_positions()

func toggle_logs_visibility() -> void:
	if EventBus:
		EventBus.logs_visibility_toggled.emit()

func _on_logs_visibility_toggled(visible: bool) -> void:
	# Forward to any log panels or inspector panels
	pass

func _open_load_project_dialog() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "Load Project"
	dialog.filters = ["*.dclab : DCLab Project Files"]
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_selected.connect(_on_project_file_selected)
	add_child(dialog)
	dialog.popup_centered()

func _on_project_file_selected(path: String) -> void:
	if ProjectMgr:
		ProjectMgr.load_project(path)
