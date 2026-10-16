class_name PlaySession
extends RefCounted

# The Classic physics model stays unchanged. Reverse Mode is a coordinate
# projection of that same model, including its collision plane and loss edge.
const Physics = preload("res://scripts/ball_sim.gd")
enum GameMode { CLASSIC, REVERSE }
var core := Physics.new()
var game_mode := GameMode.CLASSIC
var arena_size := Vector2(480, 800)

var ball: Vector2:
	get: return to_world(core.ball)
	set(value): core.ball = to_world(value)
var velocity: Vector2:
	get: return vector_to_world(core.velocity)
	set(value): core.velocity = vector_to_world(value)
var paddle: Vector2:
	get: return to_world(core.paddle)
	set(value): core.paddle = to_world(value)
var score: int:
	get: return core.score
	set(value): core.score = value
var lost: bool:
	get: return core.lost
var bounce_flash: float:
	get: return core.bounce_flash
var gravity: Vector2:
	get: return vector_to_world(Vector2(0, Physics.GRAVITY))

func is_reverse() -> bool:
	return game_mode == GameMode.REVERSE

func to_world(point: Vector2) -> Vector2:
	return Vector2(point.x, arena_size.y - point.y) if is_reverse() else point

func vector_to_world(vector: Vector2) -> Vector2:
	return Vector2(vector.x, -vector.y) if is_reverse() else vector

func paddle_rect() -> Rect2:
	var top := paddle.y - 16 if is_reverse() else paddle.y
	return Rect2(Vector2(paddle.x - Physics.PADDLE_WIDTH / 2, top), Vector2(Physics.PADDLE_WIDTH, 16))

func reset(size: Vector2, selected_mode: GameMode = GameMode.CLASSIC) -> void:
	arena_size = size
	game_mode = selected_mode
	core.reset(size)

func step(dt: float, target_x: float, size: Vector2) -> bool:
	arena_size = size
	return core.step(dt, target_x, size)
