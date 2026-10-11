extends PanelContainer

var _workspace_ref = null

const DEVICE_TYPES := ["router", "switch", "firewall", "pc", "server", "storage"]
const CATEGORIES := {
	"NETWORK": ["router", "switch", "firewall"],
	"COMPUTE": ["pc", "server"],
	"STORAGE": ["storage"],
}

func _ready() -> void:
	custom_minimum_size.x = 190

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "DEVICE LIBRARY"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var cat_names = CATEGORIES.keys()
	for i in range(cat_names.size()):
		var cat = cat_names[i]
		var cat_lbl = Label.new()
		cat_lbl.text = cat
		cat_lbl.add_theme_font_size_override("font_size", 10)
		cat_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		vbox.add_child(cat_lbl)

		for dtype in CATEGORIES[cat]:
			var btn = create_palette_button(dtype)
			btn.pressed.connect(_on_palette_pressed.bind(dtype))
			vbox.add_child(btn)

		if i < cat_names.size() - 1:
			vbox.add_child(HSeparator.new())

	var hint = Label.new()
	hint.text = "\nClick a device, then click on the canvas to place it. Drag devices to move. Right-click a device for options. Double-click for terminal."
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

func create_palette_button(device_type: String) -> Control:
	var def = DeviceFactory.TYPE_DEFS.get(device_type, {})
	var icon_color = def.get("color", Color.WHITE)
	var label_text = str(def.get("label", device_type))

	var btn = Control.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var _pressed = false
	var _hovered = false

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.add_child(hbox)

	var icon = Control.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon._draw = _draw_icon.bind(device_type, icon_color)
	hbox.add_child(icon)

	var lbl = Label.new()
	lbl.text = str(def.get("label", device_type))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lbl)

	btn._pressed = false
	btn._hovered = false

	btn._gui_input = func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				btn._pressed = true
				btn.update()
			elif btn._pressed:
				btn._pressed = false
				btn.update()
				btn.emit_signal("pressed")

	btn._notification = func(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			btn._hovered = true
			btn.update()
		elif what == NOTIFICATION_MOUSE_EXIT:
			btn._hovered = false
			btn._pressed = false
			btn.update()

	btn._draw = func() -> void:
		var bg_color = Color(0.15, 0.15, 0.18, 0.9)
		if btn._pressed:
			bg_color = Color(0.3, 0.5, 0.8, 0.3)
		elif btn._hovered:
			bg_color = Color(0.25, 0.25, 0.3, 0.9)
		draw_rect(Rect2(Vector2.ZERO, btn.size), bg_color, true)
		draw_rect(Rect2(Vector2.ZERO, btn.size), Color(0.25, 0.28, 0.35, 0.6), false, 1.0

	btn._draw_icon = func(device_type: String, icon_color: Color, canvas: CanvasItem) -> void:
		var rect = Rect2(4, 4, 20, 20)
		DevicePictograms.draw_device(canvas, device_type, rect, icon_color, true)

	icon._draw = btn._draw_icon.bind(device_type, icon_color)

	btn.add_user_signal("pressed")
	return btn

func _draw_icon(device_type: String, icon_color: Color, canvas: CanvasItem) -> void:
	var rect = Rect2(4, 4, 20, 20)
	DevicePictograms.draw_device(canvas, device_type, rect, icon_color, true)

func _on_palette_pressed(device_type: String) -> void:
	if _workspace_ref and _workspace_ref.has_method("start_placement"):
		_workspace_ref.start_placement(device_type)