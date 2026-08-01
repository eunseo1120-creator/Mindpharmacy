extends Control

const PHARMACY_TEXTURE := preload("res://assets/backgrounds/pharmacy/main-v1.webp")

var scene_id := "pharmacy"
var solved_flags: Dictionary = {}
var texture_cache: Dictionary = {}

const INK := Color("#211a18")
const PAPER := Color("#d7c39b")
const GOLD := Color("#d6ad5c")
const WALL := Color("#75604d")
const DARK_WALL := Color("#3c3531")
const WOOD := Color("#4a3327")
const SHADOW := Color(0.08, 0.06, 0.05, 0.48)


func set_scene(next_scene_id: String, flags: Dictionary) -> void:
	scene_id = next_scene_id
	solved_flags = flags
	queue_redraw()


func _draw() -> void:
	var size := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	var inner := Rect2(size * Vector2(0.01, 0.014), size * Vector2(0.98, 0.972))
	_draw_room(inner)
	_draw_grain(inner)
	_draw_soft_edge(inner)


func _draw_room(rect: Rect2) -> void:
	var generated_texture := _get_generated_texture()
	if generated_texture != null:
		draw_texture_rect(generated_texture, rect, false)
		return
	match scene_id:
		"pharmacy":
			_draw_pharmacy(rect)
		"childhood_front":
			_draw_childhood_front(rect)
		"childhood_right":
			_draw_childhood_right(rect)
		"childhood_back":
			_draw_childhood_back(rect)
		"childhood_left":
			_draw_childhood_left(rect)
		"school_front", "school_right", "school_back", "school_left":
			_draw_school(rect, scene_id.trim_prefix("school_"))
		"adult_front", "adult_right", "adult_back", "adult_left":
			_draw_adult(rect, scene_id.trim_prefix("adult_"))
		"truth_front", "truth_right", "truth_back", "truth_left":
			_draw_truth(rect, scene_id.trim_prefix("truth_"))
		_:
			_draw_pharmacy(rect)


func _get_generated_texture() -> Texture2D:
	var path := ""
	if scene_id == "pharmacy":
		path = "res://assets/backgrounds/pharmacy_v2/front.png"
	elif scene_id.begins_with("pharmacy_"):
		path = "res://assets/backgrounds/pharmacy_v2/" + scene_id.trim_prefix("pharmacy_") + ".png"
	elif scene_id.begins_with("childhood_"):
		if scene_id == "childhood_front" and solved_flags.get("alphabet_book_collected", false):
			path = "res://assets/backgrounds/childhood/front-no-x-book.png"
		elif scene_id == "childhood_back" and solved_flags.get("childhood_complete", false):
			path = "res://assets/backgrounds/childhood/back-open.jpg"
		else:
			path = "res://assets/backgrounds/childhood/" + scene_id.trim_prefix("childhood_") + ".png"
	elif scene_id.begins_with("school_"):
		path = "res://assets/backgrounds/school/" + scene_id.trim_prefix("school_") + ".png"
	elif scene_id.begins_with("adult_"):
		path = "res://assets/backgrounds/adult/" + scene_id.trim_prefix("adult_") + ".png"
	elif scene_id.begins_with("truth_"):
		path = "res://assets/backgrounds/truth/" + scene_id.trim_prefix("truth_") + ".png"
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if not texture_cache.has(path):
		texture_cache[path] = load(path)
	return texture_cache[path] as Texture2D


func _draw_background(rect: Rect2, wall_color: Color = WALL) -> void:
	draw_rect(rect, wall_color)
	var floor_top := rect.position.y + rect.size.y * 0.72
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x, floor_top),
		Vector2(rect.end.x, floor_top),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]), Color("#392a24"))
	draw_line(
		Vector2(rect.position.x, floor_top),
		Vector2(rect.end.x, floor_top),
		Color("#1d1715"),
		4.0
	)


