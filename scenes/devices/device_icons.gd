class_name DeviceIcons
extends RefCounted

## Legacy interface delegating to DevicePictograms
static func draw_device(canvas: CanvasItem, device_type: String, rect: Rect2, color: Color, is_powered: bool = true) -> void:
	DevicePictograms.draw_device(canvas, device_type, rect, color, is_powered)
