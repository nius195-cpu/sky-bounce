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
	check(sim.velocity.length() < 1100, "Speed remains bounded")
	print("Automated rally: %d bounces" % sim.score)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.mode == "menu", "Main menu opens")
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
	game.pause_game()
	var paused_ball: Vector2 = game.sim.ball
	for i in range(5):
		await physics_frame
	check(game.mode == "paused" and game.sim.ball == paused_ball, "Pause freezes physics")
	game.resume_game()
	check(game.mode == "playing", "Resume works")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.mode == "paused", "Backgrounding automatically pauses")
	game.start_game()
	check(game.sim.score == 0, "Restart clears score")
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
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