func _draw_pharmacy(rect: Rect2) -> void:
	draw_texture_rect(PHARMACY_TEXTURE, rect, false)
	draw_rect(rect, Color(0.07, 0.045, 0.025, 0.08))
	var mailbox := Rect2(
		rect.position + rect.size * Vector2(0.88, 0.34),
		rect.size * Vector2(0.1, 0.19)
	)
	if not solved_flags.get("letter_opened", false):
		for grow_size in [2.0, 8.0, 15.0]:
			draw_style_box(
				_glow_box(Color(0.95, 0.76, 0.32, 0.38 / (grow_size / 4.0 + 1.0))),
				mailbox.grow(grow_size)
			)


func _draw_childhood_front(rect: Rect2) -> void:
	_draw_background(rect, Color("#5b5048"))
	var door := Rect2(
		rect.position + rect.size * Vector2(0.35, 0.06),
		rect.size * Vector2(0.3, 0.67)
	)
	draw_rect(door, Color("#332923"))
	draw_rect(door.grow(-12), Color("#594638"))
	draw_line(
		Vector2(door.position.x + door.size.x * 0.5, door.position.y),
		Vector2(door.position.x + door.size.x * 0.5, door.end.y),
		Color("#291f1b"),
		4.0
	)
	draw_circle(door.position + door.size * Vector2(0.84, 0.55), 8.0, GOLD)
	if solved_flags.get("childhood_complete", false):
		draw_rect(door.grow(-22), Color("#d8bd76"))
	var phone_base := rect.position + rect.size * Vector2(0.74, 0.58)
	draw_rect(Rect2(phone_base, rect.size * Vector2(0.12, 0.1)), Color("#292523"))
	draw_circle(phone_base + rect.size * Vector2(0.06, 0.035), 24.0, PAPER)
	draw_circle(phone_base + rect.size * Vector2(0.06, 0.035), 10.0, Color("#292523"))
	draw_line(phone_base + Vector2(-6, -8), phone_base + Vector2(110, -8), INK, 13.0)


func _draw_childhood_right(rect: Rect2) -> void:
	_draw_background(rect, Color("#66594d"))
	var rug := Rect2(
		rect.position + rect.size * Vector2(0.17, 0.69),
		rect.size * Vector2(0.65, 0.18)
	)
	draw_colored_polygon(PackedVector2Array([
		rug.position + Vector2(rug.size.x * 0.12, 0),
		rug.position + Vector2(rug.size.x * 0.88, 0),
		rug.end,
		Vector2(rug.position.x, rug.end.y)
	]), Color("#7d563c"))
	if not solved_flags.get("bear_collected", false):
		var bear := rect.position + rect.size * Vector2(0.22, 0.68)
		draw_circle(bear, 38.0, Color("#c3b18e"))
		draw_circle(bear + Vector2(-28, -28), 16.0, Color("#c3b18e"))
		draw_circle(bear + Vector2(28, -28), 16.0, Color("#c3b18e"))
		draw_circle(bear + Vector2(-12, -7), 3.0, INK)
		draw_circle(bear + Vector2(12, -7), 3.0, INK)
		draw_line(bear + Vector2(-20, 18), bear + Vector2(20, 3), Color("#8f3e38"), 5.0)
	var train_pos := rect.position + rect.size * Vector2(0.58, 0.67)
	draw_rect(Rect2(train_pos, rect.size * Vector2(0.17, 0.08)), Color("#744a38"))
	draw_rect(Rect2(train_pos + Vector2(35, -42), rect.size * Vector2(0.07, 0.05)), Color("#5f7b6c"))
	draw_circle(train_pos + Vector2(35, 75), 18.0, INK)
	draw_circle(train_pos + Vector2(115, 75), 18.0, INK)
	for index in range(3):
		var block_pos := rect.position + rect.size * Vector2(0.45 + index * 0.035, 0.79)
		draw_rect(Rect2(block_pos, Vector2(28, 28)), [Color("#b45448"), GOLD, Color("#5f7b6c")][index])


