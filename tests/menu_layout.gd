extends RefCounted

const Session = preload("res://scripts/play_session.gd")

func text_controls(parent: Node) -> Array[Control]:
	var controls: Array[Control] = []
	for child in parent.get_children():
		if child is Label or child is Button:
			controls.append(child)
		controls.append_array(text_controls(child))
	return controls

func settle(tree: SceneTree) -> void:
	for frame in range(6):
		await tree.process_frame

func run(tree: SceneTree, check: Callable) -> void:
	var old_size := tree.root.size
	var old_scale_size := tree.root.content_scale_size
	var old_scale_mode := tree.root.content_scale_mode
	tree.root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	tree.root.content_scale_size = Vector2i.ZERO
	var game = load("res://main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.high_scores = {"classic": 123456789, "reverse": 987654321}
	# Include the extra warning line that used to crowd the bottom of the menu.
	game.storage_warning = true
	for viewport_size in [Vector2i(320, 568), Vector2i(480, 800), Vector2i(480, 1040), Vector2i(768, 1024)]:
		tree.root.size = viewport_size
		await tree.process_frame
		for chosen in [Session.GameMode.CLASSIC, Session.GameMode.REVERSE]:
			game.selected_mode = chosen
			for selecting in [false, true]:
				if selecting:
					game.show_mode_selection()
				else:
					game.show_menu()
				await settle(tree)
				var controls := text_controls(game.overlay)
				var non_overlapping := not controls.is_empty()
				var readable := true
				var inside_width := true
				var targets_large_enough := true
				var last_button: Button
				var screen_width: float = game.get_viewport_rect().size.x
				for i in range(controls.size()):
					var rect := controls[i].get_global_rect()
					inside_width = inside_width and rect.position.x >= 0 and rect.end.x <= screen_width + 1
					if controls[i] is Label:
						readable = readable and controls[i].size.y + 1 >= controls[i].get_combined_minimum_size().y
					if controls[i] is Button:
						targets_large_enough = targets_large_enough and controls[i].size.y >= 48
						last_button = controls[i]
					for j in range(i + 1, controls.size()):
						if rect.intersects(controls[j].get_global_rect()):
							non_overlapping = false
				var context := "%s / %s / %s" % [viewport_size, chosen, "mode selector" if selecting else "main menu"]
				check.call(non_overlapping, "Menu text and buttons do not overlap: " + context)
				check.call(readable and inside_width and targets_large_enough, "Menu wraps text without clipping and keeps full touch targets: " + context)
				# On short screens, the last button must remain reachable by scrolling.
				var scrollers: Array[Node] = game.overlay.find_children("*", "ScrollContainer", true, false)
				if not scrollers.is_empty() and last_button != null:
					var scroller := scrollers[0] as ScrollContainer
					scroller.ensure_control_visible(last_button)
					await settle(tree)
					var viewport_rect: Rect2 = scroller.get_global_rect()
					check.call(viewport_rect.has_point(last_button.get_global_rect().get_center()), "Last menu button remains reachable: " + context)
				else:
					check.call(false, "Menu has a reachable final button: " + context)
	game.queue_free()
	await tree.process_frame
	tree.root.content_scale_mode = old_scale_mode
	tree.root.content_scale_size = old_scale_size
	tree.root.size = old_size
