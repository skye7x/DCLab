extends PanelContainer

var _workspace_ref = null

const DEVICE_TYPES := ["router", "switch", "firewall", "pc", "server", "storage"]
const CATEGORIES := {
	"NETWORK": ["router", "switch", "firewall"],
	"COMPUTE": ["pc", "server"],
	"STORAGE": ["storage"],
}

class PaletteButton extends Button:
	var device_type: String = ""
	var icon_color: Color = Color.WHITE

	func _init(p_type: String) -> void:
		device_type = p_type
		var def = DeviceFactory.TYPE_DEFS.get(p_type, {})
		text = str(def.get("label", p_type))
		icon_color = def.get("color", Color.WHITE)
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		custom_minimum_size = Vector2(0, 34)
		tooltip_text = "Click, then click on the canvas to place a " + text

	func _draw() -> void:
		var icon_rect = Rect2(6, (size.y - 20.0) / 2.0, 20, 20)
		DevicePictograms.draw_device(self, device_type, icon_rect, icon_color, true)

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
