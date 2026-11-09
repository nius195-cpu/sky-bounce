class_name CosmeticPainter
extends RefCounted

static func ball_color(entry: Dictionary, time: float, fallback: Color) -> Color:
	match entry.style:
		"default": return fallback
		"rainbow": return Color.from_hsv(fposmod(time * 0.07, 1.0), 0.68, 1.0)
		"galaxy": return Color("9f80ff").lerp(Color("70cfff"), 0.5 + sin(time * 0.7) * 0.5)
		"fireball": return Color("ff6538").lerp(Color("ffc05c"), 0.5 + sin(time * 3) * 0.5)
	return Color(entry.color)

static func ball(canvas: CanvasItem, center: Vector2, radius: float, entry: Dictionary, time: float, fallback := Color("ffce68")) -> void:
	var tint := ball_color(entry, time, fallback)
	canvas.draw_circle(center, radius * 1.6, Color(tint, 0.08))
	canvas.draw_circle(center, radius, tint)
	match entry.style:
		"galaxy":
			for ring in range(6, 0, -1):
				var fraction := ring / 6.0
				var drift := Vector2(sin(time * 0.4), cos(time * 0.4)) * radius * (1 - fraction) * 0.45
				canvas.draw_circle(center + drift, radius * fraction, Color("413578").lerp(tint, 1 - fraction))
			for i in range(5):
				var angle := time * 0.5 + i * TAU / 5
				canvas.draw_circle(center + Vector2(cos(angle), sin(angle)) * radius * 0.58, radius * 0.12, Color("eadcff"))
			canvas.draw_arc(center, radius * 0.75, time * 0.3, time * 0.3 + PI, 16, Color("6550a2"), radius * 0.18, true)
		"rainbow":
			for i in range(12):
				canvas.draw_arc(center, radius * 0.72, i * TAU / 12, (i + 1) * TAU / 12, 4, Color.from_hsv(fposmod(i / 12.0 + time * 0.07, 1), 0.75, 1), radius * 0.4, true)
		"fireball":
			canvas.draw_circle(center, radius * (1.9 + sin(time * 3) * 0.15), Color(1, 0.23, 0.08, 0.08))
			canvas.draw_arc(center, radius * 0.8, time, time + PI * 1.4, 16, Color("fff0a5"), radius * 0.2, true)
		"chrome":
			for i in range(9):
				var y := (i - 4) * radius / 5
				var width := sqrt(maxf(0, radius * radius - y * y)) * 0.92
				var shine := Color("637687").lerp(Color("f1f9ff"), 0.5 + 0.5 * sin(i * 0.85))
				canvas.draw_line(center + Vector2(-width, y), center + Vector2(width, y), shine, radius / 5 + 1, true)
	canvas.draw_circle(center + Vector2(-radius * 0.3, -radius * 0.3), radius * 0.22, tint.lightened(0.65))

static func paddle(canvas: CanvasItem, rect: Rect2, entry: Dictionary, time: float) -> void:
	var tint := Color(entry.color)
	var style := StyleBoxFlat.new()
	style.bg_color = tint if entry.style in ["solid", "default", "gold"] else Color("12293b")
	style.set_corner_radius_all(8)
	style.shadow_color = Color(tint, 0.16)
	style.shadow_size = 10
	if entry.style == "pulse":
		style.set_border_width_all(2)
		style.border_color = tint.lerp(Color("f58adf"), 0.5 + 0.5 * sin(time * 1.5))
		style.shadow_color = Color(style.border_color, 0.22)
		style.shadow_size = 8 + int(3 * (1 + sin(time * 1.5)))
	canvas.draw_style_box(style, rect)
	if entry.style == "grid":
		for i in range(1, 9):
			var x := rect.position.x + rect.size.x * i / 9
			canvas.draw_line(Vector2(x, rect.position.y + 2), Vector2(x, rect.end.y - 2), Color(tint, 0.7), 1, true)
		canvas.draw_line(rect.position + Vector2(5, 8), rect.end - Vector2(5, 8), tint, 1, true)
	elif entry.style == "gold":
		canvas.draw_line(rect.position + Vector2(8, 4), rect.position + Vector2(rect.size.x - 8, 4), Color("fff0ad"), 3, true)
		canvas.draw_line(rect.position + Vector2(8, 12), rect.position + Vector2(rect.size.x - 8, 12), Color("956b24"), 2, true)
	else:
		canvas.draw_line(rect.position + Vector2(15, 5), rect.position + Vector2(rect.size.x - 15, 5), tint.lightened(0.6), 2, true)

