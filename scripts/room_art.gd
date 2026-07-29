extends Control

const PHARMACY_TEXTURE := preload("res://assets/backgrounds/pharmacy/main-v1.webp")

var scene_id := "pharmacy"
var solved_flags: Dictionary = {}

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
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	var frame := Rect2(size * Vector2(0.015, 0.02), size * Vector2(0.97, 0.96))
	draw_rect(frame, Color("#b59969"))
	var inner := frame.grow(-10.0)
	draw_rect(inner, DARK_WALL)
	_draw_room(inner)
	_draw_grain(inner)


func _draw_room(rect: Rect2) -> void:
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
		_:
			_draw_pharmacy(rect)


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
