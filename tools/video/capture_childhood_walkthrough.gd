extends SceneTree

var game
var output_dir := "/tmp/mindpharmacy-childhood-capture"
var steps: Array = []
var shot_index := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output_dir = args[0]
	DirAccess.make_dir_recursive_absolute(output_dir)

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("메인 장면을 불러오지 못했습니다.")
		quit(1)
		return

	game = packed.instantiate()
	root.add_child(game)
	await _settle()
	_prepare_title_without_touching_save()

	# 시작 화면과 약방 진입
	await _click("title", _node_point(game.title_layer.find_child("TitleSettingsButton", true, false)), "ui_click", game._open_settings)
	await _click("title-settings", Vector2(640, 622), "ui_back", game._close_modal)
	await _shot("title-ready", _click_action(_node_point(game.title_layer.find_child("StartGameButton", true, false)), "ui_click", 0.75))
	_start_new_game_without_saving()

	await _turn_right("pharmacy-front")
	await _click("pharmacy-mailbox", _scene_point(0.33, 0.42), "paper_pickup", game._open_letter)
	await _click("first-letter", Vector2(640, 542), "book_open", game._enter_childhood, 0.9)

	# 정면: X 책과 그림일기
	await _click("childhood-front", _scene_point(0.17, 0.875), "ui_click", game._inspect_floor_book)
	await _click("floor-x-book", Vector2(590, 330), "book_open", game._collect_alphabet_book)
	await _click("front-after-book", _scene_point(0.405, 0.695), "ui_click", game._inspect_alphabet_bookcase)
	await _select_inventory("alphabet_book", "alphabet-bookcase")
	await _click("alphabet-book-selected", Vector2(590, 345), "soft_place", game._insert_alphabet_book)
	await _click("diary-revealed", Vector2(590, 430), "book_open", game._collect_picture_diary)
	await _back("empty-diary-compartment")
	await _select_inventory("picture_diary", "front-before-diary")
	for page in range(0, 12):
		await _click("diary-%02d" % page, Vector2(1085, 350), "page_turn", game._open_diary.bind(page + 1), 0.28)
	await _back("diary-12", 0.45)

	# 뒤쪽: 바늘, 실, 바느질 세트
	await _turn_right("front-after-diary")
	await _turn_right("right-to-back")
	await _click("back-room", _scene_point(0.185, 0.69), "ui_click", game._inspect_dresser)
	await _click("dresser-closed", Vector2(590, 355), "drawer_open", game._open_dresser)
	await _click("needle-in-drawer", Vector2(235, 150), "metal_click", game._collect_needle)
	await _back("dresser-empty")
	await _click("back-after-needle", _scene_point(0.82, 0.515), "ui_click", game._inspect_wardrobe)
	await _click("wardrobe-closed", Vector2(590, 350), "wardrobe_open", game._open_wardrobe)
	await _click("thread-in-wardrobe", Vector2(700, 420), "item_pickup", game._collect_thread)
	await _back("wardrobe-empty")
	await _drag_inventory("needle", "thread", "back-before-sewing-kit", "sewing", game._combine_dragged_items.bind("needle", "thread"))

	# 오른쪽: 곰인형 수선
	await _turn_left("back-after-sewing-kit")
	await _click("right-before-bear", _scene_point(0.525, 0.80), "ui_click", game._inspect_torn_bear)
	await _select_inventory("sewing_kit", "torn-bear")
	await _click("bear-kit-selected", Vector2(590, 395), "sewing", game._attempt_sew_bear)
	await _back("stitched-bear", 0.6)

	# 왼쪽: 곰인형을 침대 밑에 놓고 3쪽 획득
	await _turn_left("right-after-bear")
	await _turn_left("front-to-left-bed")
	await _select_inventory("repaired_bear", "left-before-bear-item")
	await _back("repaired-bear-item")
	await _click("left-bear-selected", _scene_point(0.605, 0.595), "ui_click", game._inspect_bed)
	await _click("bed-empty", Vector2(590, 470), "soft_place", game._place_bear)
	await _click("storybook-page-03", Vector2(625, 330), "paper_pickup", game._collect_storybook_page_3)
	await _back("bear-under-bed")

	# 오른쪽: 기차 단서, 블록 조합, 4쪽 획득
	await _turn_right("left-after-bed")
	await _turn_right("front-to-right-train")
	await _click("right-before-blocks", _scene_point(0.73, 0.905), "wood_connect", game._collect_blocks)
	await _click("blocks-collected", _scene_point(0.575, 0.215), "paper_pickup", game._inspect_train_photo)
	await _back("train-order-clue")
	await _drag_inventory("block_yellow", "block_blue", "right-before-train-pair", "wood_connect", game._combine_dragged_items.bind("block_yellow", "block_blue"))
	await _back("train-pair")
	await _drag_inventory("train_pair_yellow_blue", "block_red", "right-before-repaired-train", "wood_connect", game._combine_dragged_items.bind("train_pair_yellow_blue", "block_red"))
	await _back("repaired-train")
	await _select_inventory("repaired_train", "right-before-train-item")
	await _back("repaired-train-item")
	await _click("right-train-selected", _scene_point(0.79, 0.805), "train_run", game._place_train_on_rail)
	await _click("storybook-page-04", Vector2(590, 330), "paper_pickup", game._collect_storybook_page_4)

	# 왼쪽: 구두 240과 엄마의 쪽지
	await _turn_left("right-after-page-04")
	await _turn_left("front-to-left-shoes")
	await _click("left-before-shoes", _scene_point(0.87, 0.63), "ui_click", game._inspect_shoe_cabinet)
	await _click("shoe-cabinet-locked", Vector2(790, 420), "ui_click", game._inspect_old_shoe)
	await _back("shoe-size-240", 0.6)
	await _click("left-after-shoe", _scene_point(0.87, 0.63), "ui_click", game._inspect_shoe_cabinet)
	await _click("shoe-cabinet-again", Vector2(345, 360), "ui_click", game._show_shoe_keypad)
	await _modal_digit("2")
	await _modal_digit("4")
	await _modal_digit("0", 0.55)
	await _click("shoe-cabinet-open", Vector2(325, 340), "paper_pickup", game._reveal_mother_note)
	await _back("mother-note", 0.75)

	# 오른쪽: 빈 리모컨
	await _turn_right("left-after-note")
	await _turn_right("front-to-right-remote")
	await _click("right-before-tv-drawer", _scene_point(0.28, 0.67), "ui_click", game._inspect_tv_drawer)
	await _click("tv-drawer-closed", Vector2(590, 455), "drawer_open", game._open_tv_drawer)
	await _click("empty-remote-in-drawer", Vector2(590, 445), "item_pickup", game._collect_empty_remote)
	await _back("tv-drawer-empty")

	# 왼쪽: 소파 건전지 → 반드시 방으로 복귀 → 시계 건전지
	await _turn_left("right-after-remote")
	await _turn_left("front-to-left-batteries")
	await _click("left-before-sofa", _scene_point(0.235, 0.575), "ui_click", game._inspect_sofa)
	await _click("sofa-cushion", Vector2(590, 335), "soft_place", game._lift_sofa_cushion)
	await _click("sofa-battery", Vector2(495, 340), "metal_click", game._collect_sofa_battery)
	await _back("sofa-battery-collected", 0.45)
	await _click("left-room-after-sofa", _scene_point(0.24, 0.24), "ui_click", game._inspect_clock)
	await _click("clock-front", Vector2(590, 330), "metal_click", game._turn_clock)
	await _click("clock-battery", Vector2(535, 315), "metal_click", game._collect_clock_battery)
	await _back("clock-battery-collected", 0.45)

	# 왼쪽 방 인벤토리에서 건전지 두 개를 리모컨에 직접 드래그
	await _drag_inventory("battery_1", "empty_remote", "left-before-first-battery", "metal_click", game._combine_dragged_items.bind("battery_1", "empty_remote"))
	await _drag_inventory("battery_2", "remote_one_battery", "left-before-second-battery", "tv_button", game._combine_dragged_items.bind("battery_2", "remote_one_battery"))
	await _back("powered-remote")

	# 오른쪽: 리모컨 선택 후 TV를 눌러 실제로 0→14 조절
	await _turn_right("left-after-remote-complete")
	await _turn_right("front-to-right-tv")
	await _select_inventory("powered_remote", "right-before-powered-remote-item")
	await _back("powered-remote-item")
	await _click("right-remote-selected", _scene_point(0.285, 0.41), "ui_click", game._inspect_tv)
	for volume in range(0, 14):
		await _click("tv-volume-%02d" % volume, Vector2(540, 362), "tv_button", game._change_tv_volume.bind(1), 0.18)
	await _click("tv-volume-14", Vector2(775, 625), "paper_pickup", game._collect_storybook_page_5, 0.55)
	await _back("tv-page-collected")

	# 오른쪽 방에서 세 페이지를 드래그 조합하고 동화책을 실제 화살표로 넘김
	await _drag_inventory("storybook_page_3", "storybook_page_4", "right-before-page-pair", "paper_pickup", game._combine_dragged_items.bind("storybook_page_3", "storybook_page_4"))
	await _drag_inventory("storybook_page_pair", "storybook_page_5", "right-before-storybook", "book_open", game._combine_dragged_items.bind("storybook_page_pair", "storybook_page_5"))
	for page in range(0, 5):
		await _click("storybook-%02d" % (page + 1), Vector2(1080, 350), "page_turn", game._open_storybook.bind(page + 1), 0.55)
	await _back("storybook-code-1366", 0.9)

	# 정면: 다이얼 전화기로 1366 입력
	await _turn_left("right-after-storybook")
	await _click("front-before-phone", _scene_point(0.34, 0.54), "metal_click", game._open_phone)
	for digit in ["1", "3", "6", "6"]:
		await _phone_digit(digit)

	# 열쇠 상세 → 방 복귀 → 두 번 방향 전환 → 뒤쪽 문 열기 → 열린 문 선택
	await _select_inventory("door_key", "front-after-phone")
	await _back("door-key-item")
	await _turn_right("front-key-selected")
	await _turn_right("right-to-back-door")
	await _click("closed-door", _scene_point(0.495, 0.49), "lock_latch", game._use_door, 0.65)
	await _click("open-door", _scene_point(0.495, 0.49), "door_open", game._return_to_pharmacy, 0.9)
	await _shot("escaped-to-pharmacy", {"type": "hold", "hold": 2.2})

	var manifest := {
		"width": 1280,
		"height": 720,
		"fps": 24,
		"steps": steps
	}
	var manifest_file := FileAccess.open(output_dir.path_join("manifest.json"), FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "\t"))
	print("CAPTURE_COMPLETE steps=%d output=%s" % [steps.size(), output_dir])
	quit(0)


