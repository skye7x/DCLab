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
	_label.add_theme_color_override("font_color", Color("#ededed"))
	add_child(_label)

	_ip_label = Label.new()
	_ip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ip_label.position = Vector2(-icon_size.x, icon_size.y / 2.0 + 22)
	_ip_label.custom_minimum_size = Vector2(icon_size.x * 2.0, 14)
	_ip_label.add_theme_font_size_override("font_size", 10)
	_ip_label.add_theme_color_override("font_color", Color("#8f8f8f"))
	add_child(_ip_label)

	# Status is drawn as a badge in _draw(); the ColorRect stays for compatibility but is hidden.
	_status_indicator = ColorRect.new()
	_status_indicator.size = Vector2(10, 10)
	_status_indicator.visible = false
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

const CARD := Color("#111111")
const CARD_OFF := Color("#0d0d0d")
const HAIRLINE := Color("#2e2e2e")
const HAIRLINE_HOVER := Color("#4d4d4d")
const ACCENT := Color("#3291ff")
const OK := Color("#50e3c2")
const BAD := Color("#ff4d4d")
const IDLE := Color("#8f8f8f")
const CARD_RADIUS := 10

func _card_style(bg: Color, border: Color, border_w: int, grow: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(CARD_RADIUS + grow)
	sb.anti_aliasing = true
	return sb

func _draw() -> void:
	if not device_ref:
		return

	var base_color: Color = DeviceFactory.get_color(device_ref.device_type)
	if not device_ref.is_enabled:
		base_color = Color(0.4, 0.45, 0.5)

	var card_rect := Rect2(-icon_size / 2.0, icon_size)
	var powered: bool = device_ref.is_powered_on and device_ref.is_enabled

	# Soft drop shadow: one offset card, no heavy blur.
	var shadow := _card_style(Color(0, 0, 0, 0.35), Color.TRANSPARENT, 0)
	draw_style_box(shadow, Rect2(card_rect.position + Vector2(0, 2), card_rect.size))

	# Card: hairline by default, brighter on hover, accent ring when selected.
	var border: Color = HAIRLINE
	var border_w := 1
	if is_selected:
		border = ACCENT
		border_w = 2
	elif is_hovered:
		border = HAIRLINE_HOVER
	draw_style_box(_card_style(CARD if powered else CARD_OFF, border, border_w), card_rect)
	if is_selected:
		var halo := ACCENT
		halo.a = 0.25
		var halo_style := _card_style(Color.TRANSPARENT, halo, 3, 4)
		draw_style_box(halo_style, card_rect.grow(4.0))

	DevicePictograms.draw_device(self, device_ref.device_type, card_rect.grow(-14.0), base_color, powered)

	# Shape + colour status badge so state never relies on colour alone:
	# filled dot = running, hollow ring = off / disabled.
	var dot_pos := Vector2(card_rect.end.x - 9.0, card_rect.position.y + 9.0)
	var status_col: Color = OK if powered else (IDLE if not device_ref.is_enabled else BAD)
	if powered:
		draw_circle(dot_pos, 3.5, status_col)
	else:
		draw_arc(dot_pos, 3.0, 0.0, TAU, 20, status_col, 1.5, true)
