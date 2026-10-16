extends SceneTree

const Sim = preload("res://scripts/ball_sim.gd")
var checks := 0
var failures := 0
const SIZE := Vector2(480, 800)

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(480, 800)
	var sim = Sim.new()
	sim.reset(SIZE)
	sim.ball = Vector2(240, sim.paddle.y - 14)
	sim.velocity = Vector2(0, 600)
	check(sim.step(1.0 / 120, 240, SIZE), "Descending ball hits platform")
	check(sim.score == 1 and sim.velocity.y < 0, "Bounce scores once and moves upward")
	sim.step(1.0 / 120, 240, SIZE)
	check(sim.score == 1, "No duplicate score on departure")
	check(absf(sim.velocity.x) < 1, "Centered hit travels straight")
	sim.reset(SIZE)
	sim.ball = Vector2(285, sim.paddle.y - 14)
	sim.velocity = Vector2(0, 1000)
	sim.step(1.0 / 120, 240, SIZE)
	check(sim.velocity.x > 100 and sim.velocity.y < 0, "Edge hit deflects ball outward")
	sim.reset(SIZE)
	sim.ball = Vector2(240, sim.paddle.y - 30)
	sim.velocity = Vector2(0, 3000)
	check(sim.step(1.0 / 30, 240, SIZE), "Swept collision catches fast ball")
	sim.reset(SIZE)
	sim.ball = Vector2(20, 400)
	sim.velocity = Vector2(-300, 0)
	sim.step(0.05, -900, SIZE)
	check(sim.velocity.x > 0 and sim.ball.x >= Sim.RADIUS, "Wall reflects and keeps ball in bounds")
	check(sim.paddle.x >= 66, "Platform stays inside left edge")
	sim.step(0.01, 900, SIZE)
	check(sim.paddle.x <= SIZE.x - 66, "Platform stays inside right edge")
	sim.reset(SIZE)
	sim.ball = Vector2(20, sim.paddle.y - 15)
	sim.velocity = Vector2(0, 500)
	for i in range(120):
		sim.step(1.0 / 120, 350, SIZE)
	check(sim.lost and sim.score == 0, "Miss ends game without score")
	var final_ball: Vector2 = sim.ball
	sim.step(0.5, 240, SIZE)
	check(sim.ball == final_ball, "Lost simulation freezes")
	sim.reset(SIZE)
	check(not sim.lost and sim.score == 0, "Restart resets game")
	var previous_multiplier := 0.0
	var increasing := true
	for value in [0, 5, 10, 30, 60, 100, 250, 1000]:
		sim.score = value
		increasing = increasing and sim.speed_multiplier() > previous_multiplier
		previous_multiplier = sim.speed_multiplier()
	check(increasing, "Speed keeps increasing beyond score 30 and at high scores")
	sim.reset(SIZE)
	var initial_ball: Vector2 = sim.ball
	sim.step(1.0 / 120, 240, SIZE)
	var early_distance: float = sim.ball.distance_to(initial_ball)
	sim.reset(SIZE)
	sim.score = 100
	sim.step(1.0 / 120, 240, SIZE)
	check(sim.ball.distance_to(initial_ball) > early_distance * 2, "High scores move the ball faster in actual simulation time")
	sim.reset(SIZE)
	check(is_equal_approx(sim.speed_multiplier(), Sim.START_SPEED), "Restart restores starting speed")
	check(sim.speed_multiplier() <= 0.7, "Opening pace is at least 30 percent slower than version 1.1.0")
	sim.bounce_rng.seed = 42
	var early_heights: Array[float] = []
	for i in range(40):
		early_heights.append(sim.next_bounce_height())
	check(early_heights.min() >= 240 and early_heights.max() <= 300, "Beginner bounce heights stay within a gentle band")
	check(early_heights.max() - early_heights.min() > 30, "Bounce heights vary rather than repeating a fixed arc")
	var minimum_airtime: float = 2 * sqrt(2 * float(early_heights.min()) / Sim.GRAVITY) / sim.speed_multiplier()
	check(minimum_airtime > 2.5, "Low-score bounces allow over 2.5 seconds of reaction time")
	sim.score = 100
	var late_heights: Array[float] = []
	for i in range(40):
		late_heights.append(sim.next_bounce_height())
	check(late_heights.min() >= 170 and late_heights.max() <= 360, "Advanced bounce heights remain controlled")
	check(late_heights.max() - late_heights.min() > early_heights.max() - early_heights.min(), "Height variety widens at higher scores")
	sim.reset(SIZE)
	sim.bounce_rng.seed = 42
	sim.ball = Vector2(285, sim.paddle.y - 14)
	sim.velocity = Vector2(0, 600)
	sim.step(1.0 / 120, 240, SIZE)
	var launch_height: float = sim.velocity.y * sim.velocity.y / (2 * Sim.GRAVITY)
	check(sim.velocity.y < 0 and launch_height >= 240 and launch_height <= 300, "Edge steering preserves a forgiving randomized vertical bounce")
	sim.reset(SIZE)
	sim.bounce_rng.seed = 99
	var min_y := 9999.0
	var max_y := 0.0
	for i in range(120 * 180):
		sim.step(1.0 / 120, sim.ball.x, SIZE)
		if sim.score > 10:
			min_y = minf(min_y, sim.paddle.y)
			max_y = maxf(max_y, sim.paddle.y)
		if sim.lost:
			break
	check(sim.score >= 60 and not sim.lost, "Three-minute automated rally remains playable")
	check(max_y - min_y > 50, "Difficulty moves platform vertically")
	check(sim.velocity.length() < 1100, "Ballistic arc stays stable during the long rally")
	print("Automated rally: %d bounces" % sim.score)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.mode == "menu", "Main menu opens")
	check(game.ball_color_for_score(0) == game.ball_color_for_score(9), "Ball color stays consistent within a level")
	check(game.ball_color_for_score(10) != game.ball_color_for_score(9), "Ball color changes at 10 points")
	check(game.ball_color_for_score(20) != game.ball_color_for_score(10), "Later level has a new ball color")
	check(game.ball_color_for_score(60) == game.ball_color_for_score(0), "Color palette cycles for continued play")
	var old_star: Vector2 = game.star_position(0, SIZE)
	game._process(1.0)
	check(game.star_position(0, SIZE) != old_star, "Stars move over time in menus")
	game.start_game()
	await process_frame
	check(game.mode == "playing", "Play starts game")
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = Vector2(180, 600)
	down.pressed = true
	game._unhandled_input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(220, 600)
	game._unhandled_input(drag)
	check(is_equal_approx(game.target_x, 280), "Touch drag moves relative to finger")
	game.sim.score = 10
	var previous_tint: Color = game.ball_tint
	game._process(0.1)
	check(game.ball_tint != previous_tint and game.ball_tint != game.ball_color_for_score(10), "Milestone color transition is gradual")
	game.pause_game()
	var paused_sky: float = game.sky_time
	var paused_tint: Color = game.ball_tint
	var paused_ball: Vector2 = game.sim.ball
	for i in range(5):
		await physics_frame
	check(game.mode == "paused" and game.sim.ball == paused_ball, "Pause freezes physics")
	check(game.sky_time == paused_sky and game.ball_tint == paused_tint, "Pause freezes star and ball-color animation")
	game.resume_game()
	check(game.mode == "playing", "Resume works")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.mode == "paused", "Backgrounding automatically pauses")
	game.start_game()
	check(game.sim.score == 0, "Restart clears score")
	check(game.ball_tint == game.ball_color_for_score(0), "Restart restores first ball color")
	game.best = 123
	game.persist()
	var config := ConfigFile.new()
	check(config.load("user://progress.cfg") == OK and config.get_value("game", "best") == 123, "High score saves to device storage")
	game.game_over()
	await process_frame
	check(game.mode == "over", "Game over offers replay")
	game.show_menu()
	await process_frame
	check(game.mode == "menu", "Main menu return works")
	game.queue_free()
	await process_frame
	await preload("res://tests/reverse_mode.gd").new().run(self, check)
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
