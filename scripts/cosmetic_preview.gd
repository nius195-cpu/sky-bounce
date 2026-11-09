extends Control

const Painter = preload("res://scripts/cosmetic_painter.gd")
var entry: Dictionary
var time := 0.0

func _init(item: Dictionary = {}) -> void:
	entry = item
	custom_minimum_size = Vector2(0, 84)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _process(dt: float) -> void:
	time += dt
	queue_redraw()

func _draw() -> void:
	if entry.is_empty():
		return
	draw_style_box(preview_style(), Rect2(Vector2.ZERO, size))
	match entry.category:
		"ball": Painter.ball(self, size / 2, 19, entry, time)
		"paddle": Painter.paddle(self, Rect2(size / 2 - Vector2(65, 8), Vector2(130, 16)), entry, time)
		"background": Painter.background(self, size, entry, time)

func preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1530")
	style.set_corner_radius_all(12)
	return style
