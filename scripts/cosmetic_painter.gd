class_name CosmeticPainter
extends RefCounted

static func ball_color(entry: Dictionary, _time: float, fallback: Color) -> Color:
	return fallback if entry.style == "default" else Color(entry.color)

static func ball(canvas: CanvasItem, center: Vector2, radius: float, entry: Dictionary, time: float, fallback := Color("ffce68")) -> void:
	var tint := ball_color(entry, time, fallback)
	canvas.draw_circle(center, radius * 1.6, Color(tint, 0.08))
	canvas.draw_circle(center, radius, tint)
	canvas.draw_circle(center + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.3, tint.lightened(0.65))

static func paddle(canvas: CanvasItem, rect: Rect2, entry: Dictionary, _time: float) -> void:
	var tint := Color(entry.color)
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(8)
	style.shadow_color = Color(tint, 0.16)
	style.shadow_size = 10
	canvas.draw_style_box(style, rect)
	canvas.draw_line(rect.position + Vector2(15, 5), rect.position + Vector2(rect.size.x - 15, 5), tint.lightened(0.6), 2, true)

static func background(canvas: CanvasItem, size: Vector2, entry: Dictionary, time: float) -> void:
	var style: String = entry.style
	var top := Color(entry.color)
	var bottom := Color("0b1225")
	if style == "sunset":
		top = Color("773b45")
		bottom = Color("211b40")
	elif style == "ocean":
		top = Color("073153")
		bottom = Color("061021")
	elif style == "forest":
		top = Color("173e35")
		bottom = Color("071d21")
	for i in range(24):
		canvas.draw_rect(Rect2(0, size.y * i / 24.0, size.x, size.y / 24.0 + 1), top.lerp(bottom, float(i) / 23))
	if style == "sunset":
		canvas.draw_circle(Vector2(size.x * 0.77, size.y * 0.24), size.x * 0.13, Color("aa6759"))
	elif style == "ocean":
		for layer in range(4):
			var wave := PackedVector2Array()
			for x in range(33):
				wave.append(Vector2(x * size.x / 32, size.y * (0.38 + layer * 0.15) + sin(x * 0.3 + time * 0.12 + layer) * 10))
			canvas.draw_polyline(wave, Color(0.06, 0.38, 0.55, 0.23), 3, true)
	elif style == "city":
		city(canvas, size, time, false)
	elif style == "space" or style == "default":
		stars(canvas, size, time)
		if style == "space":
			canvas.draw_circle(Vector2(size.x * 0.78, size.y * 0.28), 42, Color("34234f"))
			canvas.draw_arc(Vector2(size.x * 0.78, size.y * 0.28), 58, -0.2, PI + 0.5, 40, Color("594268"), 2, true)
	elif style == "forest":
		for layer in range(3):
			for i in range(11):
				var x := (i + 0.3 * layer) * size.x / 10
				var y := size.y * (0.65 + layer * 0.12)
				var height := 55 + fmod(i * 37 + layer * 13, 45)
				var tint := Color("174b3c").darkened(layer * 0.18)
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, y - height), Vector2(x - 32, y), Vector2(x + 32, y)]), tint)
				canvas.draw_line(Vector2(x, y - 18), Vector2(x, size.y), tint, 5)

static func stars(canvas: CanvasItem, size: Vector2, time: float) -> void:
	for i in range(54):
		var p := Vector2(fposmod(i * 137.3 + 31, size.x), fposmod(i * 83.7 + 132 + time * 4, size.y))
		canvas.draw_circle(p, 1.4 if i % 3 == 0 else 0.8, Color(0.65, 0.72, 0.95, 0.22))

static func city(canvas: CanvasItem, size: Vector2, _time: float, _premium: bool) -> void:
	for i in range(12):
		var width := size.x / 11
		var height := size.y * (0.12 + fmod(i * 0.071, 0.23))
		var rect := Rect2(i * width, size.y - height, width - 3, height)
		canvas.draw_rect(rect, Color("0b1425"))
		canvas.draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("1b5161"), 2)
		for row in range(5):
			for col in range(2):
				canvas.draw_rect(Rect2(rect.position + Vector2(8 + col * 13, 14 + row * 20), Vector2(4, 5)), Color("24556b"))