static func background(canvas: CanvasItem, size: Vector2, entry: Dictionary, time: float) -> void:
	var style: String = entry.style
	var top := Color(entry.color)
	var bottom := Color("0b1225")
	if style == "sunset":
		top = Color("75432d")
		bottom = Color("211b40")
	elif style == "ocean":
		top = Color("073153")
		bottom = Color("061021")
	elif style == "forest":
		top = Color("173e35")
		bottom = Color("071d21")
	for i in range(24):
		var amount := float(i) / 23
		var tint := top.lerp(bottom, amount)
		if style == "sunset":
			tint = top.lerp(Color("71395c"), amount * 2) if amount < 0.5 else Color("71395c").lerp(bottom, amount * 2 - 1)
		canvas.draw_rect(Rect2(0, size.y * i / 24.0, size.x, size.y / 24.0 + 1), tint)
	if style == "sunset":
		canvas.draw_circle(Vector2(size.x * 0.77, size.y * 0.24), size.x * 0.13, Color("aa6759"))
	elif style == "ocean":
		for layer in range(4):
			var wave := PackedVector2Array()
			for x in range(33):
				wave.append(Vector2(x * size.x / 32, size.y * (0.38 + layer * 0.15) + sin(x * 0.3 + time * 0.12 + layer) * 10))
			canvas.draw_polyline(wave, Color(0.06, 0.38, 0.55, 0.23), 3, true)
	elif style in ["city", "cyberpunk"]:
		city(canvas, size, time, style == "cyberpunk")
	elif style == "space" or style == "default":
		stars(canvas, size, time)
		if style == "space":
			canvas.draw_circle(Vector2(size.x * 0.78, size.y * 0.28), 42, Color("34234f"))
			canvas.draw_arc(Vector2(size.x * 0.78, size.y * 0.28), 58, -0.2, PI + 0.5, 40, Color("594268"), 2, true)
	elif style == "aurora":
		stars(canvas, size, time)
		for band in range(3):
			var ribbon := PackedVector2Array()
			for x in range(33):
				ribbon.append(Vector2(x * size.x / 32, size.y * (0.18 + band * 0.07) + sin(x * 0.2 + time * 0.16 + band) * 28))
			for x in range(32, -1, -1):
				ribbon.append(Vector2(x * size.x / 32, size.y * (0.26 + band * 0.07) + sin(x * 0.2 + time * 0.16 + band) * 28))
			canvas.draw_colored_polygon(ribbon, Color(0.18 + band * 0.1, 0.7 - band * 0.12, 0.52 + band * 0.15, 0.12))
	elif style == "retro":
		for i in range(11):
			canvas.draw_line(Vector2(size.x / 2, size.y * 0.48), Vector2(i * size.x / 10, size.y), Color("43294f"), 1)
		for i in range(9):
			var y := size.y * (0.5 + pow(i / 8.0, 1.5) * 0.5)
			canvas.draw_line(Vector2(0, y), Vector2(size.x, y), Color("43294f"), 1)
		for i in range(25):
			canvas.draw_rect(Rect2(fmod(i * 113 + 17, size.x), fmod(i * 43 + 15, size.y * 0.45), 3, 3), Color("7d5487"))
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

static func city(canvas: CanvasItem, size: Vector2, time: float, premium: bool) -> void:
	for i in range(12):
		var width := size.x / 11
		var height := size.y * (0.12 + fmod(i * 0.071, 0.23))
		var rect := Rect2(i * width, size.y - height, width - 3, height)
		canvas.draw_rect(rect, Color("0b1425"))
		var glow := Color("a63f85") if premium and i % 2 == 0 else Color("1b5161")
		canvas.draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), glow, 2)
		if premium:
			canvas.draw_line(rect.position + Vector2(2, 0), rect.position + Vector2(2, height), Color(glow, 0.55), 2)
			canvas.draw_circle(rect.position + Vector2(rect.size.x / 2, -7), 2, Color(glow, 0.5 + sin(time + i) * 0.2))
		for row in range(5):
			for col in range(2):
				canvas.draw_rect(Rect2(rect.position + Vector2(8 + col * 13, 14 + row * 20), Vector2(4, 5)), Color("24556b"))
