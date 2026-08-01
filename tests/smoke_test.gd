extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "시작 장면을 불러온다")
	if packed == null:
		quit(1)
		return

	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	game._reset_game()
	game._open_letter()
	game._enter_childhood()
	_expect(game.current_place == "childhood", "편지에서 유아기 방으로 이동한다")

	game._inspect_floor_book()
	game._collect_alphabet_book()
	_expect(game.inventory.has("alphabet_book"), "바닥에서 알파벳 X 책을 얻는다")
	game._inspect_alphabet_bookcase()
	game._insert_alphabet_book()
	game._collect_picture_diary()
	_expect(game.inventory.has("picture_diary"), "책장의 빈자리를 채워 그림일기를 얻는다")
	game._open_diary(12)
	_expect(game.flags.get("diary_page_12_seen", false), "그림일기 표지와 12쪽을 반복해서 펼쳐본다")

	game._inspect_dresser()
	game._open_dresser()
	game._collect_needle()
	game._inspect_wardrobe()
	game._open_wardrobe()
	game._collect_thread()
	game._combine_dragged_items("needle", "thread")
	_expect(game.inventory.has("sewing_kit"), "바늘과 실로 바느질 세트를 만든다")

	game._inspect_torn_bear()
	game._select_item("sewing_kit")
	game._attempt_sew_bear()
	_expect(game.inventory.has("repaired_bear"), "뜯어진 곰인형을 수선한다")

	game._select_item("repaired_bear")
	game._inspect_bed()
	game._place_bear()
	game._collect_storybook_page_3()
	_expect(game.inventory.has("storybook_page_3"), "곰인형을 침대 밑에 두고 동화책 3쪽을 얻는다")

	game._collect_blocks()
	game._inspect_train_photo()
	game._combine_dragged_items("block_yellow", "block_blue")
	_expect(game.inventory.has("train_pair_yellow_blue"), "노란 블록을 파란 블록에 드래그해 연결한다")
	game._combine_dragged_items("train_pair_yellow_blue", "block_red")
	_expect(game.inventory.has("repaired_train"), "노랑·파랑·빨강 순서로 기차를 수리한다")
	game._select_item("repaired_train")
	game._place_train_on_rail()
	_expect(not game.inventory.has("storybook_page_4"), "레일에서 드러난 페이지는 누르기 전까지 획득되지 않는다")
	game._collect_storybook_page_4()
	_expect(game.inventory.has("storybook_page_4"), "기차가 움직인 뒤 동화책 4쪽을 얻는다")

	game._inspect_shoe_cabinet()
	game._inspect_old_shoe()
	game._show_shoe_keypad()
	for digit in ["2", "4", "0"]:
		game._shoe_digit(digit)
	_expect(game.flags.get("shoe_cabinet_unlocked", false), "구두의 240으로 신발장을 연다")
	game._reveal_mother_note()
	_expect(game.inventory.has("mother_note"), "엄마의 쪽지를 얻는다")

	game._inspect_tv_drawer()
	game._open_tv_drawer()
	game._collect_empty_remote()
	game._inspect_sofa()
	game._lift_sofa_cushion()
	_expect(not game.inventory.has("battery_1"), "소파 건전지는 그림을 누르기 전까지 획득되지 않는다")
	game._collect_sofa_battery()
	game._inspect_clock()
	game._turn_clock()
	_expect(not game.inventory.has("battery_2"), "시계 건전지는 뒤집은 뒤 눌러야 획득된다")
	game._collect_clock_battery()
	game._combine_dragged_items("empty_remote", "battery_1")
	_expect(game.inventory.has("remote_one_battery"), "리모컨에 첫 번째 건전지를 드래그해 넣는다")
	game._combine_dragged_items("remote_one_battery", "battery_2")
	_expect(game.inventory.has("powered_remote"), "건전지 두 개를 넣어 리모컨을 작동시킨다")
	game._select_item("powered_remote")
	game._inspect_tv()
	for step in range(14):
		game._change_tv_volume(1)
	_expect(game.flags.get("tv_volume_set", false), "TV 볼륨을 14에 맞춘다")
	_expect(not game.inventory.has("storybook_page_5"), "볼륨 14의 페이지는 눌러야 획득된다")
	game._collect_storybook_page_5()
	_expect(game.inventory.has("storybook_page_5"), "볼륨 14에서 동화책 5쪽을 얻는다")
	game._combine_dragged_items("storybook_page_3", "storybook_page_4")
	_expect(game.inventory.has("storybook_page_pair"), "동화책 3쪽과 4쪽을 먼저 맞춘다")
	game._combine_dragged_items("storybook_page_pair", "storybook_page_5")
	_expect(game.inventory.has("completed_storybook"), "세 페이지를 조합해 동화책을 완성한다")
	game._open_storybook(5)
	_expect(game.flags.get("storybook_code_seen", false), "완성된 동화책 맨 뒷장에서 1366을 확인한다")

	game._open_phone()
	for digit in ["1", "3", "6", "6"]:
		game._dial_digit(digit)
	_expect(game.inventory.has("courage"), "1366 입력으로 용기를 얻는다")
	_expect(game.inventory.has("door_key"), "1366 입력으로 문 열쇠를 얻는다")

	game.direction_index = 2
	game._select_item("door_key")
	game._use_door()
	_expect(game.flags.get("childhood_complete", false), "뒤쪽의 닫힌 문을 연다")
	game._return_to_pharmacy()
	game._brew_medicine()
	_expect(game.flags.get("medicine_brewed", false), "약방에서 물약을 완성한다")

	game._show_letter(2)
	game._enter_school()
	game._inspect_desk()
	game._open_locker()
	game._collect_tape()
	game._collect_shoe()
	game._combine_dragged_items("torn_shoe", "clear_tape")
	game._inspect_attendance()
	game._inspect_blackboard()
	game._quiet_whispers()
	game._select_item("school_key")
	game._use_school_door()
	_expect(game.flags.get("school_complete", false), "교실의 소음을 끄고 문을 연다")
	game._return_to_pharmacy()
	game._brew_medicine()
	_expect(game.flags.get("school_medicine_brewed", false), "두 번째 약을 완성한다")

	game._show_letter(3)
	game._enter_adult()
	game._switch_power()
	game._inspect_stars()
	game._collect_ticket()
	game._inspect_dream_note()
	game._combine_dragged_items("bus_ticket", "phone")
	game._water_plant()
	game._select_item("adult_key")
	game._use_adult_door()
	_expect(game.flags.get("adult_complete", false), "작은 약속을 실행하고 자취방을 나간다")
	game._return_to_pharmacy()
	game._brew_medicine()
	_expect(game.flags.get("adult_medicine_brewed", false), "세 번째 약을 완성한다")

	game._enter_truth()
	game._inspect_mirror()
	game._inspect_records()
	game._combine_dragged_items("courage_vial", "will_vial")
	_expect(game.inventory.has("emotion_vial_pair"), "두 감정의 병을 드래그해 연결한다")
	game._combine_dragged_items("emotion_vial_pair", "self_trust_vial")
	_expect(game.inventory.has("heart_key"), "세 감정으로 마음의 열쇠를 만든다")
	game._select_item("heart_key")
	game._use_final_door()
	_expect(game.flags.get("ending_complete", false), "현실의 문을 열고 엔딩에 도달한다")

	game._toggle_developer_mode()
	_expect(game.developer_mode, "설정에서 개발자 모드를 켠다")
	game._developer_jump("school")
	_expect(game.current_place == "school", "개발자 메뉴에서 원하는 챕터로 이동한다")
	game._developer_solve_current()
	_expect(
		game.flags.get("blackboard_solved", false)
		and game.flags.get("whispers_quiet", false)
		and game.inventory.has("school_key"),
		"개발자 메뉴에서 현재 챕터를 마지막 상호작용 직전으로 준비한다"
	)
	game._toggle_developer_mode()
	_expect(not game.developer_mode, "개발자 모드를 다시 끈다")

	game.inventory.assign([
		"picture_diary", "completed_storybook", "courage", "door_key",
		"phone", "school_key", "adult_key"
	])
	game._refresh_inventory()
	await process_frame
	var inventory_scroll := game.inventory_list.get_parent() as ScrollContainer
	_expect(
		game.inventory_list.get_child_count() == 7
		and inventory_scroll != null
		and inventory_scroll.get_v_scroll_bar().max_value > inventory_scroll.size.y,
		"인벤토리는 6칸을 표시하고 7번째 아이템부터 스크롤한다"
	)

	if failures == 0:
		print("마음 약방 전체 챕터 스모크 테스트 통과")
		quit(0)
	else:
		push_error("스모크 테스트 실패: %d개" % failures)
		quit(1)
