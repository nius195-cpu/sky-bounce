extends RefCounted
const Catalog = preload("res://scripts/cosmetic_catalog.gd")
const Progress = preload("res://scripts/cosmetic_progress.gd")
const Store = preload("res://scripts/progress_store.gd")

func run(tree: SceneTree, check: Callable) -> void:
	for category in Catalog.CATEGORIES:
		check.call(Catalog.items(category).filter(func(entry): return not entry.get("premium", false)).size() == 6, "Five free %s cosmetics plus the original" % category)
	for entry in Catalog.FREE:
		if entry.score == 0:
			continue
		var progress := Progress.new()
		progress.load_config(ConfigFile.new(), 0)
		progress.record_score(entry.score - 1)
		check.call(not progress.is_unlocked(entry.id) and not progress.equip(entry.id), "Locked before threshold: " + entry.name)
		progress.record_score(entry.score)
		check.call(progress.is_unlocked(entry.id) and progress.equip(entry.id), "Unlocks and equips exactly at threshold: " + entry.name)
	var progress := Progress.new()
	progress.load_config(ConfigFile.new(), 50)
	check.call(progress.highest_score == 50 and progress.is_unlocked("paddle_ocean"), "Legacy best migrates into cosmetic progression")
	check.call(progress.next_unlock().id == "background_ocean", "Next reward follows the exact progression table")
	check.call(not progress.equip("unknown_id"), "Unknown cosmetic cannot be equipped")
	progress.record_score(1000)
	progress.equip("ball_royal")
	progress.equip("paddle_midnight")
	progress.equip("background_forest")
	var saved := ConfigFile.new()
	progress.write_config(saved)
	var restored := Progress.new()
	restored.load_config(saved, 0)
	check.call(restored.unlocked.size() == 18 and restored.next_unlock().is_empty(), "All free unlocks persist across restart")
	check.call(restored.equipped == progress.equipped, "One equipped cosmetic per category persists")
	restored.record_score(2)
	check.call(restored.highest_score == 1000 and restored.is_unlocked("background_forest"), "A new low-score run never relocks rewards")
	var malformed := ConfigFile.new()
	malformed.set_value("cosmetics", "ball", "background_forest")
	restored.load_config(malformed, 0)
	check.call(restored.equipped.ball == "ball_default", "Invalid or locked saved equipment falls back safely")
	var path := "user://cosmetic-save-test.cfg"
	var first := ConfigFile.new()
	first.set_value("test", "value", 1)
	check.call(Store.write_file(first, path) == OK, "Safe save writes a valid config")
	first.set_value("test", "value", 2)
	check.call(Store.write_file(first, path) == OK and Store.load_file(path).get_value("test", "value") == 2, "Safe save atomically replaces an existing config")
	var broken := FileAccess.open(path, FileAccess.WRITE)
	broken.store_string("[broken")
	broken.close()
	check.call(Store.load_file(path).get_value("test", "value") == 1, "Corrupt primary save recovers the last valid backup")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var original_save := Store.load_file()
	var game = load("res://main.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	game.set_process(false)
	game.set_physics_process(false)
	game.cosmetics.load_config(ConfigFile.new(), 1000)
	for category in Catalog.CATEGORIES:
		game.show_customization(category)
		for frame in range(6):
			await tree.process_frame
		var buttons: Array[Node] = game.overlay.find_children("*", "Button", true, false)
		check.call(buttons.size() >= 10, "Customization tab has touchscreen equip controls: " + category)
	game.equip_cosmetic("ball_crimson")
	check.call(game.cosmetics.equipped.ball == "ball_crimson", "Customization equips an unlocked ball")
	game.start_game()
	check.call(game.ball_tint == Color("e63950"), "Equipped ball color appears immediately in gameplay")
	check.call(game.sim.core.score == 0 and game.sim.core.velocity == Vector2(105, 0), "Cosmetics do not change game mechanics")
	game.queue_free()
	await tree.process_frame
	Store.write_file(original_save)
