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

	game._collect_needle()
	game._collect_thread()
	game._collect_bear()
	game._collect_blocks()
	game._combine_items()
	_expect(game.inventory.has("repaired_bear"), "곰인형을 수선한다")

	game._inspect_bookshelf()
	game._select_item("repaired_bear")
	game._place_bear()
	_expect(game.inventory.has("storybook_page_1"), "침대 밑에서 첫 페이지를 얻는다")

	game._repair_train()
	_expect(game.inventory.has("storybook_page_2"), "기차에서 두 번째 페이지를 얻는다")
	game._combine_items()
	_expect(game.inventory.has("completed_storybook"), "동화책을 완성한다")

	game._open_phone()
	for digit in ["1", "3", "6", "6"]:
		game._dial_digit(digit)
	_expect(game.inventory.has("courage"), "1366 입력으로 용기를 얻는다")
	_expect(game.inventory.has("door_key"), "1366 입력으로 문 열쇠를 얻는다")

	game.direction_index = 0
	game._select_item("door_key")
	game._use_door()
	_expect(game.flags.get("childhood_complete", false), "거대한 문을 연다")
	game._return_to_pharmacy()
	game._brew_medicine()
	_expect(game.flags.get("medicine_brewed", false), "약방에서 물약을 완성한다")

	if failures == 0:
		print("마음 약방 프로토타입 스모크 테스트 통과")
		quit(0)
	else:
		push_error("스모크 테스트 실패: %d개" % failures)
		quit(1)
