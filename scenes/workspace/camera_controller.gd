extends Camera2D
class_name CameraController

signal zoom_changed(new_zoom: float)

var zoom_speed: float = 1.12
var min_zoom: float = 0.15
var max_zoom: float = 6.0
var pan_button: int = MOUSE_BUTTON_MIDDLE

var _is_panning: bool = false
var _is_space_pressed: bool = false

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 14.0
	make_current()

func is_panning() -> bool:
	return _is_panning

func zoom_at_cursor(zoom_in_flag: bool) -> void:
	var factor = zoom_speed if zoom_in_flag else (1.0 / zoom_speed)
	set_zoom_level(zoom.x * factor, get_viewport().get_mouse_position())

func set_zoom_level(new_zoom: float, screen_anchor: Vector2 = Vector2(-1, -1)) -> void:
	var new_zoom_val = clampf(new_zoom, min_zoom, max_zoom)
	if is_equal_approx(new_zoom_val, zoom.x):
		return

	# Keep the world point under the screen anchor stationary while zooming.
	var vp := get_viewport()
	var anchor := screen_anchor
	if anchor.x < 0.0:
		anchor = vp.get_visible_rect().size * 0.5

	var before := vp.get_canvas_transform().affine_inverse() * anchor
	zoom = Vector2(new_zoom_val, new_zoom_val)
	var after := vp.get_canvas_transform().affine_inverse() * anchor
	position += before - after

	zoom_changed.emit(new_zoom_val)

func zoom_in() -> void:
	zoom_at_cursor(true)

func zoom_out() -> void:
	zoom_at_cursor(false)

func zoom_to(level: float) -> void:
	set_zoom_level(level)

func zoom_step(dir: int) -> void:
	set_zoom_level(zoom.x * (zoom_speed if dir > 0 else 1.0 / zoom_speed))

func fit_to_rect(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var vp_size = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var zoom_x = vp_size.x / max(rect.size.x, 100.0)
	var zoom_y = vp_size.y / max(rect.size.y, 100.0)
	set_zoom_level(min(zoom_x, zoom_y) * 0.85)
	position = rect.get_center()
	reset_smoothing()

func reset_view() -> void:
	set_zoom_level(1.0)
	position = Vector2.ZERO
	reset_smoothing()

func pan_by(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE:
			_is_space_pressed = event.pressed
			if not event.pressed and _is_panning:
				_is_panning = false
				_set_cursor(false)
			elif event.pressed:
				_set_cursor(true)
		elif event.pressed and not event.echo:
			var step := 64.0 / zoom.x
			match event.keycode:
				KEY_LEFT: pan_by(Vector2(-step, 0))
				KEY_RIGHT: pan_by(Vector2(step, 0))
				KEY_UP: pan_by(Vector2(0, -step))
				KEY_DOWN: pan_by(Vector2(0, step))
				KEY_EQUAL, KEY_KP_ADD: zoom_in()
				KEY_MINUS, KEY_KP_SUBTRACT: zoom_out()
				KEY_0, KEY_KP_0: reset_view()

	elif event is InputEventMouseButton:
		var want_pan: bool = event.button_index == pan_button or (event.button_index == MOUSE_BUTTON_LEFT and _is_space_pressed)
		if want_pan:
			_is_panning = event.pressed
			_set_cursor(_is_panning)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at_cursor(true)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at_cursor(false)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _is_panning:
		pan_by(event.relative)
		get_viewport().set_input_as_handled()

func _set_cursor(panning: bool) -> void:
	if panning:
		Input.set_default_cursor_shape(Input.CURSOR_MOVE)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
