extends RefCounted
## Design tokens + Theme for the DCLab terminal.
##
## Language: Vercel / Geist, dark. A near-black canvas, 1px hairlines instead of
## fills, one text ladder (ink > body > mute) and a single blue accent.
## Colour carries meaning only: blue = addresses / paths / focus, red = error,
## amber = warning, teal = ok. Values match the palette in AUDIT.md.
##
## Everything here is static; nothing needs to be instanced.

# --- Surfaces ---------------------------------------------------------------
const CANVAS := Color("#0a0a0a")
const SURFACE := Color("#111111")
const RAISED := Color("#1a1a1a")
const HAIRLINE := Color("#2e2e2e")
const HAIRLINE_STRONG := Color("#454545")

# --- Text ladder (contrast on CANVAS: ink 16:1, out 12:1, body 7.6:1, mute 6:1) ---
const INK := Color("#ededed")
const OUT := Color("#d4d4d4")
const BODY := Color("#a1a1a1")
const MUTE := Color("#8f8f8f")
const FAINT := Color("#6b6b6b")   # decorative only (separators, prompt symbol)

# --- Signal colours ---------------------------------------------------------
const ACCENT := Color("#3291ff")
const ERROR := Color("#ff5c5c")
const WARN := Color("#f5a623")
const OK := Color("#50e3c2")

# --- Type -------------------------------------------------------------------
const FONT_SIZE := 13
const FONT_SIZE_SMALL := 11
const FONT_SIZE_UI := 12
const TITLE_HEIGHT := 32

## Preferred monospace families, first match wins. Geist Mono is used when
## installed; the rest are what ships on Windows / macOS / Linux.
const MONO_FAMILIES := [
	"Geist Mono", "JetBrains Mono", "Cascadia Mono", "Cascadia Code", "SF Mono",
	"Menlo", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono",
	"Courier New", "monospace",
]
## Drop these files into the project to bundle Geist Mono; picked up automatically.
const BUNDLED_REGULAR := "res://assets/fonts/GeistMono-Regular.ttf"
const BUNDLED_BOLD := "res://assets/fonts/GeistMono-SemiBold.ttf"

static var _fonts: Dictionary = {}


static func mono(bold: bool = false) -> Font:
	if _fonts.has(bold):
		return _fonts[bold]
	var font: Font = null
	var bundled: String = BUNDLED_BOLD if bold else BUNDLED_REGULAR
	if ResourceLoader.exists(bundled):
		font = load(bundled) as Font
	if font == null:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(MONO_FAMILIES)
		sf.font_weight = 700 if bold else 400
		sf.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		sf.hinting = TextServer.HINTING_LIGHT
		sf.allow_system_fallback = true
		font = sf
	_fonts[bold] = font
	return font


static var _icons: Dictionary = {}


## A thin anti-aliased "x" (two line segments, rasterised once). Godot's built-in
## close icon is a heavy white cross that fights the hairline look.
static func close_icon(color: Color, px: int = 10) -> Texture2D:
	var key := "%d_%s" % [px, color.to_html()]
	if _icons.has(key):
		return _icons[key]
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var lo := 2.5
	var hi := float(px) - 2.5
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var d1 := Geometry2D.get_closest_point_to_segment(p, Vector2(lo, lo), Vector2(hi, hi)).distance_to(p)
			var d2 := Geometry2D.get_closest_point_to_segment(p, Vector2(lo, hi), Vector2(hi, lo)).distance_to(p)
			var coverage := clampf(0.5 + (0.7 - minf(d1, d2)), 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * coverage))
	var tex := ImageTexture.create_from_image(img)
	_icons[key] = tex
	return tex


static func fade(c: Color, alpha: float) -> Color:
	return Color(c.r, c.g, c.b, alpha)


## StyleBoxFlat shortcut. `border` and `margin` are (left, top, right, bottom).
static func flat(bg: Color, radius: int = 0, border_color: Color = Color(0, 0, 0, 0),
		border: Vector4 = Vector4.ZERO, margin: Vector4 = Vector4.ZERO) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border_color
	sb.border_width_left = int(border.x)
	sb.border_width_top = int(border.y)
	sb.border_width_right = int(border.z)
	sb.border_width_bottom = int(border.w)
	sb.content_margin_left = margin.x
	sb.content_margin_top = margin.y
	sb.content_margin_right = margin.z
	sb.content_margin_bottom = margin.w
	sb.anti_aliasing = radius > 0
	return sb


static func style_label(label: Label, color: Color, size: int = FONT_SIZE,
		bold: bool = false, use_mono: bool = true) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	if use_mono:
		label.add_theme_font_override("font", mono(bold))