func _prepare_title_without_touching_save() -> void:
	game.game_started = false
	game.has_saved_game = false
	game.title_continue_button.disabled = true
	game.title_save_label.text = "이어갈 저장 기록이 없습니다."
	game.title_layer.visible = true
	game._close_modal()


func _start_new_game_without_saving() -> void:
	game.game_started = false
	game.has_saved_game = false
	game.title_layer.visible = false
	game.current_place = "pharmacy"
	game.direction_index = 0
	game.inventory.clear()
	game.flags.clear()
	game.flags["music_enabled"] = true
	game.flags["sfx_enabled"] = true
	game.selected_item = ""
	game.phone_input = ""
	game.shoe_input = ""
	game.diary_page = 0
	game.storybook_page = 0
	game._close_modal()
	game._set_status("빛나는 편지함을 눌러 보세요.")
	game._render()


func _turn_left(name: String) -> void:
	await _click(name, Vector2(177, 344), "room_turn", game._move_left, 0.22)


func _turn_right(name: String) -> void:
	await _click(name, Vector2(1007, 344), "room_turn", game._move_right, 0.22)


func _back(name: String, hold: float = 0.3) -> void:
	await _click(name, Vector2(592, 642), "ui_back", game._close_closeup, hold)


func _select_inventory(item: String, name: String) -> void:
	await _settle()
	await _click(name, _inventory_point(item), "ui_click", game._select_item.bind(item), 0.32)


