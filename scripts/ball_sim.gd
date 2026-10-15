class_name BallSim
extends RefCounted

const RADIUS := 13.0
const PADDLE_WIDTH := 112.0
const GRAVITY := 680.0
var ball := Vector2(240, 310)
var velocity := Vector2(105, 0)
var paddle := Vector2(240, 654)
var score := 0
var elapsed := 0.0
var lost := false
var bounce_flash := 0.0

func reset(size: Vector2) -> void:
	ball = Vector2(size.x / 2, size.y * 0.38)
	velocity = Vector2(105, 0)
	paddle = Vector2(size.x / 2, size.y - 146)
	score = 0
	elapsed = 0
	lost = false
	bounce_flash = 0

func platform_y(height: float) -> float:
	var amplitude := minf(maxf(score - 4, 0) * 3.0, 55.0)
	return height - 146.0 + sin(elapsed * 1.15) * amplitude

# Swept crossing in the paddle's moving frame prevents tunnelling.
func step(dt: float, target_x: float, size: Vector2) -> bool:
	if lost:
		return false
	elapsed += dt
	bounce_flash = maxf(0, bounce_flash - dt)
	var old_paddle := paddle
	paddle.x = clampf(target_x, PADDLE_WIDTH / 2 + 10, size.x - PADDLE_WIDTH / 2 - 10)
	paddle.y = platform_y(size.y)
	var old_ball := ball
	velocity.y += GRAVITY * dt
	ball += velocity * dt
	if ball.x < RADIUS:
		ball.x = RADIUS + (RADIUS - ball.x)
		velocity.x = absf(velocity.x)
	elif ball.x > size.x - RADIUS:
		ball.x = size.x - RADIUS - (ball.x - (size.x - RADIUS))
		velocity.x = -absf(velocity.x)
	if ball.y < 140 + RADIUS:
		ball.y = 140 + RADIUS
		velocity.y = absf(velocity.y)
	var before := old_ball.y + RADIUS - old_paddle.y
	var after := ball.y + RADIUS - paddle.y
	var hit := false
	if before <= 0 and after >= 0 and after > before:
		var fraction := -before / (after - before)
		var cross_x := lerpf(old_ball.x, ball.x, fraction)
		var paddle_x := lerpf(old_paddle.x, paddle.x, fraction)
		if absf(cross_x - paddle_x) <= PADDLE_WIDTH / 2 + RADIUS * 0.5:
			var offset := clampf((cross_x - paddle_x) / (PADDLE_WIDTH / 2), -1, 1)
			var speed := minf(640 + score * 7, 850)
			var movement := clampf((paddle.x - old_paddle.x) / dt, -450, 450)
			velocity.x = clampf(offset * 290 + movement * 0.12, -340, 340)
			velocity.y = -sqrt(speed * speed - velocity.x * velocity.x)
			ball.y = paddle.y - RADIUS - 0.5
			score += 1
			bounce_flash = 0.2
			hit = true
	lost = ball.y - RADIUS > size.y
	return hit
