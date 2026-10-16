extends RefCounted

const Session = preload("res://scripts/play_session.gd")
const Physics = preload("res://scripts/ball_sim.gd")
const SIZE := Vector2(480, 800)

func run(tree: SceneTree, check: Callable) -> void:
	# Classic delegates every step directly, while Reverse mirrors that exact
	# trajectory. Exercise seeded random heights, difficulty, walls, and scores
	# across phone/tablet aspect ratios without copying the physics algorithm.
	for size in [SIZE, Vector2(480, 1040), Vector2(768, 1024)]:
		var classic = Session.new()
		var reverse = Session.new()
		var baseline = Physics.new()
		classic.reset(size)
		reverse.reset(size, Session.GameMode.REVERSE)
		baseline.reset(size)
		for model in [classic.core, reverse.core, baseline]:
			model.bounce_rng.seed = 8675309
		var same_classic := true
		var mirrored := true
		for frame in range(120 * 180):
			if frame % 500 == 0:
				for model in [classic.core, reverse.core, baseline]:
					model.velocity.x = 280
			var target: float = baseline.ball.x
			var expected_hit: bool = baseline.step(1.0 / 120, target, size)
			var classic_hit: bool = classic.step(1.0 / 120, target, size)
			var reverse_hit: bool = reverse.step(1.0 / 120, target, size)
			same_classic = same_classic and classic_hit == expected_hit and classic.ball == baseline.ball and classic.velocity == baseline.velocity and classic.paddle == baseline.paddle and classic.score == baseline.score and classic.lost == baseline.lost
			mirrored = mirrored and reverse_hit == expected_hit and is_equal_approx(reverse.ball.y + baseline.ball.y, size.y) and reverse.ball.x == baseline.ball.x and reverse.velocity.y == -baseline.velocity.y and reverse.velocity.x == baseline.velocity.x and is_equal_approx(reverse.paddle.y + baseline.paddle.y, size.y) and reverse.score == baseline.score and reverse.lost == baseline.lost
		check.call(same_classic, "Classic trajectory remains exactly unchanged at %s" % size)
		check.call(mirrored, "Reverse mirrors Classic collisions and progression at %s" % size)
		check.call(reverse.score > 60 and not reverse.lost, "Reverse three-minute rally remains playable at %s" % size)

	var reverse = Session.new()
	reverse.reset(SIZE, Session.GameMode.REVERSE)
	check.call(is_equal_approx(reverse.paddle.y, 146) and reverse.ball.y > reverse.paddle.y, "Reverse spawns below a platform near the top")
	check.call(reverse.gravity.y == -Physics.GRAVITY, "Reverse gravity points upward")
	reverse.step(1.0 / 120, 240, SIZE)
	check.call(reverse.velocity.y < 0, "Upward acceleration changes world velocity")
	check.call(reverse.paddle_rect().end.y == reverse.paddle.y, "Reverse collision plane is the visible underside of the platform")
	reverse.ball = Vector2(240, reverse.paddle.y + 14)
	reverse.velocity = Vector2(0, -600)
	check.call(reverse.step(1.0 / 120, 240, SIZE), "Upward ball hits the underside of the platform")
	check.call(reverse.velocity.y > 0 and reverse.score == 1 and reverse.ball.y > reverse.paddle.y, "Reverse hit rebounds downward and scores once")
	reverse.step(1.0 / 120, 240, SIZE)
	check.call(reverse.score == 1, "Downward departure does not double-count a bounce")
	reverse.reset(SIZE, Session.GameMode.REVERSE)
	reverse.ball = Vector2(285, reverse.paddle.y + 30)
	reverse.velocity = Vector2(0, -3000)
	check.call(reverse.step(1.0 / 30, 240, SIZE) and reverse.velocity.x > 0 and reverse.velocity.y > 0, "Fast Reverse edge collision preserves steering and rebound")
	reverse.reset(SIZE, Session.GameMode.REVERSE)
	reverse.ball = Vector2(200, SIZE.y - 145)
	reverse.velocity = Vector2(0, 300)
	reverse.step(1.0 / 120, 240, SIZE)
	check.call(not reverse.lost and reverse.velocity.y < 0, "Reverse bottom boundary reflects before the HUD")
	reverse.reset(SIZE, Session.GameMode.REVERSE)
	reverse.ball = Vector2(20, reverse.paddle.y + 14)
	reverse.velocity = Vector2(0, -500)
	for frame in range(240):
		reverse.step(1.0 / 120, 350, SIZE)
	check.call(reverse.lost and reverse.ball.y + Physics.RADIUS < 0 and reverse.score == 0, "Missing Reverse platform loses only after exiting the top")
	var lost_ball: Vector2 = reverse.ball
	reverse.step(1.0, 240, SIZE)
	check.call(reverse.ball == lost_ball, "Reverse loss freezes simulation")
	reverse.reset(SIZE)
	check.call(not reverse.is_reverse() and not reverse.lost and reverse.gravity.y > 0, "Restarting Classic restores downward gravity")

	var game = load("res://main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	game.set_physics_process(false)
	game.set_process(false)
	# Simulate a pre-upgrade installation rather than relying on test-user data.
	var legacy := ConfigFile.new()
	legacy.set_value("game", "best", 321)
	legacy.set_value("game", "sound", false)
	legacy.save("user://progress.cfg")
	game.load_progress()
	check.call(game.high_scores["classic"] == 321 and game.high_scores["reverse"] == 0 and not game.sound_enabled, "Legacy score migrates to Classic and sound preference is retained")
	game.show_menu()
	var play_button: Button
	for child in game.overlay.get_children():
		if child is Button and child.text == "Play":
			play_button = child
	play_button.pressed.emit()
	check.call(game.mode == "selecting", "Play opens the mode selection menu")
	var reverse_button: Button
	var classic_button: Button
	for child in game.overlay.get_children():
		if child is Button and child.text == "Reverse Mode":
			reverse_button = child
		if child is Button and child.text == "Classic Mode":
			classic_button = child
	check.call(reverse_button != null and classic_button != null, "Mode menu offers both modes")
	reverse_button.pressed.emit()
	check.call(game.mode == "playing" and game.sim.is_reverse() and game.best == 0, "Reverse selection starts gameplay with its own best score")
	check.call(game.score_label.position.y > SIZE.y - 140, "Reverse HUD is below the playfield")
	check.call(not game.touch_in_play_area(Vector2(240, 740)) and game.touch_in_play_area(Vector2(240, 180)), "Reverse touch area includes top platform and excludes bottom HUD")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.index = 0
	touch.position = Vector2(180, 180)
	game._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(220, 180)
	game._unhandled_input(drag)
	check.call(is_equal_approx(game.target_x, 280), "Reverse touch drag still moves right with the finger")
	game.sim.score = 1
	game._physics_process(1.0 / 120)
	check.call(game.sim.paddle.x > 240, "Reverse touch input moves the actual platform")
	game.sim.ball = Vector2(game.sim.paddle.x, game.sim.paddle.y + 14)
	game.sim.velocity = Vector2(0, -600)
	game._physics_process(1.0 / 120)
	check.call(game.best == 2 and game.high_scores["classic"] == 321, "A real Reverse bounce updates only the Reverse high score")
	game.pause_game()
	check.call(game.mode == "paused" and game.finger == -1, "Reverse pauses and releases active touch")
	var paused_ball: Vector2 = game.sim.ball
	game._physics_process(0.5)
	check.call(game.sim.ball == paused_ball, "Reverse paused physics stays frozen")
	game.resume_game()
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check.call(game.mode == "paused", "Reverse automatically pauses when backgrounded")
	game.start_game()
	check.call(game.sim.is_reverse() and game.sim.score == 0, "Restart retains Reverse Mode")
	game.sim.score = 10
	var old_tint: Color = game.ball_tint
	game._process(0.1)
	check.call(game.ball_tint != old_tint and game.level_text().contains("LEVEL 2"), "Level colors and cosmetics work in Reverse")
	game.best = 77
	game.game_over()
	check.call(game.mode == "over" and game.high_scores["classic"] == 321, "Reverse game over does not change Classic best")
	game.start_game()
	check.call(game.sim.is_reverse() and game.best == 77, "Reverse replay retains mode and high score")
	game.show_mode_selection()
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check.call(game.mode == "menu", "Back from mode selection returns to menu")
	game.start_mode(Session.GameMode.CLASSIC)
	check.call(not game.sim.is_reverse() and game.best == 321 and game.score_label.position.y == 42, "Returning to Classic preserves its score and HUD layout")
	check.call(not game.touch_in_play_area(Vector2(240, 80)) and game.touch_in_play_area(Vector2(240, 600)), "Classic touch region stays unchanged")
	game.best = 333
	game.persist()
	var stored := ConfigFile.new()
	stored.load("user://progress.cfg")
	check.call(stored.get_value("scores", "classic") == 333 and stored.get_value("scores", "reverse") == 77 and stored.get_value("game", "best") == 333, "Both mode scores persist with the legacy Classic key intact")
	game.high_scores = {"classic": 0, "reverse": 0}
	game.load_progress()
	check.call(game.high_scores["classic"] == 333 and game.high_scores["reverse"] == 77, "Both high scores survive a reload")
	game.queue_free()
	await tree.process_frame
