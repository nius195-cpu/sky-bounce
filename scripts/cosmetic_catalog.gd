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
	{"id":"ball_electric", "category":"ball", "name":"Electric Blue", "score":40, "style":"solid", "color":"238bff"},
	{"id":"paddle_ocean", "category":"paddle", "name":"Ocean Blue", "score":50, "style":"solid", "color":"168af5"},
	{"id":"background_ocean", "category":"background", "name":"Deep Ocean", "score":65, "style":"ocean", "color":"082d50"},
	{"id":"ball_neon", "category":"ball", "name":"Neon Green", "score":80, "style":"solid", "color":"72ff3c"},
	{"id":"paddle_lime", "category":"paddle", "name":"Lime Green", "score":100, "style":"solid", "color":"b9ff30"},
	{"id":"background_city", "category":"background", "name":"Neon City", "score":125, "style":"city", "color":"13172d"},
	{"id":"ball_golden", "category":"ball", "name":"Golden Yellow", "score":150, "style":"solid", "color":"ffdc24"},
	{"id":"paddle_sunset", "category":"paddle", "name":"Sunset Orange", "score":175, "style":"solid", "color":"ff964b"},
	{"id":"background_space", "category":"background", "name":"Outer Space", "score":200, "style":"space", "color":"211337"},
	{"id":"ball_royal", "category":"ball", "name":"Royal Purple", "score":250, "style":"solid", "color":"934dff"},
	{"id":"paddle_midnight", "category":"paddle", "name":"Midnight Purple", "score":300, "style":"solid", "color":"673db5"},
	{"id":"background_forest", "category":"background", "name":"Emerald Forest", "score":350, "style":"forest", "color":"10372e"},
]

const PREMIUM := [
	{"id":"ball_galaxy", "category":"ball", "name":"Galaxy Ball", "score":0, "premium":true, "style":"galaxy", "color":"a888ff"},
	{"id":"ball_rainbow", "category":"ball", "name":"Rainbow Ball", "score":0, "premium":true, "style":"rainbow", "color":"ff8ad8"},
	{"id":"ball_fireball", "category":"ball", "name":"Fireball", "score":0, "premium":true, "style":"fireball", "color":"ff7335"},
	{"id":"ball_chrome", "category":"ball", "name":"Chrome Ball", "score":0, "premium":true, "style":"chrome", "color":"d7e5ee"},
	{"id":"paddle_pulse", "category":"paddle", "name":"Neon Pulse Paddle", "score":0, "premium":true, "style":"pulse", "color":"60ffe0"},
	{"id":"paddle_gold", "category":"paddle", "name":"Gold Rush Paddle", "score":0, "premium":true, "style":"gold", "color":"edbd42"},
	{"id":"paddle_grid", "category":"paddle", "name":"Cyber Grid Paddle", "score":0, "premium":true, "style":"grid", "color":"38d1ff"},
	{"id":"background_cyberpunk", "category":"background", "name":"Cyberpunk Skyline", "score":0, "premium":true, "style":"cyberpunk", "color":"1c1334"},
	{"id":"background_aurora", "category":"background", "name":"Aurora Nights", "score":0, "premium":true, "style":"aurora", "color":"0b2534"},
	{"id":"background_retro", "category":"background", "name":"Retro Arcade", "score":0, "premium":true, "style":"retro", "color":"221237"},
]

static func all_items() -> Array:
	return FREE + PREMIUM

static func item(id: String) -> Dictionary:
	for entry in all_items():
		if entry.id == id:
			return entry
	return {}

static func items(category: String) -> Array:
	return all_items().filter(func(entry): return entry.category == category)
