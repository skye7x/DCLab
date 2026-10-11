extends Node2D
class_name DeviceNode

var device_id: String = ''
var device_ref = null # type: Device
var is_selected: bool = false
var is_hovered: bool = false
var icon_size: Vector2 = Vector2(72, 72)

var _is_dragging: bool = false
var _drag_start_pos: Vector2
var _drag_offset: Vector2

var _label: Label
var _status_indicator: ColorRect
var _ip_label: Label

signal device_clicked(device_id: String, event: InputEvent)
signal device_drag_started(device_id: String)
signal device_dragged(device_id: String, new_pos: Vector2)
signal device_drag_ended(device_id: String, old_pos: Vector2, new_pos: Vector2)
signal device_double_clicked(device_id: String)
signal connection_requested(device_id: String)

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-icon_size.x, icon_size.y / 2.0 + 4)
	_label.custom_minimum_size = Vector2(icon_size.x * 2.0, 18)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	add_child(_label)

	_ip_label = Label.new()
	_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_label.position = Vector2(-icon_size.x, icon_size.y / 2.0 + 22)
	_ip_label.custom_minimum_size = Vector2(icon_size.x * 2.0, 14)
	_ip_label.add_theme_font_size_override("font_size", 10)
	_ip_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.8))
	add_child(_ip_label)

	_status_indicator = ColorRect.new()
	_status_indicator.size = Vector2(10, 10)
	_status_indicator.position = Vector2(icon_size.x / 2.0 - 12, -icon_size.y / 2.0 + 4)
	add_child(_status_indicator)

func setup(device) -> void:
	device_ref = device
	device_id = device.id
	position = device.position
	update_visual()

func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()

func update_visual() -> void:
	if device_ref:
		_label.text = device_ref.display_name
		_status_indicator.color = Color(0.2, 0.85, 0.3) if device_ref.is_powered_on else Color(0.9, 0.25, 0.25)
		if not device_ref.is_enabled:
			_status_indicator.color = Color(0.5, 0.5, 0.5)

		# Show primary IP if available
		var ip_text = ""
		if "network_interfaces" in device_ref and device_ref.network_interfaces.size() > 0:
			for iface in device_ref.network_interfaces.values():
				if iface.ipv4_address != "":
					ip_text = iface.ipv4_address
					break
		_ip_label.text = ip_text
	queue_redraw()

func _workspace() -> Node:
	var p = get_parent()
	return p if p and "snap_position" in p else null

func _input(event: InputEvent) -> void:
	var ws = _workspace()
	if ws and ws.has_method("is_camera_busy") and ws.is_camera_busy():
		if _is_dragging:
			_finish_drag()
		return

	var mouse_pos = get_global_mouse_position()
	var local_pos = mouse_pos - global_position
	var hit_rect = Rect2(-icon_size / 2.0, icon_size)
	var is_hit = hit_rect.has_point(local_pos)

	if event is InputEventMouseMotion:
		if is_hit != is_hovered:
			is_hovered = is_hit
			queue_redraw()

		if _is_dragging:
			var target_pos = mouse_pos - _drag_offset
			if ws and ws.snap_to_grid:
				target_pos = ws.snap_position(target_pos)
			position = target_pos
			if device_ref:
				device_ref.position = target_pos
			device_dragged.emit(device_id, position)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_hit:
				if event.double_click:
					device_double_clicked.emit(device_id)
				else:
					_is_dragging = true
					_drag_start_pos = position
					_drag_offset = mouse_pos - position
					device_clicked.emit(device_id, event)
					device_drag_started.emit(device_id)
			elif not event.pressed and _is_dragging:
				_finish_drag()

func _finish_drag() -> void:
	_is_dragging = false
	var final_pos = position
	var ws = _workspace()
	if ws and ws.snap_to_grid:
		final_pos = ws.snap_position(final_pos)
	position = final_pos
	if device_ref:
		device_ref.position = final_pos
	device_drag_ended.emit(device_id, _drag_start_pos, final_pos)

func _draw() -> void:
	if not device_ref:
		return

	var base_color = Color(0.22, 0.45, 0.75)
	match device_ref.device_type:
		"router": base_color = Color(0.85, 0.45, 0.2)
		"switch": base_color = Color(0.2, 0.65, 0.6)
		"firewall": base_color = Color(0.8, 0.25, 0.3)
		"server": base_color = Color(0.35, 0.55, 0.85)
		"storage": base_color = Color(0.65, 0.4, 0.75)
		"pc": base_color = Color(0.25, 0.55, 0.8)

	if not device_ref.is_enabled:
		base_color = Color(0.4, 0.45, 0.5)

	var draw_rect = Rect2(-icon_size / 2.0, icon_size)

	# Shadow
	draw_rect(Rect2(draw_rect.position + Vector2(2, 3), draw_rect.size), Color(0, 0, 0, 0.35), true)

	# Background card
	var card_bg = Color(0.1, 0.12, 0.16, 0.92)
	draw_rect(draw_rect, card_bg, true)

	DevicePictograms.draw_device(self, device_ref.device_type, draw_rect.grow(-4.0), base_color, device_ref.is_powered_on)

	if is_selected:
		draw_rect(draw_rect.grow(4.0), Color(0.3, 0.7, 1.0, 0.9), false, 2.5)
		var c_size = 4.0
		var r_exp = draw_rect.grow(4.0)
		draw_rect(Rect2(r_exp.position.x - c_size/2, r_exp.position.y - c_size/2, c_size, c_size), Color.CYAN, true)
		draw_rect(Rect2(r_exp.end.x - c_size/2, r_exp.position.y - c_size/2, c_size, c_size), Color.CYAN, true)
		draw_rect(Rect2(r_exp.position.x - c_size/2, r_exp.end.y - c_size/2, c_size, c_size), Color.CYAN, true)
		draw_rect(Rect2(r_exp.end.x - c_size/2, r_exp.end.y - c_size/2, c_size, c_size), Color.CYAN, true)
	elif is_hovered:
		draw_rect(draw_rect.grow(2.0), Color(0.7, 0.8, 1.0, 0.8), false, 1.5)
	else:
		draw_rect(draw_rect, Color(0.25, 0.28, 0.35, 0.6), false, 1.0)