## One Theme for the whole terminal window. Assigned to the Window node, so every
## control inside inherits it and nothing leaks into the rest of the app.
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE_UI
	var none := StyleBoxEmpty.new()

	# Embedded window frame + title bar. Godot draws this box *outside* the client
	# area, extended by its expand margins: title height on top, border width elsewhere.
	var frame := flat(SURFACE, 0, HAIRLINE, Vector4(1, 1, 1, 1))
	frame.expand_margin_left = 1
	frame.expand_margin_right = 1
	frame.expand_margin_bottom = 1
	frame.expand_margin_top = TITLE_HEIGHT
	var frame_idle := frame.duplicate() as StyleBoxFlat
	frame_idle.border_color = Color("#232323")
	t.set_stylebox("embedded_border", "Window", frame)
	t.set_stylebox("embedded_unfocused_border", "Window", frame_idle)
	t.set_color("title_color", "Window", BODY)
	t.set_constant("title_height", "Window", TITLE_HEIGHT)
	t.set_constant("title_outline_size", "Window", 0)
	t.set_constant("resize_margin", "Window", 5)
	t.set_font_size("title_font_size", "Window", FONT_SIZE_UI)
	t.set_icon("close", "Window", close_icon(BODY, 12))
	t.set_icon("close_pressed", "Window", close_icon(INK, 12))
	t.set_constant("close_h_offset", "Window", 26)
	t.set_constant("close_v_offset", "Window", 22)

	# Ghost buttons (6px radius, hairline) for the chrome row.
	var btn_n := flat(Color(0, 0, 0, 0), 6, HAIRLINE, Vector4(1, 1, 1, 1), Vector4(10, 3, 10, 3))
	var btn_h := flat(RAISED, 6, HAIRLINE_STRONG, Vector4(1, 1, 1, 1), Vector4(10, 3, 10, 3))
	var btn_p := flat(RAISED, 6, BODY, Vector4(1, 1, 1, 1), Vector4(10, 3, 10, 3))
	t.set_stylebox("normal", "Button", btn_n)
	t.set_stylebox("hover", "Button", btn_h)
	t.set_stylebox("pressed", "Button", btn_p)
	t.set_stylebox("hover_pressed", "Button", btn_p)
	t.set_stylebox("disabled", "Button", btn_n)
	t.set_stylebox("focus", "Button", none)
	t.set_color("font_color", "Button", BODY)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_hover_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", BODY)
	t.set_color("font_disabled_color", "Button", FAINT)
	t.set_font_size("font_size", "Button", FONT_SIZE_UI)

	# Tabs: ink underline on the active one, nothing else.
	var tab_sel := flat(Color(0, 0, 0, 0), 0, INK, Vector4(0, 0, 0, 2), Vector4(12, 7, 12, 5))
	var tab_off := flat(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector4(0, 0, 0, 2), Vector4(12, 7, 12, 5))
	var tab_hov := flat(fade(Color.WHITE, 0.04), 0, Color(0, 0, 0, 0), Vector4(0, 0, 0, 2), Vector4(12, 7, 12, 5))
	t.set_stylebox("tab_selected", "TabBar", tab_sel)
	t.set_stylebox("tab_unselected", "TabBar", tab_off)
	t.set_stylebox("tab_hovered", "TabBar", tab_hov)
	t.set_stylebox("tab_disabled", "TabBar", tab_off)
	t.set_stylebox("tab_focus", "TabBar", none)
	t.set_icon("close", "TabBar", close_icon(MUTE, 10))
	t.set_stylebox("button_pressed", "TabBar", flat(RAISED, 4))
	t.set_stylebox("button_highlight", "TabBar", flat(RAISED, 4))
	t.set_color("font_selected_color", "TabBar", INK)
	t.set_color("font_unselected_color", "TabBar", MUTE)
	t.set_color("font_hovered_color", "TabBar", INK)
	t.set_color("font_disabled_color", "TabBar", FAINT)
	t.set_font_size("font_size", "TabBar", FONT_SIZE_UI)
	t.set_constant("h_separation", "TabBar", 6)
	t.set_constant("outline_size", "TabBar", 0)
	t.set_stylebox("panel", "TabContainer", none)

	# Input + output text.
	t.set_stylebox("normal", "LineEdit", none)
	t.set_stylebox("focus", "LineEdit", none)
	t.set_stylebox("read_only", "LineEdit", none)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", FAINT)
	t.set_color("font_placeholder_color", "LineEdit", FAINT)
	t.set_color("caret_color", "LineEdit", ACCENT)
	t.set_color("selection_color", "LineEdit", fade(ACCENT, 0.35))
	t.set_constant("caret_width", "LineEdit", 2)

	t.set_stylebox("normal", "RichTextLabel", flat(CANVAS, 0, Color(0, 0, 0, 0), Vector4.ZERO, Vector4(14, 10, 8, 10)))
	t.set_stylebox("focus", "RichTextLabel", none)
	t.set_color("default_color", "RichTextLabel", OUT)
	t.set_color("selection_color", "RichTextLabel", fade(ACCENT, 0.35))
	t.set_constant("line_separation", "RichTextLabel", 3)

	# Slim scrollbars.
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, flat(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector4.ZERO, Vector4(3, 3, 3, 3)))
		t.set_stylebox("scroll_focus", bar, flat(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0), Vector4.ZERO, Vector4(3, 3, 3, 3)))
		t.set_stylebox("grabber", bar, flat(HAIRLINE, 3))
		t.set_stylebox("grabber_highlight", bar, flat(HAIRLINE_STRONG, 3))
		t.set_stylebox("grabber_pressed", bar, flat(FAINT, 3))

	# Context menu (right-click on output / input) and tooltips.
	t.set_stylebox("panel", "PopupMenu", flat(SURFACE, 8, HAIRLINE, Vector4(1, 1, 1, 1), Vector4(4, 4, 4, 4)))
	t.set_stylebox("hover", "PopupMenu", flat(RAISED, 4))
	t.set_stylebox("separator", "PopupMenu", flat(HAIRLINE, 0, Color(0, 0, 0, 0), Vector4.ZERO, Vector4(0, 0, 0, 0)))
	t.set_color("font_color", "PopupMenu", BODY)
	t.set_color("font_hover_color", "PopupMenu", INK)
	t.set_color("font_disabled_color", "PopupMenu", FAINT)
	t.set_color("font_accelerator_color", "PopupMenu", FAINT)
	t.set_constant("v_separation", "PopupMenu", 6)
	t.set_font_size("font_size", "PopupMenu", FONT_SIZE_UI)
	t.set_stylebox("panel", "TooltipPanel", flat(RAISED, 6, HAIRLINE_STRONG, Vector4(1, 1, 1, 1), Vector4(8, 5, 8, 5)))
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font_size("font_size", "TooltipLabel", FONT_SIZE_UI)
	return t