func _draw_childhood_back(rect: Rect2) -> void:
	_draw_background(rect, Color("#51463f"))
	var wardrobe := Rect2(
		rect.position + rect.size * Vector2(0.57, 0.13),
		rect.size * Vector2(0.29, 0.59)
	)
	draw_rect(wardrobe, WOOD)
	draw_rect(wardrobe.grow(-10), Color("#4b382e"))
	draw_line(
		Vector2(wardrobe.get_center().x, wardrobe.position.y + 10),
		Vector2(wardrobe.get_center().x, wardrobe.end.y - 10),
		Color("#261e1b"),
		4.0
	)
	draw_circle(wardrobe.get_center() + Vector2(-12, 0), 5, GOLD)
	draw_circle(wardrobe.get_center() + Vector2(12, 0), 5, GOLD)
	var drawers := Rect2(
		rect.position + rect.size * Vector2(0.12, 0.47),
		rect.size * Vector2(0.26, 0.25)
	)
	draw_rect(drawers, Color("#48352c"))
	for index in range(3):
		var y := drawers.position.y + index * drawers.size.y / 3.0
		draw_line(Vector2(drawers.position.x, y), Vector2(drawers.end.x, y), INK, 3)
		draw_circle(Vector2(drawers.get_center().x, y + drawers.size.y / 6.0), 4, GOLD)


func _draw_childhood_left(rect: Rect2) -> void:
	_draw_background(rect, Color("#62564a"))
	var window := Rect2(
		rect.position + rect.size * Vector2(0.58, 0.12),
		rect.size * Vector2(0.23, 0.28)
	)
	draw_rect(window, Color("#262c31"))
	draw_rect(window.grow(-8), Color("#56636b"))
	draw_line(
		Vector2(window.get_center().x, window.position.y),
		Vector2(window.get_center().x, window.end.y),
		INK,
		5
	)
	var bed := Rect2(
		rect.position + rect.size * Vector2(0.37, 0.58),
		rect.size * Vector2(0.5, 0.18)
	)
	draw_rect(bed, Color("#aa9474"))
	draw_rect(Rect2(bed.position + Vector2(0, bed.size.y * 0.65), Vector2(bed.size.x, bed.size.y * 0.35)), Color("#62503f"))
	var shelf := Rect2(
		rect.position + rect.size * Vector2(0.07, 0.19),
		rect.size * Vector2(0.2, 0.48)
	)
	draw_rect(shelf, WOOD)
	for row in range(3):
		for column in range(4):
			var book := Rect2(
				shelf.position + Vector2(12 + column * shelf.size.x / 4.0, 18 + row * shelf.size.y / 3.0),
				Vector2(24, shelf.size.y / 3.0 - 28)
			)
			draw_rect(book, [Color("#8d5540"), Color("#68775a"), Color("#c1a45f"), Color("#594b60")][column])


func _draw_school(rect: Rect2, direction: String) -> void:
	_draw_background(rect, Color("#714b4e"))
	var sunset := Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.72))
	draw_rect(sunset, Color(0.45, 0.12, 0.12, 0.18))
	if direction == "front":
		var board := Rect2(rect.position + rect.size * Vector2(0.1, 0.16), rect.size * Vector2(0.5, 0.38))
		draw_rect(board, Color("#27342d"))
		for row in range(3):
			for col in range(6):
				var eye := board.position + Vector2(35 + col * board.size.x / 6.0, 45 + row * board.size.y / 3.0)
				draw_arc(eye, 13, 0, PI, 16, Color("#bfb49c"), 2)
				draw_circle(eye, 3, Color("#c86555"))
		var door := Rect2(rect.position + rect.size * Vector2(0.72, 0.13), rect.size * Vector2(0.18, 0.59))
		draw_rect(door, Color("#46342f"))
		draw_circle(door.position + door.size * Vector2(0.18, 0.52), 6, GOLD)
	elif direction == "right":
		for index in range(3):
			var desk := Rect2(rect.position + rect.size * Vector2(0.16 + index * 0.23, 0.46 + index * 0.06), rect.size * Vector2(0.25, 0.15))
			draw_rect(desk, Color("#68483a"))
			draw_line(desk.position + Vector2(18, 25), desk.end - Vector2(25, 18), Color("#241a18"), 3)
	elif direction == "back":
		var locker := Rect2(rect.position + rect.size * Vector2(0.5, 0.12), rect.size * Vector2(0.36, 0.6))
		draw_rect(locker, Color("#766f62"))
		for x in range(3):
			for y in range(3):
				var cell := Rect2(locker.position + Vector2(x * locker.size.x / 3.0, y * locker.size.y / 3.0), locker.size / 3.0)
				draw_rect(cell.grow(-3), Color("#625d54"), false, 2)
		draw_string(ThemeDB.fallback_font, locker.position + Vector2(18, 32), "314", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, PAPER)
	else:
		var window := Rect2(rect.position + rect.size * Vector2(0.1, 0.12), rect.size * Vector2(0.31, 0.42))
		draw_rect(window, Color("#a96051"))
		draw_line(window.get_center() - Vector2(window.size.x / 2, 0), window.get_center() + Vector2(window.size.x / 2, 0), INK, 4)
		var speaker := rect.position + rect.size * Vector2(0.72, 0.19)
		draw_circle(speaker, 48, Color("#342c2b"))
		for radius in [12, 24, 36]:
			draw_arc(speaker, radius, 0, TAU, 28, Color("#918579"), 2)


