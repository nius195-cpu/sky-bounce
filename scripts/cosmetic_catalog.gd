class_name CosmeticCatalog
extends RefCounted

const CATEGORIES := ["ball", "paddle", "background"]
const DEFAULTS := {"ball": "ball_default", "paddle": "paddle_default", "background": "background_default"}
const FREE := [
	{"id":"ball_default", "category":"ball", "name":"Original · Level Colors", "score":0, "style":"default", "color":"ffce68"},
	{"id":"paddle_default", "category":"paddle", "name":"Original Mint", "score":0, "style":"default", "color":"62e7d4"},
	{"id":"background_default", "category":"background", "name":"Original Star Field", "score":0, "style":"default", "color":"0d1530"},
	{"id":"ball_crimson", "category":"ball", "name":"Crimson Red", "score":10, "style":"solid", "color":"e63950"},
	{"id":"paddle_fire", "category":"paddle", "name":"Fire Red", "score":20, "style":"solid", "color":"ff514a"},
	{"id":"background_sunset", "category":"background", "name":"Sunset Sky", "score":30, "style":"sunset", "color":"713b4b"},
	{"id":"ball_electric", "category":"ball", "name":"Electric Blue", "score":50, "style":"solid", "color":"238bff"},
	{"id":"paddle_ocean", "category":"paddle", "name":"Ocean Blue", "score":75, "style":"solid", "color":"168af5"},
	{"id":"background_ocean", "category":"background", "name":"Deep Ocean", "score":100, "style":"ocean", "color":"082d50"},
	{"id":"ball_neon", "category":"ball", "name":"Neon Green", "score":150, "style":"solid", "color":"72ff3c"},
	{"id":"paddle_lime", "category":"paddle", "name":"Lime Green", "score":200, "style":"solid", "color":"b9ff30"},
	{"id":"background_city", "category":"background", "name":"Neon City", "score":250, "style":"city", "color":"13172d"},
	{"id":"ball_golden", "category":"ball", "name":"Golden Yellow", "score":350, "style":"solid", "color":"ffdc24"},
	{"id":"paddle_sunset", "category":"paddle", "name":"Sunset Orange", "score":450, "style":"solid", "color":"ff964b"},
	{"id":"background_space", "category":"background", "name":"Outer Space", "score":550, "style":"space", "color":"211337"},
	{"id":"ball_royal", "category":"ball", "name":"Royal Purple", "score":700, "style":"solid", "color":"934dff"},
	{"id":"paddle_midnight", "category":"paddle", "name":"Midnight Purple", "score":850, "style":"solid", "color":"673db5"},
	{"id":"background_forest", "category":"background", "name":"Emerald Forest", "score":1000, "style":"forest", "color":"10372e"},
]

static func all_items() -> Array:
	return FREE

static func item(id: String) -> Dictionary:
	for entry in all_items():
		if entry.id == id:
			return entry
	return {}

static func items(category: String) -> Array:
	return all_items().filter(func(entry): return entry.category == category)
