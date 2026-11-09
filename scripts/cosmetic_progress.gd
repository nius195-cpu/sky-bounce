class_name CosmeticProgress
extends RefCounted

const Catalog = preload("res://scripts/cosmetic_catalog.gd")
var highest_score := 0
var unlocked: Array[String] = []
var equipped := Catalog.DEFAULTS.duplicate()
var premium_owned := false
var last_store_check := 0

func load_config(save: ConfigFile, legacy_highest: int) -> void:
	highest_score = maxi(legacy_highest, maxi(0, int(save.get_value("cosmetics", "highest_score", 0))))
	unlocked.clear()
	var saved = save.get_value("cosmetics", "unlocked", [])
	if saved is Array or saved is PackedStringArray:
		for id in saved:
			var entry := Catalog.item(str(id))
			if not entry.is_empty() and not entry.get("premium", false) and not unlocked.has(str(id)):
				unlocked.append(str(id))
	premium_owned = bool(save.get_value("cosmetics", "premium_owned", false))
	last_store_check = maxi(0, int(save.get_value("cosmetics", "last_store_check", 0)))
	refresh_unlocks()
	for category in Catalog.CATEGORIES:
		var id := str(save.get_value("cosmetics", category, Catalog.DEFAULTS[category]))
		var entry := Catalog.item(id)
		equipped[category] = id if not entry.is_empty() and entry.category == category and is_unlocked(id) else Catalog.DEFAULTS[category]

func write_config(save: ConfigFile) -> void:
	save.set_value("cosmetics", "schema", 1)
	save.set_value("cosmetics", "highest_score", highest_score)
	save.set_value("cosmetics", "unlocked", unlocked)
	save.set_value("cosmetics", "premium_owned", premium_owned)
	save.set_value("cosmetics", "last_store_check", last_store_check)
	for category in Catalog.CATEGORIES:
		save.set_value("cosmetics", category, equipped[category])

func refresh_unlocks() -> Array[String]:
	var added: Array[String] = []
	for entry in Catalog.all_items():
		if not entry.get("premium", false) and int(entry.score) <= highest_score and not unlocked.has(entry.id):
			unlocked.append(entry.id)
			added.append(entry.id)
	return added

# Called by the game only after the shared simulation reports a successful hit.
# This is locally validated gameplay progress, not server-authoritative scoring.
func record_score(score: int) -> Array[String]:
	highest_score = maxi(highest_score, maxi(score, 0))
	return refresh_unlocks()

func is_unlocked(id: String) -> bool:
	var entry := Catalog.item(id)
	if entry.is_empty():
		return false
	return premium_owned if entry.get("premium", false) else unlocked.has(id)

func equip(id: String) -> bool:
	var entry := Catalog.item(id)
	if entry.is_empty() or not is_unlocked(id):
		return false
	equipped[entry.category] = id
	return true

func apply_store_entitlement(owned: bool) -> void:
	premium_owned = owned
	last_store_check = int(Time.get_unix_time_from_system())
	for category in Catalog.CATEGORIES:
		if not is_unlocked(equipped[category]):
			equipped[category] = Catalog.DEFAULTS[category]

func next_unlock() -> Dictionary:
	for entry in Catalog.all_items():
		if not entry.get("premium", false) and not is_unlocked(entry.id):
			return entry
	return {}