func _drag_inventory(source: String, target: String, name: String, sfx: String, callback: Callable) -> void:
	await _settle()
	await _shot(name, {
		"type": "drag",
		"from": _vector_array(_inventory_point(source)),
		"to": _vector_array(_inventory_point(target)),
		"sfx": sfx,
		"hold": 0.34
	})
	callback.call()
	await _settle()


func _modal_digit(digit: String, hold: float = 0.22) -> void:
	await _settle()
	var point := Vector2(640, 360)
	var digit_index := int(digit)
	if digit_index < game.modal_actions.get_child_count():
		point = _node_point(game.modal_actions.get_child(digit_index))
	await _click("shoe-code-%s-%s" % [game.shoe_input, digit], point, "keypad_tick", game._shoe_digit.bind(digit), hold)


func _phone_digit(digit: String) -> void:
	var normalized: Vector2 = {
		"1": Vector2(0.474, 0.412), "2": Vector2(0.485, 0.450), "3": Vector2(0.479, 0.493),
		"4": Vector2(0.463, 0.526), "5": Vector2(0.438, 0.544), "6": Vector2(0.411, 0.545),
		"7": Vector2(0.387, 0.529), "8": Vector2(0.371, 0.498), "9": Vector2(0.362, 0.460),
		"0": Vector2(0.371, 0.425)
	}[digit]
	var point: Vector2 = Vector2(52, 27) + normalized * Vector2(1080, 631)
	await _click("phone-%s-%s" % [game.phone_input, digit], point, "metal_click", game._dial_digit.bind(digit), 0.4)


