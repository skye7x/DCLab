extends Control

const AppInfo = preload("res://core/app_info.gd")

signal new_project_requested()
signal open_project_requested()
signal open_sample_requested()
signal instructions_requested()

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color("#0a0a0a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Subtle vignette-ish accent bar at top
	var accent_bar = ColorRect.new()
	accent_bar.color = Color("#3291ff")
	accent_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	accent_bar.custom_minimum_size.y = 3
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accent_bar)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#111111")
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.border_color = Color("#2e2e2e")
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 32
	sb.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 400
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var title = Label.new()
	title.text = "DCLab"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#ededed"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle = Label.new()
	subtitle.text = "Interactive IT Infrastructure Simulator"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#a1a1a1"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	vbox.add_child(_spacer(26))

	vbox.add_child(_section_label("PROJECTS"))
	var btn_new = _make_btn("New Project", "file_new", "Create an empty project")
	btn_new.pressed.connect(func(): new_project_requested.emit())
	vbox.add_child(btn_new)
	var btn_open = _make_btn("Open Project…", "folder", "Open a saved .dclabproj file")
	btn_open.pressed.connect(func(): open_project_requested.emit())
	vbox.add_child(btn_open)

	vbox.add_child(_spacer(14))

	vbox.add_child(_section_label("SAMPLES"))
	var btn_sample = _make_btn("Small Office", "topology", "Load the built-in sample topology")
	btn_sample.pressed.connect(func(): open_sample_requested.emit())
	vbox.add_child(btn_sample)

	vbox.add_child(_spacer(14))

	vbox.add_child(_section_label("LEARN"))
	var btn_instr = _make_btn("Instructions", "instructions", "Every shortcut, tool and terminal command")
	btn_instr.pressed.connect(func(): instructions_requested.emit())
	vbox.add_child(btn_instr)

	vbox.add_child(_spacer(20))

	var version = Label.new()
	version.text = AppInfo.display_version()
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", Color("#6b6b6b"))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(version)

func _spacer(h: float) -> Control:
	var c = Control.new()
	c.custom_minimum_size.y = h
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _section_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color("#8f8f8f"))
	return l

func _make_btn(text: String, icon_name: String, tip: String) -> Button:
	var b = Button.new()
	var tex = load("res://resIcons/%s.svg" % icon_name)
	if tex:
		b.icon = tex
	b.text = text
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(0, 40)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("icon_separation", 10)
	return b