func _draw_adult(rect: Rect2, direction: String) -> void:
	_draw_background(rect, Color("#304654"))
	draw_rect(rect, Color(0.02, 0.12, 0.2, 0.22))
	for index in range(18):
		var y := rect.position.y + fmod(index * 71.0, rect.size.y)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y - 18), Color(0.4, 0.72, 0.82, 0.07), 2)
	if direction == "front":
		var door := Rect2(rect.position + rect.size * Vector2(0.71, 0.1), rect.size * Vector2(0.18, 0.63))
		draw_rect(door, Color("#26343a"))
		draw_circle(door.position + door.size * Vector2(0.2, 0.5), 6, Color("#8da2a6"))
		draw_rect(Rect2(rect.position + rect.size * Vector2(0.43, 0.62), Vector2(78, 24)), Color("#151b20"))
	elif direction == "right":
		var monitor := Rect2(rect.position + rect.size * Vector2(0.17, 0.22), rect.size * Vector2(0.42, 0.34))
		draw_rect(monitor, Color("#12191e"))
		if not solved_flags.get("power_off", false):
			draw_rect(monitor.grow(-12), Color("#8ab2bb"))
			draw_rect(Rect2(monitor.position + Vector2(28, 38), Vector2(monitor.size.x - 56, 24)), Color("#d6dfe0"))
			draw_rect(Rect2(monitor.position + Vector2(28, 82), Vector2(monitor.size.x - 56, 70)), Color("#ad6166"))
		var strip := Rect2(rect.position + rect.size * Vector2(0.63, 0.7), rect.size * Vector2(0.22, 0.06))
		draw_rect(strip, Color("#dad4c5"))
		for x in range(4):
			draw_circle(strip.position + Vector2(25 + x * 42, strip.size.y / 2), 7, Color("#393f43"))
	elif direction == "back":
		for index in range(8):
			var p := rect.position + rect.size * Vector2(0.1 + fmod(index * 0.17, 0.75), 0.64 + fmod(index * 0.07, 0.18))
			draw_colored_polygon(PackedVector2Array([p, p + Vector2(35, -12), p + Vector2(50, 24), p + Vector2(8, 32)]), Color("#625c55"))
		var note := Rect2(rect.position + rect.size * Vector2(0.54, 0.43), rect.size * Vector2(0.27, 0.2))
		draw_rect(note, Color("#b0a68f"))
		for y in range(4):
			draw_line(note.position + Vector2(18, 28 + y * 24), note.end - Vector2(18, note.size.y - 28 - y * 24), Color("#4d5e66"), 2)
	else:
		if solved_flags.get("power_off", false):
			for index in range(9):
				var p := rect.position + rect.size * Vector2(0.13 + fmod(index * 0.19, 0.56), 0.13 + fmod(index * 0.11, 0.28))
				draw_circle(p, 4, Color("#d7df9c"))
		var pot := rect.position + rect.size * Vector2(0.77, 0.67)
		draw_colored_polygon(PackedVector2Array([pot + Vector2(-35, -20), pot + Vector2(35, -20), pot + Vector2(24, 45), pot + Vector2(-24, 45)]), Color("#735243"))
		draw_line(pot + Vector2(0, -18), pot + Vector2(0, -72), Color("#56674f"), 6)
		if solved_flags.get("plant_watered", false):
			draw_arc(pot + Vector2(-14, -66), 18, -PI * 0.2, PI * 0.8, 14, Color("#8eaa75"), 7)


