extends Node
## Shows one-shot hints as toasts in the bottom-right corner.
## Closing a hint with × saves the dismissal to user://hints.cfg -
## a dismissed hint NEVER appears again.

const SAVE_PATH := "user://hints.cfg"
const LAYER_NUM := 100

## Ordered hint list. `check` is evaluated every second while a workspace
## is open; the first hint whose check passes and which is neither dismissed
## nor already shown this session becomes visible.
const HINTS := [
	{
		"id": "welcome",
		"text": "Welcome to DCLab! Drag a device from the Device Library onto the canvas to get started.",
		"check": "no_devices",
	},
	{
		"id": "connect",
		"text": "Select a device and press C, then click a second device to connect them. Or use the Connector tool in the Tools panel.",
		"check": "has_devices_no_links",
	},
	{
		"id": "terminal",
		"text": "Double-click a PC or Server to open its terminal. Type help to see all commands.",
		"check": "has_links",
	},
	{
		"id": "tools",
		"text": "Tools panel (right side): Pointer (V) selects and moves, Connector (C) cables devices, Delete (X) removes them.",
		"check": "has_links",
	},
	{
		"id": "simulate",
		"text": "Press Play in the toolbar (Simulation > Start) to run the network and watch packets flow.",
		"check": "has_links",
	},
	{
		"id": "projects",
		"text": "Save your work with Ctrl+S - projects use the .dclabproj format. Help > Instructions has every shortcut.",
		"check": "has_links",
	},
]

var _dismissed: Dictionary = {}
var _shown_this_session: Array = []
var _current_id: String = ""
var _cooldown: float = 8.0
var _elapsed_since_hide: float = 999.0

var _layer: CanvasLayer
var _panel: PanelContainer
var _label: Label
var _close_btn: Button

func _ready() -> void:
	_load_dismissals()
	_build_ui()
	set_process(true)

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = LAYER_NUM
	add_child(_layer)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_panel.anchor_left = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -420
	_panel.offset_top = -110
	_panel.offset_right = -16
	_panel.offset_bottom = -16
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.visible = false
	_layer.add_child(_panel)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#161616")
	sb.border_color = Color("#3291ff")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_panel.add_child(row)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.add_theme_color_override("font_color", Color("#ededed"))
	row.add_child(_label)

	_close_btn = Button.new()
	_close_btn.text = "×"
	_close_btn.tooltip_text = "Dismiss permanently"
	_close_btn.custom_minimum_size = Vector2(26, 26)
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.pressed.connect(_on_close_pressed)
	row.add_child(_close_btn)

func _process(delta: float) -> void:
	if _current_id != "":
		return
	_elapsed_since_hide += delta
	if _elapsed_since_hide < _cooldown:
		return
	if not _workspace_open():
		return
	for hint in HINTS:
		var id: String = hint["id"]
		if _dismissed.has(id) or id in _shown_this_session:
			continue
		if call(hint["check"]):
			_show_hint(id, hint["text"])
			return

func _show_hint(id: String, text: String) -> void:
	_current_id = id
	_label.text = text
	_panel.visible = true

func _on_close_pressed() -> void:
	# Permanent dismissal - saved to disk, never shown again.
	if _current_id != "":
		_dismissed[_current_id] = true
		_save_dismissals()
	_hide_current()

func _hide_current() -> void:
	if _current_id != "" and not _current_id in _shown_this_session:
		_shown_this_session.append(_current_id)
	_current_id = ""
	_panel.visible = false
	_elapsed_since_hide = 0.0

# ----------------------------------------------------------------------------
# Conditions
# ----------------------------------------------------------------------------

func _workspace_open() -> bool:
	return get_tree().get_first_node_in_group("workspace") != null

func _engine():
	return get_node_or_null("/root/SimEngine")

func no_devices() -> bool:
	var e = _engine()
	return e != null and e.get_device_count() == 0

func has_devices_no_links() -> bool:
	var e = _engine()
	return e != null and e.get_device_count() > 0 and e.connections.is_empty()

func has_links() -> bool:
	var e = _engine()
	return e != null and not e.connections.is_empty()

# ----------------------------------------------------------------------------
# Persistence
# ----------------------------------------------------------------------------

func _load_dismissals() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in cfg.get_section_keys("dismissed"):
		_dismissed[key] = true

func _save_dismissals() -> void:
	var cfg := ConfigFile.new()
	for id in _dismissed:
		cfg.set_value("dismissed", id, true)
	cfg.save(SAVE_PATH)
