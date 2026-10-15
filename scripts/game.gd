extends Node2D

const Sim = preload("res://scripts/ball_sim.gd")
const INK := Color("eaf2ff")
const MINT := Color("62e7d4")
const GOLD := Color("ffce68")
const COLOR_INTERVAL := 10
const BALL_PALETTE := [Color("ffce68"), Color("62e7d4"), Color("72b7ff"), Color("bb9aff"), Color("ff8fa9"), Color("ffad72")]
var sky_time := 0.0
var ball_tint := GOLD
var sim = Sim.new()
var mode := "menu"
var best := 0
var target_x := 240.0
var finger := -1
var drag_offset := 0.0
var trail: Array[Vector2] = []
var sparks: Array[Dictionary] = []
var ui: CanvasLayer
var overlay: Control
var hud: Control
var score_label: Label
var best_label: Label
var level_label: Label
var sound_enabled := true
var audio: AudioStreamPlayer
var font := ThemeDB.fallback_font
var last_size := Vector2.ZERO
var storage_warning := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	var save := ConfigFile.new()
	if save.load("user://progress.cfg") == OK:
		best = maxi(0, int(save.get_value("game", "best", 0)))
		sound_enabled = bool(save.get_value("game", "sound", true))
	audio = AudioStreamPlayer.new()
	add_child(audio)
	ui = CanvasLayer.new()
	add_child(ui)
	sim.reset(get_viewport_rect().size)
	show_menu()

func persist() -> void:
	var save := ConfigFile.new()
	save.set_value("game", "best", best)
	save.set_value("game", "sound", sound_enabled)
	storage_warning = save.save("user://progress.cfg") != OK

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if mode == "playing":
			pause_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if mode == "playing":
			pause_game()
		elif mode == "paused":
			resume_game()
		else:
			get_tree().quit()

func clear_ui() -> void:
	for child in ui.get_children():
		child.queue_free()
		ui.remove_child(child)
	overlay = null

func label_at(parent: Node, text: String, pos: Vector2, width: float, size: int, color := INK) -> Label:
	var item := Label.new()
	item.text = text
	item.position = pos
	item.size = Vector2(width, 50)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func button_at(parent: Node, text: String, pos: Vector2, width: float, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(width, 54)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("102437") if primary else INK)
	button.add_theme_color_override("font_hover_color", Color("102437") if primary else INK)
	button.add_theme_color_override("font_pressed_color", Color("102437") if primary else INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = MINT.darkened(0.13 if state == "pressed" else 0) if primary else Color("233254")
		style.set_corner_radius_all(16)
		if state == "focus":
			style.set_border_width_all(2)
			style.border_color = GOLD
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func make_panel(title: String, subtitle: String) -> Vector2:
	clear_ui()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	var screen := get_viewport_rect().size
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.11, 0.90)
	shade.size = screen
	overlay.add_child(shade)
	var top := maxf(110, (screen.y - 540) / 2)
	label_at(overlay, "●  SKY BOUNCE", Vector2(0, top), screen.x, 18, MINT)
	label_at(overlay, title, Vector2(0, top + 62), screen.x, 44)
	label_at(overlay, subtitle, Vector2(16, top + 125), screen.x - 32, 17, Color("a7b8dc"))
	return Vector2((screen.x - 300) / 2, top + 205)

func show_menu() -> void:
	mode = "menu"
	finger = -1
	var pos := make_panel("Find your rhythm.", "One ball. One platform. Keep it alive.")
	button_at(overlay, "Play", pos, 300, start_game, true)
	button_at(overlay, "Sound: " + ("on" if sound_enabled else "off"), pos + Vector2(0, 70), 300, toggle_sound)
	label_at(overlay, "PERSONAL BEST   %d" % best, pos + Vector2(-40, 153), 380, 19, GOLD)
	label_at(overlay, "Drag anywhere below the score.\nAim with the edges of your platform.\nAt 5 bounces, the platform starts to float.\nNew ball color every 10 bounces.", pos + Vector2(-45, 208), 390, 16, Color("a7b8dc"))
	button_at(overlay, "About & privacy", pos + Vector2(0, 300), 300, show_about)
	if storage_warning:
		label_at(overlay, "Could not save progress on this device.", pos + Vector2(-45, 365), 390, 15, GOLD)

