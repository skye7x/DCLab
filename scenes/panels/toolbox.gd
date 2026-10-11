extends PanelContainer

var _workspace_ref = null

const DEVICE_TYPES := ["router", "switch", "firewall", "pc", "server", "storage"]
const CATEGORIES := {
	"NETWORK": ["router", "switch", "firewall"],
	"COMPUTE": ["pc", "server"],
	"STORAGE": ["storage"],
}

class PaletteButton extends Control:
	var device_type: String = ""
	var icon_color: Color = Color.WHITE
	var _pressed: bool = false
	var _hovered: bool = false
	signal pressed

	func _init(p_type: String) -> void:
		device_type = p_type
		var def = DeviceFactory.TYPE_DEFS.get(p_type, {})
		icon_color = def.get("color", Color.WHITE)
		custom_minimum_size = Vector2(0, 40)
		mouse_filter = Control.MOUSE_FILTER_PASS
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(hbox)
		
		var icon = Control.new()
		icon.custom_minimum_size = Vector2(28, 28)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon._draw = _draw_icon.bind(device_type, icon_color)
		hbox.add_child(icon)
		
		var lbl = Label.new()
		lbl.text = str(def.get("label", p_type))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(lbl)

func _draw_icon(device_type: String, icon_color: Color, canvas: CanvasItem) -> void:
	var rect = Rect2(4, 4, 20, 20)
	DevicePictograms.draw_device(canvas, device_type, rect, icon_color, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			update()
		elif _pressed:
			_pressed = false
			update()
			pressed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		update()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		_pressed = false
		update()

func _draw() -> void:
	var bg_color = Color(0.15, 0.15, 0.18, 0.9)
	if _pressed:
		bg_color = Color(0.3, 0.5, 0.8, 0.3)
	elif _hovered:
		bg_color = Color(0.25, 0.25, 0.3, 0.9)
	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.28, 0.35, 0.6), false, 1.0)

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
			var btn = PaletteButton.new(dtype)
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

func _on_palette_pressed(device_type: String) -> void:
	if _workspace_ref and _workspace_ref.has_method("start_placement"):
		_workspace_ref.start_placement(device_type)