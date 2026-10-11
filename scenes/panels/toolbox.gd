extends PanelContainer

## Device library. Click a device, then click the canvas to place it.

var _workspace_ref = null

const CATEGORIES := {
	"NETWORK": ["router", "switch", "firewall"],
	"COMPUTE": ["pc", "server"],
	"STORAGE": ["storage"],
}

const INK := Color("#ededed")
const INK_DIM := Color("#a1a1a1")
const INK_MUTE := Color("#6b6b6b")


## Draws one pictogram. Lives in its own Control so _draw() runs on the right canvas item.
class PictogramIcon extends Control:
	var device_type: String = ""
	var tint: Color = Color.WHITE

	func _init(p_type: String, p_tint: Color, px: float = 24.0) -> void:
		device_type = p_type
		tint = p_tint
		custom_minimum_size = Vector2(px, px)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		DevicePictograms.draw_device(self, device_type, Rect2(Vector2.ZERO, size), tint, true)


## One row in the library: pictogram + label, hover and pressed states.
class PaletteButton extends Control:
	signal pressed

	const INK := Color("#ededed")
	const CARD := Color("#111111")
	const CARD_HOVER := Color("#1a1a1a")
	const CARD_PRESSED := Color("#0a0a0a")
	const HAIRLINE := Color("#2e2e2e")
	const HAIRLINE_HOVER := Color("#4d4d4d")
	const ACCENT := Color("#3291ff")

	var device_type: String = ""
	var _is_down: bool = false
	var _is_hover: bool = false

	func _init(p_type: String) -> void:
		device_type = p_type
		custom_minimum_size = Vector2(0, 44)
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_ALL
		tooltip_text = DeviceFactory.get_label(p_type)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_right", 10)
		add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)

		hbox.add_child(PictogramIcon.new(p_type, DeviceFactory.get_color(p_type), 26.0))

		var lbl := Label.new()
		lbl.text = DeviceFactory.get_label(p_type)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", INK)
		hbox.add_child(lbl)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_down = true
				queue_redraw()
			elif _is_down:
				_is_down = false
				queue_redraw()
				pressed.emit()
		elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			pressed.emit()

	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_MOUSE_ENTER:
				_is_hover = true
				queue_redraw()
			NOTIFICATION_MOUSE_EXIT:
				_is_hover = false
				_is_down = false
				queue_redraw()
			NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT:
				queue_redraw()

	func _draw() -> void:
		var bg := CARD
		var border := HAIRLINE
		if _is_down:
			bg = CARD_PRESSED
			border = ACCENT
		elif _is_hover:
			bg = CARD_HOVER
			border = HAIRLINE_HOVER
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = ACCENT if has_focus() else border
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))


func _ready() -> void:
	custom_minimum_size.x = 200

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "DEVICE LIBRARY"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", INK_DIM)
	vbox.add_child(title)

	var cat_names: Array = CATEGORIES.keys()
	for i in cat_names.size():
		var cat: String = cat_names[i]
		var cat_lbl := Label.new()
		cat_lbl.text = cat
		cat_lbl.add_theme_font_size_override("font_size", 10)
		cat_lbl.add_theme_color_override("font_color", INK_MUTE)
		if i > 0:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 6)
			vbox.add_child(spacer)
		vbox.add_child(cat_lbl)

		for dtype in CATEGORIES[cat]:
			var btn := PaletteButton.new(dtype)
			btn.pressed.connect(_on_palette_pressed.bind(dtype))
			vbox.add_child(btn)

	var hint := Label.new()
	hint.text = "\nClick a device, then click the canvas to place it. Drag to move. Right-click for options. Double-click for a terminal."
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", INK_MUTE)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)


func _on_palette_pressed(device_type: String) -> void:
	if _workspace_ref and _workspace_ref.has_method("start_placement"):
		_workspace_ref.start_placement(device_type)
