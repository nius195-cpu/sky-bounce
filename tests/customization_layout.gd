extends RefCounted
const Catalog = preload("res://scripts/cosmetic_catalog.gd")
const Progress = preload("res://scripts/cosmetic_progress.gd")
const Layout = preload("res://tests/menu_layout.gd")

func run(tree: SceneTree, check: Callable) -> void:
	var old_size := tree.root.size
	var old_scale := tree.root.content_scale_size
	var old_mode := tree.root.content_scale_mode
	tree.root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	tree.root.content_scale_size = Vector2i.ZERO
	var game = load("res://main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.cosmetics.load_config(ConfigFile.new(), 0)
	for dimensions in [Vector2i(320,568),Vector2i(480,800),Vector2i(768,1024)]:
		tree.root.size = dimensions
		await tree.process_frame
		for category in ["ball", "paddle", "background", "store"]:
			game.show_customization(category)
			for frame in range(8):
				await tree.process_frame
			var controls: Array[Control] = Layout.new().text_controls(game.overlay)
			var clear := not controls.is_empty()
			var inside := true
			var locked := true
			for i in range(controls.size()):
				var rect: Rect2 = controls[i].get_global_rect()
				inside = inside and rect.position.x >= -1 and rect.end.x <= dimensions.x + 1
				for j in range(i+1, controls.size()):
					clear = clear and not rect.intersects(controls[j].get_global_rect())
				if controls[i] is Button:
					inside = inside and controls[i].size.y >= 48
					if controls[i].text == "Locked":
						locked = locked and controls[i].disabled
			check.call(clear and inside, "Customization has no overlapping text or clipped controls: %s %s" % [dimensions,category])
			check.call(locked, "Locked cosmetic cards cannot be tapped to equip: %s %s" % [dimensions,category])
	game.queue_free()
	await tree.process_frame
	tree.root.content_scale_size = old_scale
	tree.root.content_scale_mode = old_mode
	tree.root.size = old_size