func show_about() -> void:
	var pos := make_panel("Keep it simple.", "Sky Bounce 1.1.1")
	label_at(overlay, "Made with Godot Engine (MIT license).\nhttps://godotengine.org/license\n\nNo ads. No tracking. No account.\nScores stay on your device.\nOriginal art and synthesized sound.", pos + Vector2(-40, 0), 380, 17, Color("a7b8dc"))
	button_at(overlay, "Back", pos + Vector2(0, 200), 300, show_menu, true)

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	persist()
	show_menu()

func start_game() -> void:
	mode = "playing"
	finger = -1
	sim.reset(get_viewport_rect().size)
	target_x = sim.paddle.x
	ball_tint = GOLD
	trail.clear()
	sparks.clear()
	make_hud()

func make_hud() -> void:
	clear_ui()
	hud = Control.new()
	ui.add_child(hud)
	var w := get_viewport_rect().size.x
	score_label = label_at(hud, str(sim.score), Vector2(w / 2 - 65, 42), 130, 42)
	best_label = label_at(hud, "BEST %d" % best, Vector2(12, 59), 110, 15, GOLD)
	level_label = label_at(hud, level_text(), Vector2(w / 2 - 100, 100), 200, 12, MINT)
	button_at(hud, "Ⅱ", Vector2(w - 72, 46), 54, pause_game)

func pause_game() -> void:
	if mode != "playing":
		return
	mode = "paused"
	finger = -1
	var pos := make_panel("Take a breath.", "Your next bounce can wait.")
	button_at(overlay, "Resume", pos, 300, resume_game, true)
	button_at(overlay, "Restart", pos + Vector2(0, 70), 300, start_game)
	button_at(overlay, "Main menu", pos + Vector2(0, 140), 300, show_menu)

func resume_game() -> void:
	mode = "playing"
	finger = -1
	make_hud()

