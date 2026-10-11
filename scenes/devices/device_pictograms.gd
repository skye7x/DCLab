class_name DevicePictograms
extends RefCounted

## Draws device pictograms from the shape data in PictogramShapes
## (generated from tools/pictograms.json, 24x24 grid, monoline).
##
## One ink colour carries the shape, the device-type colour only tints the
## fill and the small activity dots. Everything scales with `rect`, so the same
## call works for the 20px toolbox icon and the 72px canvas node.

const GRID := 24.0
const STROKE_UNITS := 1.5
const CORNER_SEGMENTS := 6
const ARC_SEGMENTS := 20

const INK := Color("#ededed")
const INK_OFF := Color("#6b6b6b")


static func draw_device(canvas: CanvasItem, device_type: String, rect: Rect2, color: Color, is_powered: bool = true) -> void:
	var shapes: Array = PictogramShapes.SHAPES.get(device_type, PictogramShapes.SHAPES["generic"])
	var s: float = minf(rect.size.x, rect.size.y) / GRID
	var origin: Vector2 = rect.get_center() - Vector2(GRID, GRID) * 0.5 * s
	var ink: Color = INK if is_powered else INK_OFF
	var accent: Color = color if is_powered else INK_OFF
	var tint := Color(color.r, color.g, color.b, 0.18 if is_powered else 0.06)
	var width: float = maxf(STROKE_UNITS * s, 1.25)

	for op in shapes:
		_draw_op(canvas, op, origin, s, width, ink, accent, tint)


static func _draw_op(canvas: CanvasItem, op: Dictionary, o: Vector2, s: float, w: float, ink: Color, accent: Color, tint: Color) -> void:
	match String(op["t"]):
		"rrect":
			var rc := Rect2(float(op["x"]), float(op["y"]), float(op["w"]), float(op["h"]))
			_fill_and_stroke(canvas, _xf(_rrect_points(rc, float(op["r"])), o, s), tint, ink, w)
		"frect":
			var rc2 := Rect2(float(op["x"]), float(op["y"]), float(op["w"]), float(op["h"]))
			canvas.draw_colored_polygon(_xf(_rrect_points(rc2, 0.0), o, s), tint)
		"circle":
			var r: float = float(op["r"])
			_fill_and_stroke(canvas, _xf(_ellipse_points(op["c"], r, r, 0.0, TAU, ARC_SEGMENTS * 2, false), o, s), tint, ink, w)
		"ellipse":
			_fill_and_stroke(canvas, _xf(_ellipse_points(op["c"], float(op["rx"]), float(op["ry"]), 0.0, TAU, ARC_SEGMENTS * 2, false), o, s), tint, ink, w)
		"arc":
			# bottom half of an ellipse, drawn left to right
			var pts := _ellipse_points(op["c"], float(op["rx"]), float(op["ry"]), PI, 0.0, ARC_SEGMENTS, true)
			canvas.draw_polyline(_xf(pts, o, s), ink, w, true)
		"line":
			var p: Array = op["p"]
			canvas.draw_line(o + Vector2(p[0], p[1]) * s, o + Vector2(p[2], p[3]) * s, ink, w, true)
		"poly":
			var q: Array = op["p"]
			var pl := PackedVector2Array()
			for i in range(0, q.size(), 2):
				pl.append(Vector2(q[i], q[i + 1]))
			canvas.draw_polyline(_xf(pl, o, s), ink, w, true)
		"dot":
			canvas.draw_circle(o + (op["c"] as Vector2) * s, float(op["r"]) * s, accent)


static func _fill_and_stroke(canvas: CanvasItem, pts: PackedVector2Array, tint: Color, ink: Color, w: float) -> void:
	if tint.a > 0.0:
		canvas.draw_colored_polygon(pts, tint)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	canvas.draw_polyline(closed, ink, w, true)


static func _xf(pts: PackedVector2Array, o: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	for i in pts.size():
		out[i] = o + pts[i] * s
	return out


static func _ellipse_points(c: Vector2, rx: float, ry: float, a0: float, a1: float, segments: int, include_end: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var count: int = segments + 1 if include_end else segments
	for i in count:
		var a: float = a0 + (a1 - a0) * float(i) / float(segments)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _rrect_points(rc: Rect2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rr: float = minf(r, minf(rc.size.x, rc.size.y) * 0.5)
	if rr <= 0.01:
		pts.append(rc.position)
		pts.append(Vector2(rc.end.x, rc.position.y))
		pts.append(rc.end)
		pts.append(Vector2(rc.position.x, rc.end.y))
		return pts
	# clockwise on screen: top-right, bottom-right, bottom-left, top-left
	var centers: Array[Vector2] = [
		Vector2(rc.end.x - rr, rc.position.y + rr),
		Vector2(rc.end.x - rr, rc.end.y - rr),
		Vector2(rc.position.x + rr, rc.end.y - rr),
		Vector2(rc.position.x + rr, rc.position.y + rr),
	]
	for k in 4:
		var start: float = -PI * 0.5 + PI * 0.5 * float(k)
		for i in CORNER_SEGMENTS + 1:
			var a: float = start + (PI * 0.5) * float(i) / float(CORNER_SEGMENTS)
			pts.append(centers[k] + Vector2(cos(a), sin(a)) * rr)
	return pts
