extends RefCounted

const Catalog = preload("res://scripts/cosmetic_catalog.gd")
const Preview = preload("res://scripts/cosmetic_preview.gd")
var game: Node
var category := "ball"

func _init(owner_game: Node = null, initial_category := "ball") -> void:
	game = owner_game
	category = initial_category

func build() -> void:
	var column: VBoxContainer = game.menu_column()
	game.menu_label(column, "YOUR STYLE", 18, Color("62e7d4"))
	game.menu_label(column, "Customize", 32)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	column.add_child(tabs)
	for key in Catalog.CATEGORIES:
		var title: String = {"ball":"Balls", "paddle":"Paddles", "background":"Backgrounds"}[key]
		var tab: Button = game.button_at(tabs, title, Vector2.ZERO, 100, game.show_customization.bind(key), key == category)
		tab.custom_minimum_size = Vector2(0, 54)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 15)
	var progress = game.cosmetics
	var next: Dictionary = progress.next_unlock()
	if next.is_empty():
		game.menu_label(column, "All score rewards unlocked!", 17)
	else:
		game.menu_label(column, "Next: %s at %d points\nHighest score: %d / %d" % [next.name, next.score, progress.highest_score, next.score], 16)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 16
		bar.max_value = next.score
		bar.value = progress.highest_score
		bar.show_percentage = false
		column.add_child(bar)
	for entry in Catalog.items(category):
		var panel := PanelContainer.new()
		var skin := StyleBoxFlat.new()
		skin.bg_color = Color("182440")
		skin.set_corner_radius_all(14)
		skin.content_margin_left = 14
		skin.content_margin_right = 14
		skin.content_margin_top = 14
		skin.content_margin_bottom = 14
		panel.add_theme_stylebox_override("panel", skin)
		column.add_child(panel)
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 10)
		panel.add_child(card)
		card.add_child(Preview.new(entry))
		game.menu_label(card, entry.name, 21)
		var unlocked: bool = progress.is_unlocked(entry.id)
		var equipped: bool = progress.equipped[category] == entry.id
		var premium: bool = entry.get("premium", false)
		var status := "Equipped" if equipped else ("Unlocked" if unlocked else "Locked · Reach %d points" % entry.score)
		if premium:
			status = ("Premium · Owned" if progress.premium_owned else "Premium · Ultimate Style Pack") + (" · Equipped" if equipped else "")
		game.menu_label(card, status, 16, Color("62e7d4") if unlocked else Color("a7b8dc"))
		var button: Button = game.menu_button(card, "Equipped" if equipped else ("Equip" if unlocked else "Locked"), game.equip_cosmetic.bind(entry.id), unlocked)
		# Cards size themselves through the parent rather than their own minimum width.
		button.custom_minimum_size.x = 180
		button.disabled = not unlocked or equipped
	game.menu_label(column, "Ultimate Style Pack", 24, Color("ffce68"))
	game.menu_label(column, "10 exclusive styles · One-time purchase\nCosmetic only. No gameplay advantage.", 16)
	var billing = game.billing
	var text: String = "Owned" if progress.premium_owned else ("Buy pack · " + billing.price_label if not billing.price_label.is_empty() else "Purchase unavailable")
	var buy: Button = game.menu_button(column, text, billing.buy, true)
	buy.disabled = not billing.can_buy()
	game.menu_button(column, "Restore Purchases", billing.restore)
	game.menu_label(column, billing.status, 15, Color("a7b8dc"))
	game.menu_button(column, "Back", game.show_menu)