func game_over() -> void:
	mode = "over"
	finger = -1
	persist()
	var pos := make_panel("One more bounce?", "%d bounces  ·  Personal best %d" % [sim.score, best])
	button_at(overlay, "Play again", pos, 300, start_game, true)
	button_at(overlay, "Main menu", pos + Vector2(0, 70), 300, show_menu)
	label_at(overlay, "Tip: hit near the center for a straighter bounce.", pos + Vector2(-60, 154), 420, 15, Color("a7b8dc"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if mode == "playing":
				pause_game()
			elif mode == "paused":
				resume_game()
		if event.keycode == KEY_SPACE and mode in ["menu", "over"]:
			start_game()
	if mode != "playing":
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and event.position.y > 140:
			finger = event.index
			drag_offset = sim.paddle.x - event.position.x
		elif not event.pressed and event.index == finger:
			finger = -1
	elif event is InputEventScreenDrag and event.index == finger:
		target_x = event.position.x + drag_offset

func ball_color_for_score(value: int) -> Color:
	return BALL_PALETTE[(maxi(value, 0) / COLOR_INTERVAL) % BALL_PALETTE.size()]

func level_text() -> String:
	return "LEVEL %d · %s" % [sim.score / COLOR_INTERVAL + 1, "FLOAT MODE" if sim.score >= 5 else "WARM UP"]

func star_position(index: int, screen: Vector2) -> Vector2:
	var depth := float(index % 3 + 1)
	return Vector2(
		fposmod(index * 137.3 + 31 + sin(sky_time * 0.12 + index) * depth * 3, screen.x),
		fposmod(index * 83.7 + 132 + sky_time * (3 + depth * 3), screen.y))

func _process(dt: float) -> void:
	if mode != "paused":
		sky_time += dt
		ball_tint = ball_tint.lerp(ball_color_for_score(sim.score), 1.0 - exp(-6.0 * dt))
	queue_redraw()

func _physics_process(dt: float) -> void:
	var screen := get_viewport_rect().size
	if screen != last_size:
		if last_size != Vector2.ZERO and mode == "playing":
			pause_game()
		last_size = screen
	if mode == "playing":
		var direction := Input.get_axis("ui_left", "ui_right")
		target_x += direction * 460 * dt
		target_x = clampf(target_x, 66, screen.x - 66)
		var hit: bool = sim.step(dt, target_x, screen)
		if hit:
			if sim.score > best:
				best = sim.score
				persist()
			for i in range(12):
				var angle := float(i) / 12 * TAU
				sparks.append({"p": sim.ball, "v": Vector2(cos(angle), sin(angle)) * 125, "life": 0.5})
			play_tone()
		trail.push_front(sim.ball)
		if trail.size() > 16:
			trail.pop_back()
		score_label.text = str(sim.score)
		best_label.text = "BEST %d" % best
		level_label.text = level_text()
		level_label.add_theme_color_override("font_color", ball_tint)
		for i in range(sparks.size() - 1, -1, -1):
			sparks[i].life -= dt
			sparks[i].p += sparks[i].v * dt
			if sparks[i].life <= 0:
				sparks.remove_at(i)
		if sim.lost:
			game_over()
	queue_redraw()

func play_tone() -> void:
	if not sound_enabled:
		return
	var data := PackedByteArray()
	var rate := 22050
	for i in range(1764):
		var envelope := pow(1.0 - float(i) / 1764, 2)
		var wave := sin(TAU * (520 + mini(sim.score, 30) * 12) * i / rate) * envelope * 0.18
		var sample := int(wave * 32767)
		data.append(sample & 255)
		data.append((sample >> 8) & 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	audio.stream = stream
	audio.play()

func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color("0d1530"))
	for i in range(12):
		var a := float(i) / 12
		draw_circle(Vector2(screen.x * 0.8, screen.y * 0.32), 260 - i * 17, Color(0.1, 0.18, 0.30, 0.025 + a * 0.005))
	for i in range(44):
		var p := star_position(i, screen)
		var twinkle := 0.18 + 0.07 * sin(sky_time * 0.7 + i * 1.9)
		draw_circle(p, 1.4 if i % 3 == 0 else 0.8, Color(0.56, 0.68, 0.88, twinkle))
	draw_line(Vector2(24, 140), Vector2(screen.x - 24, 140), Color("263452"), 1)
	if mode == "playing" or mode == "paused" or mode == "over":
		for i in range(trail.size() - 1, -1, -1):
			var strength := 1.0 - float(i) / maxf(1, trail.size())
			draw_circle(trail[i], 3 + strength * 8, Color(ball_tint, strength * 0.16))
		for spark in sparks:
			draw_circle(spark.p, 3, Color(ball_tint, spark.life * 2))
		draw_circle(sim.ball, 22, Color(ball_tint, 0.06))
		draw_circle(sim.ball, Sim.RADIUS, ball_tint)
		draw_circle(sim.ball + Vector2(-4, -4), 4, ball_tint.lightened(0.65))
		var rect := Rect2(sim.paddle - Vector2(56, 0), Vector2(112, 16))
		var style := StyleBoxFlat.new()
		style.bg_color = INK if sim.bounce_flash > 0 else MINT
		style.set_corner_radius_all(8)
		style.shadow_color = Color(0.38, 0.91, 0.83, 0.16)
		style.shadow_size = 12
		draw_style_box(style, rect)
		draw_line(sim.paddle + Vector2(-36, 5), sim.paddle + Vector2(36, 5), Color("cbfff5"), 2, true)
		for i in range(14):
			var x := i * screen.x / 13
			draw_line(Vector2(x, screen.y - 25), Vector2(x + 10, screen.y - 17), Color(1, 0.42, 0.5, 0.35), 2)
		if mode == "playing" and sim.score == 0:
			draw_string(font, Vector2(screen.x / 2 - 125, screen.y - 72), "←  DRAG TO MOVE  →", HORIZONTAL_ALIGNMENT_CENTER, 250, 17, Color("a7b8dc"))
