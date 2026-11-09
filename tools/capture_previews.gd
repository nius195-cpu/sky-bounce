# Development-only desktop previews. tools/* is excluded from Android/iOS exports.
extends SceneTree
const Catalog = preload("res://scripts/cosmetic_catalog.gd")
const Painter = preload("res://scripts/cosmetic_painter.gd")
const Session = preload("res://scripts/play_session.gd")

class Gallery extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 1400), Color("0d1530"))
		draw_string(ThemeDB.fallback_font, Vector2(30, 36), "Sky Bounce · Cosmetic preview gallery (desktop)", HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		var all: Array = Catalog.all_items()
		for i in range(all.size()):
			var entry: Dictionary = all[i]
			var origin := Vector2(24 + (i % 4) * 234, 62 + (i / 4) * 168)
			draw_set_transform(origin)
			draw_rect(Rect2(0, 0, 214, 125), Color("17213a"))
			match entry.category:
				"ball": Painter.ball(self, Vector2(107, 62), 24, entry, 2.2)
				"paddle": Painter.paddle(self, Rect2(37, 54, 140, 16), entry, 2.2)
				"background": Painter.background(self, Vector2(214, 125), entry, 2.2)
			draw_string(ThemeDB.fallback_font, Vector2(0, 147), entry.name, HORIZONTAL_ALIGNMENT_CENTER, 214, 14, Color("eaf2ff"))
			draw_set_transform(Vector2.ZERO)

func _initialize() -> void:
	call_deferred("capture")

func settle() -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw

func save_image(name: String) -> void:
	root.get_texture().get_image().save_png("res://builds/previews/" + name + ".png")

func capture() -> void:
	if not OS.has_feature("editor"):
		quit(1)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(960, 1400)
	var gallery := Gallery.new()
	root.add_child(gallery)
	await settle()
	save_image("cosmetic-gallery")
	gallery.queue_free()
	await process_frame
	root.size = Vector2i(480, 800)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	save_image("main-menu")
	game.cosmetics.record_score(350)
	game.cosmetics.apply_store_entitlement(true) # In-memory visual fixture only; not saved or billed.
	for category in Catalog.CATEGORIES:
		game.show_customization(category)
		await settle()
		save_image("customize-" + category)
	game.cosmetics.equipped = {"ball":"ball_galaxy", "paddle":"paddle_grid", "background":"background_aurora"}
	for selected in [Session.GameMode.CLASSIC, Session.GameMode.REVERSE]:
		game.start_mode(selected)
		game.sim.ball = Vector2(240, 400)
		await settle()
		save_image("game-" + str(selected))
	game.queue_free()
	await process_frame
	quit()