func _draw_truth(rect: Rect2, direction: String) -> void:
	_draw_background(rect, Color("#4b4038"))
	draw_rect(rect, Color(0.16, 0.11, 0.08, 0.22))
	if direction == "front":
		var mirror := Rect2(rect.position + rect.size * Vector2(0.35, 0.08), rect.size * Vector2(0.3, 0.65))
		draw_rect(mirror.grow(14), Color("#241d1a"))
		draw_rect(mirror, Color("#7b8583"))
		draw_circle(mirror.position + mirror.size * Vector2(0.5, 0.23), 35, Color(0.85, 0.78, 0.66, 0.48))
		draw_colored_polygon(PackedVector2Array([mirror.position + mirror.size * Vector2(0.38, 0.34), mirror.position + mirror.size * Vector2(0.62, 0.34), mirror.position + mirror.size * Vector2(0.72, 0.85), mirror.position + mirror.size * Vector2(0.28, 0.85)]), Color(0.87, 0.84, 0.76, 0.35))
	elif direction == "right":
		for index in range(3):
			var record := Rect2(rect.position + rect.size * Vector2(0.17 + index * 0.23, 0.43), rect.size * Vector2(0.18, 0.23))
			draw_rect(record, [Color("#bca883"), Color("#9b745f"), Color("#303b42")][index])
	elif direction == "back":
		var door := Rect2(rect.position + rect.size * Vector2(0.35, 0.08), rect.size * Vector2(0.3, 0.65))
		draw_rect(door, Color("#2d251f"))
		if solved_flags.get("heart_key_made", false):
			for width in [28.0, 18.0, 8.0]:
				draw_rect(door.grow(width), Color(0.92, 0.72, 0.32, 0.08), false, 4)
		draw_circle(door.position + door.size * Vector2(0.82, 0.53), 8, GOLD)
	else:
		var counter := Rect2(rect.position + rect.size * Vector2(0.13, 0.52), rect.size * Vector2(0.72, 0.21))
		draw_rect(counter, Color("#4b3429"))
		for index in range(3):
			_draw_bottle(counter.position + Vector2(160 + index * 150, 5), 0.55, Color(0.32, 0.28, 0.25, 0.55))


func _draw_bottle(position: Vector2, scale_value: float, color: Color) -> void:
	draw_rect(Rect2(position + Vector2(-12, -55) * scale_value, Vector2(24, 34) * scale_value), color)
	draw_circle(position, 34 * scale_value, color)
	draw_rect(Rect2(position + Vector2(-8, -80) * scale_value, Vector2(16, 25) * scale_value), PAPER)


func _draw_grain(rect: Rect2) -> void:
	var seed_value := scene_id.hash()
	for index in range(90):
		seed_value = int((seed_value * 1103515245 + 12345) & 0x7fffffff)
		var x := rect.position.x + float(seed_value % 1000) / 1000.0 * rect.size.x
		seed_value = int((seed_value * 1103515245 + 12345) & 0x7fffffff)
		var y := rect.position.y + float(seed_value % 1000) / 1000.0 * rect.size.y
		draw_circle(Vector2(x, y), 1.2, Color(0.1, 0.08, 0.07, 0.1))


func _draw_soft_edge(rect: Rect2) -> void:
	for index in range(18):
		var inset := float(index) * 2.2
		var alpha := 0.12 * (1.0 - float(index) / 18.0)
		draw_rect(
			rect.grow(-inset),
			Color(0, 0, 0, alpha),
			false,
			5.0
		)


func _glow_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = color
	style.set_border_width_all(3)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