func _click(name: String, point: Vector2, sfx: String, callback: Callable, hold: float = 0.3) -> void:
	await _shot(name, _click_action(point, sfx, hold))
	callback.call()
	await _settle()


func _click_action(point: Vector2, sfx: String, hold: float = 0.3) -> Dictionary:
	return {
		"type": "click",
		"to": _vector_array(point),
		"sfx": sfx,
		"hold": hold
	}


func _shot(name: String, action: Dictionary) -> void:
	await _settle()
	var image := root.get_texture().get_image()
	if image.get_width() != 1280 or image.get_height() != 720:
		image.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	var filename := "%03d-%s.png" % [shot_index, name]
	var result := image.save_png(output_dir.path_join(filename))
	if result != OK:
		push_error("스크린샷 저장 실패: " + filename)
	steps.append({"image": filename, "action": action})
	shot_index += 1


func _settle() -> void:
	await process_frame
	await process_frame


func _scene_point(nx: float, ny: float) -> Vector2:
	return Vector2(169.0 + nx * 846.0, 27.0 + ny * 631.0)


func _inventory_point(item: String) -> Vector2:
	for child in game.inventory_list.get_children():
		if str(child.get("item_id")) == item:
			return _node_point(child)
	push_error("인벤토리 위치를 찾지 못했습니다: " + item)
	return Vector2(1218, 155)


func _node_point(node: Control) -> Vector2:
	if node == null:
		return Vector2(640, 360)
	var viewport_size := root.get_visible_rect().size
	var scale := Vector2(1280.0 / viewport_size.x, 720.0 / viewport_size.y)
	return node.get_global_rect().get_center() * scale


func _vector_array(value: Vector2) -> Array:
	return [roundf(value.x), roundf(value.y)]
