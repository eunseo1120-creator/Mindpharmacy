extends Control

const RoomArt = preload("res://scripts/room_art.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")

const COLOR_INK := Color("#211a18")
const COLOR_PANEL := Color("#2c2521")
const COLOR_PANEL_LIGHT := Color("#44372e")
const COLOR_PAPER := Color("#d7c39b")
const COLOR_GOLD := Color("#d6ad5c")
const COLOR_MUTED := Color("#a99878")
const DIRECTIONS := ["front", "right", "back", "left"]

var current_place := "pharmacy"
var direction_index := 0
var inventory: Array[String] = []
var selected_item := ""
var flags: Dictionary = {}
var phone_input := ""

var room_art: Control
var hotspot_layer: Control
var inventory_list: VBoxContainer
var status_label: Label
var left_button: Button
var right_button: Button
var combine_button: Button
var modal_layer: ColorRect
var modal_title: Label
var modal_body: RichTextLabel
var modal_actions: VBoxContainer


func _ready() -> void:
	set_process_unhandled_input(true)
	_build_ui()
	var saved := SaveManagerScript.load_game()
	if not saved.is_empty():
		current_place = str(saved.get("current_place", "pharmacy"))
		direction_index = int(saved.get("direction_index", 0))
		inventory.assign(saved.get("inventory", []))
		flags = saved.get("flags", {})
		_set_status("저장된 기억에서 이어갑니다.")
	else:
		_set_status("빛나는 편지함을 눌러 보세요.")
	_render()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#050505")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 14
	center.offset_bottom = -14
	add_child(center)

	var body := HBoxContainer.new()
	body.custom_minimum_size = Vector2(1060, 640)
	body.add_theme_constant_override("separation", 20)
	center.add_child(body)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = 4.0 / 3.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.custom_minimum_size = Vector2(850, 638)
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(aspect)

	var scene_root := Control.new()
	scene_root.custom_minimum_size = Vector2(850, 638)
	aspect.add_child(scene_root)

	room_art = RoomArt.new()
	room_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root.add_child(room_art)

	hotspot_layer = Control.new()
	hotspot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root.add_child(hotspot_layer)

	left_button = _make_arrow_button("‹", "왼쪽 방향")
	left_button.anchor_left = 0.0
	left_button.anchor_top = 0.44
	left_button.anchor_right = 0.07
	left_button.anchor_bottom = 0.59
	left_button.pressed.connect(_move_left)
	scene_root.add_child(left_button)

	right_button = _make_arrow_button("›", "오른쪽 방향")
	right_button.anchor_left = 0.93
	right_button.anchor_top = 0.44
	right_button.anchor_right = 1.0
	right_button.anchor_bottom = 0.59
	right_button.pressed.connect(_move_right)
	scene_root.add_child(right_button)

	var inventory_margin := MarginContainer.new()
	inventory_margin.custom_minimum_size.x = 76
	inventory_margin.add_theme_constant_override("margin_left", 4)
	inventory_margin.add_theme_constant_override("margin_right", 4)
	inventory_margin.add_theme_constant_override("margin_top", 22)
	inventory_margin.add_theme_constant_override("margin_bottom", 22)
	body.add_child(inventory_margin)

	var inventory_column := VBoxContainer.new()
	inventory_column.add_theme_constant_override("separation", 7)
	inventory_margin.add_child(inventory_column)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	inventory_column.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 7)
	scroll.add_child(inventory_list)
	combine_button = _make_inventory_button("＋", "아이템 조합")
	combine_button.pressed.connect(_combine_items)
	inventory_column.add_child(combine_button)

	var settings_button := Button.new()
	settings_button.text = "⚙"
	settings_button.tooltip_text = "설정"
	settings_button.accessibility_name = "설정"
	settings_button.position = Vector2(18, 16)
	settings_button.size = Vector2(46, 46)
	settings_button.z_index = 20
	settings_button.add_theme_font_size_override("font_size", 24)
	settings_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	settings_button.add_theme_stylebox_override("normal", _transparent_style())
	settings_button.add_theme_stylebox_override("hover", _soft_button_style(Color(1, 1, 1, 0.12)))
	settings_button.add_theme_stylebox_override("pressed", _soft_button_style(Color(1, 1, 1, 0.2)))
	settings_button.pressed.connect(_open_settings)
	add_child(settings_button)

	status_label = Label.new()
	status_label.anchor_left = 0.24
	status_label.anchor_top = 0.915
	status_label.anchor_right = 0.76
	status_label.anchor_bottom = 0.975
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.82))
	status_label.add_theme_stylebox_override("normal", _soft_button_style(Color(0, 0, 0, 0.48)))
	status_label.z_index = 15
	add_child(status_label)

	_build_modal()


func _build_modal() -> void:
	modal_layer = ColorRect.new()
	modal_layer.color = Color(0.04, 0.035, 0.03, 0.9)
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.visible = false
	modal_layer.z_index = 100
	add_child(modal_layer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 410)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#ded2b9"), Color("#8f826c"), 1))
	center.add_child(card)
	var card_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		card_margin.add_theme_constant_override("margin_" + side, 28)
	card.add_child(card_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	card_margin.add_child(column)
	modal_title = Label.new()
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_font_size_override("font_size", 24)
	modal_title.add_theme_color_override("font_color", COLOR_INK)
	column.add_child(modal_title)
	modal_body = RichTextLabel.new()
	modal_body.bbcode_enabled = true
	modal_body.fit_content = false
	modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_font_size_override("normal_font_size", 18)
	modal_body.add_theme_color_override("default_color", COLOR_INK)
	column.add_child(modal_body)
	modal_actions = VBoxContainer.new()
	modal_actions.add_theme_constant_override("separation", 8)
	column.add_child(modal_actions)
	var close_button := _make_button("닫기")
	close_button.pressed.connect(_close_modal)
	column.add_child(close_button)


func _render() -> void:
	var scene_id := "pharmacy"
	if current_place in ["childhood", "school", "adult", "truth"]:
		scene_id = current_place + "_" + DIRECTIONS[direction_index]
	room_art.set_scene(scene_id, flags)
	left_button.visible = current_place != "pharmacy"
	right_button.visible = current_place != "pharmacy"
	_build_hotspots()
	_refresh_inventory()
	_save()


func _build_hotspots() -> void:
	for child in hotspot_layer.get_children():
		child.queue_free()
	if current_place == "pharmacy":
		_add_hotspot("편지함", Rect2(0.84, 0.3, 0.15, 0.29), _open_letter)
		if flags.get("chapter_returned", false):
			_add_hotspot("조제대", Rect2(0.2, 0.5, 0.62, 0.42), _brew_medicine)
		return

	if current_place == "childhood":
		_build_childhood_hotspots()
	elif current_place == "school":
		_build_school_hotspots()
	elif current_place == "adult":
		_build_adult_hotspots()
	elif current_place == "truth":
		_build_truth_hotspots()


func _build_childhood_hotspots() -> void:
	match DIRECTIONS[direction_index]:
		"front":
			_add_hotspot("거대한 문", Rect2(0.32, 0.04, 0.36, 0.72), _use_door)
			_add_hotspot("구형 전화기", Rect2(0.68, 0.48, 0.22, 0.24), _open_phone)
		"right":
			if not flags.get("bear_collected", false):
				_add_hotspot("뜯어진 곰인형", Rect2(0.12, 0.57, 0.22, 0.25), _collect_bear)
			if not flags.get("blocks_collected", false):
				_add_hotspot("색깔 블록", Rect2(0.4, 0.7, 0.22, 0.18), _collect_blocks)
			_add_hotspot("망가진 기차", Rect2(0.52, 0.5, 0.3, 0.3), _repair_train)
		"back":
			if not flags.get("needle_collected", false):
				_add_hotspot("서랍", Rect2(0.08, 0.42, 0.34, 0.33), _collect_needle)
			if not flags.get("thread_collected", false):
				_add_hotspot("올이 풀린 옷", Rect2(0.55, 0.12, 0.34, 0.58), _collect_thread)
		"left":
			_add_hotspot("책꽂이", Rect2(0.04, 0.12, 0.28, 0.6), _inspect_bookshelf)
			_add_hotspot("침대 밑", Rect2(0.34, 0.54, 0.56, 0.27), _place_bear)


func _build_school_hotspots() -> void:
	match DIRECTIONS[direction_index]:
		"front":
			_add_hotspot("교실 문", Rect2(0.7, 0.13, 0.2, 0.62), _use_school_door)
			_add_hotspot("칠판의 눈", Rect2(0.12, 0.18, 0.5, 0.34), _inspect_blackboard)
		"right":
			if not flags.get("tape_collected", false):
				_add_hotspot("서랍 속 테이프", Rect2(0.13, 0.5, 0.25, 0.23), _collect_tape)
			_add_hotspot("낙서 책상", Rect2(0.46, 0.42, 0.4, 0.34), _inspect_desk)
		"back":
			_add_hotspot("사물함", Rect2(0.52, 0.12, 0.35, 0.62), _open_locker)
			if not flags.get("shoe_collected", false):
				_add_hotspot("찢어진 실내화", Rect2(0.16, 0.65, 0.25, 0.18), _collect_shoe)
		"left":
			_add_hotspot("창가의 출석표", Rect2(0.12, 0.16, 0.27, 0.42), _inspect_attendance)
			_add_hotspot("방송 스피커", Rect2(0.64, 0.12, 0.2, 0.18), _quiet_whispers)


func _build_adult_hotspots() -> void:
	match DIRECTIONS[direction_index]:
		"front":
			_add_hotspot("현관문", Rect2(0.7, 0.1, 0.2, 0.67), _use_adult_door)
			_add_hotspot("꺼진 휴대전화", Rect2(0.42, 0.59, 0.15, 0.12), _open_mobile)
		"right":
			_add_hotspot("모니터", Rect2(0.17, 0.23, 0.4, 0.34), _inspect_monitor)
			_add_hotspot("멀티탭", Rect2(0.62, 0.68, 0.24, 0.12), _switch_power)
		"back":
			if not flags.get("ticket_collected", false):
				_add_hotspot("구겨진 버스표", Rect2(0.16, 0.64, 0.25, 0.15), _collect_ticket)
			_add_hotspot("꿈의 노트", Rect2(0.52, 0.44, 0.3, 0.24), _inspect_dream_note)
		"left":
			_add_hotspot("야광 별", Rect2(0.15, 0.14, 0.5, 0.3), _inspect_stars)
			_add_hotspot("말라버린 화분", Rect2(0.7, 0.52, 0.17, 0.25), _water_plant)


func _build_truth_hotspots() -> void:
	match DIRECTIONS[direction_index]:
		"front":
			_add_hotspot("전신 거울", Rect2(0.34, 0.08, 0.31, 0.67), _inspect_mirror)
		"right":
			_add_hotspot("세 개의 기록", Rect2(0.18, 0.42, 0.62, 0.3), _inspect_records)
		"back":
			_add_hotspot("없었던 문", Rect2(0.35, 0.08, 0.3, 0.68), _use_final_door)
		"left":
			_add_hotspot("조제대의 빈 병", Rect2(0.16, 0.5, 0.68, 0.27), _inspect_empty_bottles)


func _add_hotspot(label_text: String, normalized_rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = label_text
	button.accessibility_name = label_text
	button.anchor_left = normalized_rect.position.x
	button.anchor_top = normalized_rect.position.y
	button.anchor_right = normalized_rect.end.x
	button.anchor_bottom = normalized_rect.end.y
	button.focus_mode = Control.FOCUS_ALL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.border_color = Color.TRANSPARENT
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.92, 0.75, 0.34, 0.09)
	hover.border_color = Color(0.92, 0.75, 0.34, 0.72)
	hover.set_border_width_all(3)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(callback)
	hotspot_layer.add_child(button)


func _refresh_inventory() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	var slot_count := maxi(6, inventory.size())
	for index in range(slot_count):
		if index < inventory.size():
			var item := inventory[index]
			var item_button := _make_inventory_button(_item_symbol(item), _item_name(item))
			item_button.toggle_mode = true
			item_button.button_pressed = item == selected_item
			item_button.pressed.connect(_select_item.bind(item))
			inventory_list.add_child(item_button)
		else:
			var empty_slot := _make_inventory_button("", "빈 소지품 칸")
			empty_slot.disabled = true
			inventory_list.add_child(empty_slot)
	combine_button.disabled = inventory.size() < 2


func _open_letter() -> void:
	if flags.get("adult_medicine_brewed", false):
		_enter_truth()
	elif flags.get("school_medicine_brewed", false):
		_show_letter(3)
	elif flags.get("medicine_brewed", false):
		_show_letter(2)
	elif flags.get("letter_opened", false):
		_enter_childhood()
	else:
		flags["letter_opened"] = true
		_show_letter(1)
	room_art.set_scene("pharmacy", flags)


func _show_letter(number: int) -> void:
	var data: Array = {
		1: ["첫 번째 편지", "밤이 되면 집이 너무 커져요.\n문은 바로 앞에 있는데 혼자서는 열 수가 없어요.", _enter_childhood],
		2: ["두 번째 편지", "아무도 없는 교실에서도 웃음소리가 따라와요.\n그들이 붙인 이름 말고, 제 이름을 듣고 싶어요.", _enter_school],
		3: ["마지막 편지", "다들 앞으로 가는데 제 방만 물속에 잠긴 것 같아요.\n내일 한 가지를 시작할 힘을 처방해 주세요.", _enter_adult]
	}[number]
	_show_modal(str(data[0]), "[center]약사님,\n\n" + str(data[1]) + "\n\n— 이름이 번진 손님[/center]", [{"label": "기억의 방으로", "callback": data[2]}])


func _enter_childhood() -> void:
	_close_modal()
	current_place = "childhood"
	direction_index = 0
	_set_status("좌우 화살표로 방을 둘러보세요.")
	_render()


func _enter_school() -> void:
	_close_modal()
	current_place = "school"
	direction_index = 0
	_set_status("붉은 교실 · 남의 말과 나의 목소리를 구분하세요.")
	_render()


func _enter_adult() -> void:
	_close_modal()
	current_place = "adult"
	direction_index = 0
	_set_status("가라앉은 자취방 · 오늘 할 수 있는 한 가지를 찾으세요.")
	_render()


func _enter_truth() -> void:
	_close_modal()
	current_place = "truth"
	direction_index = 0
	flags["truth_entered"] = true
	_set_status("편지함은 비어 있다. 약방에는 거울만 남았다.")
	_render()


func _move_left() -> void:
	direction_index = wrapi(direction_index - 1, 0, DIRECTIONS.size())
	_set_status(_direction_name())
	_render()


func _move_right() -> void:
	direction_index = wrapi(direction_index + 1, 0, DIRECTIONS.size())
	_set_status(_direction_name())
	_render()


func _collect_bear() -> void:
	_add_item("torn_bear")
	flags["bear_collected"] = true
	_set_status("뜯어진 곰인형을 주웠다.")
	_render()


func _collect_blocks() -> void:
	_add_item("block_set")
	flags["blocks_collected"] = true
	_set_status("색깔 블록 세 개를 주웠다.")
	_render()


func _collect_needle() -> void:
	_add_item("needle")
	flags["needle_collected"] = true
	_set_status("서랍에서 작은 바늘을 찾았다.")
	_render()


func _collect_thread() -> void:
	_add_item("thread")
	flags["thread_collected"] = true
	_set_status("옷에서 길게 풀린 실을 얻었다.")
	_render()


func _repair_train() -> void:
	if not inventory.has("block_set"):
		_set_status("기차의 빈자리에 맞는 색깔 블록이 필요하다.")
		return
	_remove_item("block_set")
	_add_item("storybook_page_2")
	flags["train_repaired"] = true
	_set_status("사진의 색 순서대로 끼우자 기차가 움직이며 종이를 밀어냈다.")
	_render()


func _inspect_bookshelf() -> void:
	if flags.get("diary_found", false):
		_set_status("정리된 책들 사이의 빈자리가 보인다.")
		return
	flags["diary_found"] = true
	_show_modal(
		"그림일기",
		"문틀에 남은 키 표시의 높이와 색에 맞춰 책을 정리했다.\n\n[italic]“큰 소리가 날 때면 흰 곰을 안고 숫자를 거꾸로 세었다.”[/italic]",
		[]
	)
	_set_status("그림일기를 찾았다. 곰인형과 침대 밑이 그려져 있다.")
	_save()


func _place_bear() -> void:
	if not flags.get("diary_found", false):
		_set_status("침대 밑에는 희미한 먼지 자국만 남아 있다.")
		return
	if not inventory.has("repaired_bear"):
		_set_status("그림일기 속에는 멀쩡한 곰인형이 놓여 있다.")
		return
	_remove_item("repaired_bear")
	_add_item("storybook_page_1")
	flags["storybook_page_1_found"] = true
	_set_status("곰인형을 같은 자리에 두자 동화책 한 장이 떨어졌다.")
	_render()


func _combine_items() -> void:
	if inventory.has("needle") and inventory.has("thread") and inventory.has("torn_bear"):
		_remove_item("needle")
		_remove_item("thread")
		_remove_item("torn_bear")
		_add_item("repaired_bear")
		flags["bear_repaired"] = true
		_set_status("바늘과 실로 곰인형을 수선했다.")
	elif inventory.has("storybook_page_1") and inventory.has("storybook_page_2"):
		_remove_item("storybook_page_1")
		_remove_item("storybook_page_2")
		_add_item("completed_storybook")
		flags["storybook_completed"] = true
		_show_modal(
			"점박이 곰과 하얀 곰",
			"“혼자가 무섭다면 함께해도 괜찮아. 도와달라고 말해도 괜찮아.”\n\n책의 마지막 장 뒤편에 숫자가 적혀 있다.\n\n[center][font_size=34]1 · 3 · 6 · 6[/font_size][/center]",
			[]
		)
		_set_status("완성된 동화책의 뒷면에서 번호를 찾았다.")
	elif inventory.has("torn_shoe") and inventory.has("clear_tape"):
		_remove_item("torn_shoe")
		_remove_item("clear_tape")
		_add_item("repaired_shoe")
		flags["shoe_repaired"] = true
		_show_modal("되찾은 이름", "실내화 안쪽, 테이프에 가려졌던 글씨가 드러난다.\n\n[center][font_size=32]윤 · 슬 · 기[/font_size][/center]\n\n낙서는 이름이 아니다.", [])
		_set_status("지워지지 않은 본래의 이름을 찾았다.")
	elif inventory.has("bus_ticket") and inventory.has("phone"):
		flags["phone_unlocked"] = true
		_remove_item("bus_ticket")
		_show_modal("잠금 화면", "표의 날짜 10월 9일을 입력했다.\n\n메모 앱에는 한 문장만 남아 있다.\n[italic]“내일 오전 9시, 창가의 화분에 물 주기.”[/italic]", [])
		_set_status("휴대전화가 열렸다. 내일을 위한 작은 약속을 찾았다.")
	elif flags.get("records_seen", false) and inventory.has("courage_vial") and inventory.has("will_vial") and inventory.has("self_trust_vial"):
		_remove_item("courage_vial")
		_remove_item("will_vial")
		_remove_item("self_trust_vial")
		_add_item("heart_key")
		flags["heart_key_made"] = true
		_show_modal("마음의 열쇠", "[center]용기, 의지, 자기 신뢰가 하나의 열쇠가 된다.\n\n상처가 사라진 것은 아니다.\n하지만 이제 문을 열 사람을 알고 있다.[/center]", [])
		_set_status("마음의 열쇠가 완성되었다.")
	else:
		_set_status("지금 가진 물건들로는 조합할 수 없다.")
	_refresh_inventory()
	_save()


func _open_phone() -> void:
	phone_input = ""
	_show_modal("구형 다이얼 전화기", "[center][font_size=34]— — — —[/font_size][/center]", [])
	for digit in range(10):
		var button := _make_button(str(digit))
		button.pressed.connect(_dial_digit.bind(str(digit)))
		modal_actions.add_child(button)


func _dial_digit(digit: String) -> void:
	if phone_input.length() >= 4:
		phone_input = ""
	phone_input += digit
	var display := " ".join(phone_input.split(""))
	modal_body.text = "[center][font_size=34]" + display + "[/font_size][/center]"
	if phone_input.length() == 4:
		if phone_input == "1366" and inventory.has("completed_storybook"):
			_add_item("courage")
			_add_item("door_key")
			flags["phone_code_entered"] = true
			flags["courage_obtained"] = true
			_close_modal()
			_set_status("전화기 아래 칸이 열렸다. 용기의 눈물과 열쇠를 얻었다.")
			_render()
		elif phone_input == "1366":
			_set_status("번호는 맞지만, 이 번호의 의미를 이해할 단서가 더 필요하다.")
		else:
			_set_status("연결되지 않는다. 번호를 다시 생각해 보자.")


func _use_door() -> void:
	if selected_item != "door_key":
		_set_status("문은 너무 크고 무겁다. 열쇠가 필요하다.")
		return
	_remove_item("door_key")
	flags["childhood_complete"] = true
	flags["chapter_returned"] = true
	selected_item = ""
	_show_modal(
		"문이 열린다",
		"[center]거대한 문 틈으로 따뜻한 빛이 번진다.\n\n도움을 요청하는 일은 도망치는 것이 아니었다.[/center]",
		[{"label": "약방으로 돌아가기", "callback": _return_to_pharmacy}]
	)
	_render()


func _collect_tape() -> void:
	_add_item("clear_tape")
	flags["tape_collected"] = true
	_set_status("투명 테이프를 찾았다. 찢어진 것을 붙일 수 있다.")
	_render()


func _collect_shoe() -> void:
	_add_item("torn_shoe")
	flags["shoe_collected"] = true
	_set_status("낙서로 이름이 가려진 찢어진 실내화를 주웠다.")
	_render()


func _inspect_desk() -> void:
	flags["desk_read"] = true
	_show_modal("낙서 책상", "겹쳐 쓴 단어들 사이에서 같은 획만 따라 읽는다.\n\n[center][font_size=30]셋 · 하나 · 넷[/font_size][/center]\n\n사물함 자물쇠는 세 자리다.", [])
	_set_status("사물함 암호의 순서를 찾았다.")
	_save()


func _open_locker() -> void:
	if not flags.get("desk_read", false):
		_set_status("세 자리 자물쇠가 걸려 있다.")
		return
	if flags.get("locker_open", false):
		_set_status("빈 사물함 안쪽에 ‘네가 들은 말은 네 이름이 아니다’라고 적혀 있다.")
		return
	flags["locker_open"] = true
	_add_item("name_card")
	_show_modal("314번 사물함", "자물쇠가 열린다. 출석표에서 뜯긴 이름표가 들어 있다.\n\n[center][font_size=30]윤슬기[/font_size][/center]", [])
	_set_status("본래 이름이 적힌 이름표를 찾았다.")
	_render()


func _inspect_attendance() -> void:
	flags["attendance_read"] = true
	_show_modal("출석표", "17번 자리만 검게 지워져 있다.\n하지만 종이를 빛에 비추면 이름의 눌린 자국이 남아 있다.\n\n[italic]“지워진 것과 없었던 것은 다르다.”[/italic]", [])
	_set_status("17이라는 번호와 지워진 이름의 흔적을 기억했다.")
	_save()


func _inspect_blackboard() -> void:
	if not flags.get("attendance_read", false) or not flags.get("locker_open", false) or not flags.get("shoe_repaired", false):
		_set_status("칠판의 눈들이 웅성거린다. 이름, 번호, 찢긴 흔적이 아직 이어지지 않는다.")
		return
	flags["blackboard_solved"] = true
	_add_item("will")
	_add_item("school_key")
	_show_modal("나는 17번이 아니다", "[center]이름표를 칠판에 붙인다.\n\n“나는 윤슬기다.”\n\n그 순간 수십 개의 눈이 분필 가루로 무너진다.\n책상 아래에서 굳은 의지와 교실 열쇠가 나타난다.[/center]", [])
	_set_status("타인이 붙인 이름과 자신의 이름을 분리했다.")
	_render()


func _quiet_whispers() -> void:
	if not flags.get("blackboard_solved", false):
		_set_status("스피커는 알아들을 수 없는 별명들을 반복한다.")
	else:
		flags["whispers_quiet"] = true
		_set_status("방송 스위치를 내렸다. 이제 자기 숨소리가 들린다.")
		_render()


func _use_school_door() -> void:
	if selected_item != "school_key" or not flags.get("whispers_quiet", false):
		_set_status("열쇠와, 소음을 끌 결심이 모두 필요하다.")
		return
	_remove_item("school_key")
	flags["school_complete"] = true
	flags["chapter_returned"] = true
	selected_item = ""
	_show_modal("교실 밖으로", "[center]복도에는 아무도 없다.\n끝까지 따라오던 웃음소리도 멎었다.\n\n남의 말은 기억에 남지만, 나의 이름이 되지는 않는다.[/center]", [{"label": "약방으로 돌아가기", "callback": _return_to_pharmacy}])
	_render()


func _collect_ticket() -> void:
	_add_item("bus_ticket")
	flags["ticket_collected"] = true
	_set_status("10월 9일, 고향행 버스표. 사용되지 않았다.")
	_render()


func _inspect_monitor() -> void:
	flags["monitor_read"] = true
	_show_modal("두 개의 창", "[b]최종 면접 결과: 불합격[/b]\n\n그 뒤로 타인의 합격, 여행, 결혼 사진이 끝없이 흐른다.\n화면 구석의 작은 글씨:\n[italic]‘피드는 한 사람의 하루 전체가 아닙니다.’[/italic]", [])
	_set_status("빛이 너무 강해 방의 다른 흔적이 보이지 않는다.")
	_save()


func _switch_power() -> void:
	flags["power_off"] = not flags.get("power_off", false)
	_set_status("모니터를 껐다. 천장의 야광 별이 보이기 시작한다." if flags["power_off"] else "모니터가 다시 켜졌다.")
	_render()


func _inspect_stars() -> void:
	if not flags.get("power_off", false):
		_set_status("모니터 불빛 때문에 천장이 보이지 않는다.")
		return
	flags["stars_read"] = true
	_show_modal("야광 별자리", "별 네 개 아래에 짧은 문장이 숨어 있다.\n\n[center]물 · 주 · 기 · 9[/center]\n\n‘해야 할 인생’이 아니라 ‘내일 할 한 가지’.", [])
	_set_status("화분과 9시를 가리키는 단서를 찾았다.")
	_save()


func _inspect_dream_note() -> void:
	flags["dream_note_read"] = true
	if not inventory.has("phone"):
		_add_item("phone")
	_show_modal("꿈의 노트", "첫 장에는 거창한 목표가 빼곡하지만 마지막 장에는 한 줄뿐이다.\n\n[italic]“식물을 살리는 일부터 다시 시작하고 싶다.”[/italic]\n\n노트 밑에서 꺼진 휴대전화를 찾았다.", [])
	_set_status("휴대전화와 화분에 관한 기록을 찾았다.")
	_render()


func _open_mobile() -> void:
	if not inventory.has("phone"):
		_set_status("휴대전화 모양의 먼지 자국만 남아 있다.")
	elif not flags.get("phone_unlocked", false):
		_set_status("네 자리 날짜 암호가 필요하다. 사용하지 못한 표가 있었던 것 같다.")
	else:
		_set_status("메모: ‘내일 오전 9시, 창가의 화분에 물 주기.’")


func _water_plant() -> void:
	if not flags.get("phone_unlocked", false) or not flags.get("stars_read", false):
		_set_status("말라버린 흙. 무엇부터 해야 할지 정하지 못했다.")
		return
	if flags.get("plant_watered", false):
		_set_status("아주 작은 새잎이 물 위로 고개를 든다.")
		return
	flags["plant_watered"] = true
	_add_item("self_trust")
	_add_item("adult_key")
	_show_modal("한 가지의 내일", "[center]컵 한 잔의 물이 흙에 스민다.\n죽었다고 생각한 줄기에서 작은 초록이 드러난다.\n\n성공할 거라는 확신이 아니라,\n다시 해볼 수 있다는 자기 신뢰를 얻었다.[/center]", [])
	_set_status("자기 신뢰와 현관 열쇠를 얻었다.")
	_render()


func _use_adult_door() -> void:
	if selected_item != "adult_key":
		_set_status("문밖의 하루가 두렵다. 작은 약속을 끝내고 열쇠를 찾아야 한다.")
		return
	_remove_item("adult_key")
	flags["adult_complete"] = true
	flags["chapter_returned"] = true
	selected_item = ""
	_show_modal("수면 위로", "[center]현관문을 열자 물처럼 흔들리던 공기가 빠져나간다.\n\n오늘 해결한 것은 인생이 아니라 화분 하나였다.\n그것으로 충분한 날도 있다.[/center]", [{"label": "약방으로 돌아가기", "callback": _return_to_pharmacy}])
	_render()


func _inspect_mirror() -> void:
	flags["mirror_seen"] = true
	_show_modal("거울 속 손님", "[center]흰 가운의 약사 뒤로 아이, 학생, 청년이 차례로 겹친다.\n마지막에 남는 얼굴은 지금의 나다.\n\n편지의 번진 서명도, 기록 속 이름도 모두 [b]윤슬기[/b]였다.[/center]", [])
	_set_status("약사와 세 손님이 같은 사람임을 알아차렸다.")
	_save()


func _inspect_records() -> void:
	if not flags.get("mirror_seen", false):
		_set_status("스케치북, 이름표, 휴대전화. 아직 누구의 것인지 모르겠다.")
		return
	flags["records_seen"] = true
	_show_modal("세 개의 기록", "그림일기의 흰 곰, 17번 이름표, 오전 9시 메모.\n서로 다른 시절의 글씨 끝에 같은 버릇이 남아 있다.\n\n[italic]ㅅ의 마지막 획이 유난히 길다.[/italic]", [])
	_set_status("세 감정의 병을 조합할 수 있다.")
	_save()


func _inspect_empty_bottles() -> void:
	_set_status("약은 상처를 지우지 않았다. 다음 행동을 고를 틈을 만들어 주었다.")


func _use_final_door() -> void:
	if not flags.get("heart_key_made", false) or selected_item != "heart_key":
		_set_status("문은 나타났지만 손잡이가 없다. 세 개의 감정을 하나로 묶어야 한다.")
		return
	_remove_item("heart_key")
	flags["ending_complete"] = true
	selected_item = ""
	_show_modal("문을 여는 사람", "[center]따뜻한 아침빛이 현실의 방 안으로 들어온다.\n\n“애초에 손님은 없었다.\n약사는 내가 필요했던 다정한 어른의 모습이었다.”\n\n상처는 내 잘못이 아니었다.\n그리고 이제, 도움을 받으며 내가 문을 열 차례다.\n\n[b]끝[/b][/center]", [])
	_set_status("현실의 아침으로 돌아왔다.")
	_render()


func _return_to_pharmacy() -> void:
	_close_modal()
	current_place = "pharmacy"
	_set_status("조제대가 은은하게 빛난다.")
	_render()


func _brew_medicine() -> void:
	if inventory.has("courage"):
		_remove_item("courage")
		_add_item("courage_vial")
		flags["medicine_brewed"] = true
		flags["chapter_returned"] = false
		_show_modal("경계를 두르는 물약", "[center]용기의 눈물이 금빛 막이 된다.\n두려움이 없어지는 약이 아니라,\n도움을 청할 때까지 나를 지켜 주는 약이다.[/center]", [])
		_set_status("두 번째 편지가 은은하게 빛난다.")
	elif inventory.has("will"):
		_remove_item("will")
		_add_item("will_vial")
		flags["school_medicine_brewed"] = true
		flags["chapter_returned"] = false
		_show_modal("고요를 고르는 솜", "[center]굳은 의지가 작은 흰 솜으로 피어난다.\n모든 소리를 막는 대신,\n어떤 목소리를 믿을지 고를 수 있게 한다.[/center]", [])
		_set_status("마지막 편지가 남았다.")
	elif inventory.has("self_trust"):
		_remove_item("self_trust")
		_add_item("self_trust_vial")
		flags["adult_medicine_brewed"] = true
		flags["chapter_returned"] = false
		_show_modal("내일의 수액", "[center]자기 신뢰가 한 방울씩 떨어진다.\n완벽해질 힘이 아니라,\n내일 한 가지를 이어 갈 힘이다.[/center]", [])
		_set_status("손님은 오지 않는다. 편지함이 텅 비었다.")
	else:
		_set_status("지금 조제할 감정 재료가 없다.")
	_render()


func _select_item(item: String) -> void:
	selected_item = "" if selected_item == item else item
	if selected_item.is_empty():
		_set_status("아이템 선택을 해제했다.")
	else:
		_set_status(_item_name(selected_item) + " 선택됨")
	_refresh_inventory()


func _show_hint() -> void:
	var hint := "빛나는 편지함을 살펴보세요."
	if current_place == "childhood":
		if not flags.get("bear_repaired", false):
			hint = "서랍과 옷장에서 곰인형을 수선할 도구를 찾아보세요."
		elif not flags.get("storybook_page_1_found", false):
			hint = "그림일기의 장면을 침대 밑에서 재현해 보세요."
		elif not flags.get("train_repaired", false):
			hint = "바닥의 색깔 블록을 장난감 기차에 사용해 보세요."
		elif not flags.get("storybook_completed", false):
			hint = "두 장의 동화책 페이지를 조합해 보세요."
		elif not flags.get("courage_obtained", false):
			hint = "완성된 동화책 뒷면의 번호를 전화기에 입력하세요."
		else:
			hint = "열쇠를 선택한 뒤 정면의 거대한 문을 눌러 보세요."
	elif current_place == "school":
		if not flags.get("desk_read", false):
			hint = "낙서 책상에서 반복되는 획을 읽어 보세요."
		elif not flags.get("locker_open", false):
			hint = "책상에서 찾은 314를 사물함에 사용하세요."
		elif not flags.get("shoe_repaired", false):
			hint = "서랍의 테이프로 찢어진 실내화를 수선하세요."
		elif not flags.get("blackboard_solved", false):
			hint = "출석표의 번호, 이름표, 수선된 실내화의 이름을 칠판에서 연결하세요."
		elif not flags.get("whispers_quiet", false):
			hint = "왼쪽 벽의 방송 스피커를 끄세요."
		else:
			hint = "교실 열쇠를 선택하고 정면 문을 여세요."
	elif current_place == "adult":
		if not flags.get("power_off", false):
			hint = "멀티탭으로 모니터를 꺼 보세요."
		elif not flags.get("stars_read", false):
			hint = "어두워진 방의 야광 별을 살펴보세요."
		elif not inventory.has("phone"):
			hint = "꿈의 노트 아래를 살펴보세요."
		elif not flags.get("phone_unlocked", false):
			hint = "사용하지 못한 버스표의 날짜와 휴대전화를 조합하세요."
		elif not flags.get("plant_watered", false):
			hint = "메모의 작은 약속을 창가에서 실행하세요."
		else:
			hint = "현관 열쇠를 선택하고 문을 여세요."
	elif current_place == "truth":
		if not flags.get("mirror_seen", false):
			hint = "정면의 거울에서 손님의 얼굴을 확인하세요."
		elif not flags.get("records_seen", false):
			hint = "오른쪽의 세 기록에서 공통된 글씨를 찾으세요."
		elif not flags.get("heart_key_made", false):
			hint = "인벤토리의 감정 병 세 개를 조합하세요."
		else:
			hint = "뒤쪽 문에 마음의 열쇠를 사용하세요."
	_show_modal("힌트", "[center]" + hint + "[/center]", [])


func _open_settings() -> void:
	_show_modal(
		"설정",
		"[center]게임 진행은 자동으로 저장됩니다.[/center]",
		[
			{"label": "힌트 보기", "callback": _show_hint},
			{"label": "처음부터", "callback": _confirm_reset}
		]
	)


func _confirm_reset() -> void:
	_show_modal(
		"처음부터 시작할까요?",
		"현재 기기의 자동 저장 기록이 삭제됩니다.",
		[{"label": "저장 삭제 후 시작", "callback": _reset_game}]
	)


func _reset_game() -> void:
	SaveManagerScript.clear_save()
	current_place = "pharmacy"
	direction_index = 0
	inventory.clear()
	flags.clear()
	selected_item = ""
	_close_modal()
	_set_status("빛나는 편지함을 눌러 보세요.")
	_render()


func _show_modal(heading: String, body: String, actions: Array) -> void:
	for child in modal_actions.get_children():
		child.queue_free()
	modal_title.text = heading
	modal_body.text = body
	for action in actions:
		var button := _make_button(str(action["label"]))
		button.pressed.connect(action["callback"])
		modal_actions.add_child(button)
	modal_layer.visible = true


func _close_modal() -> void:
	modal_layer.visible = false


func _save() -> void:
	SaveManagerScript.save_game({
		"current_place": current_place,
		"direction_index": direction_index,
		"inventory": inventory,
		"flags": flags
	})


func _add_item(item: String) -> void:
	if not inventory.has(item):
		inventory.append(item)


func _remove_item(item: String) -> void:
	inventory.erase(item)
	if selected_item == item:
		selected_item = ""


func _direction_name() -> String:
	var names := {
		"childhood": ["정면 · 거대한 문", "오른쪽 · 망가진 장난감", "뒤쪽 · 옷장과 서랍", "왼쪽 · 침대와 책꽂이"],
		"school": ["정면 · 칠판과 교실 문", "오른쪽 · 낙서 책상", "뒤쪽 · 사물함", "왼쪽 · 출석표와 스피커"],
		"adult": ["정면 · 현관과 휴대전화", "오른쪽 · 모니터와 멀티탭", "뒤쪽 · 쓰레기 더미와 노트", "왼쪽 · 야광 별과 화분"],
		"truth": ["정면 · 전신 거울", "오른쪽 · 세 개의 기록", "뒤쪽 · 없었던 문", "왼쪽 · 빈 조제대"]
	}
	return names.get(current_place, ["", "", "", ""])[direction_index]


func _item_name(item: String) -> String:
	return {
		"torn_bear": "뜯어진 곰인형",
		"needle": "바늘",
		"thread": "실",
		"repaired_bear": "수선된 곰인형",
		"block_set": "색깔 블록",
		"storybook_page_1": "동화책 1쪽",
		"storybook_page_2": "동화책 2쪽",
		"completed_storybook": "완성된 동화책",
		"courage": "용기의 눈물",
		"door_key": "거대한 문의 열쇠"
		,"clear_tape": "투명 테이프"
		,"torn_shoe": "찢어진 실내화"
		,"repaired_shoe": "수선된 실내화"
		,"name_card": "윤슬기 이름표"
		,"will": "굳은 의지"
		,"school_key": "교실 열쇠"
		,"bus_ticket": "10월 9일 버스표"
		,"phone": "꺼진 휴대전화"
		,"self_trust": "자기 신뢰"
		,"adult_key": "현관 열쇠"
		,"courage_vial": "용기의 병"
		,"will_vial": "의지의 병"
		,"self_trust_vial": "자기 신뢰의 병"
		,"heart_key": "마음의 열쇠"
	}.get(item, item)


func _item_symbol(item: String) -> String:
	return {
		"torn_bear": "곰",
		"needle": "침",
		"thread": "실",
		"repaired_bear": "곰",
		"block_set": "■",
		"storybook_page_1": "頁",
		"storybook_page_2": "頁",
		"completed_storybook": "冊",
		"courage": "◇",
		"door_key": "⚿"
		,"clear_tape": "▧"
		,"torn_shoe": "鞋"
		,"repaired_shoe": "鞋"
		,"name_card": "名"
		,"will": "◆"
		,"school_key": "⚿"
		,"bus_ticket": "票"
		,"phone": "▣"
		,"self_trust": "◇"
		,"adult_key": "⚿"
		,"courage_vial": "Ⅰ"
		,"will_vial": "Ⅱ"
		,"self_trust_vial": "Ⅲ"
		,"heart_key": "♢"
	}.get(item, "·")


func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _make_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(112, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", COLOR_PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL_LIGHT, Color("#796243"), 1))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#584838"), COLOR_GOLD, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#211a18"), COLOR_GOLD, 2))
	button.add_theme_stylebox_override("focus", _panel_style(COLOR_PANEL_LIGHT, COLOR_GOLD, 3))
	return button


func _make_arrow_button(glyph: String, accessible_name: String) -> Button:
	var button := Button.new()
	button.text = glyph
	button.accessibility_name = accessible_name
	button.tooltip_text = accessible_name
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_color_override("font_color", Color(0.03, 0.03, 0.03, 0.78))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _transparent_style())
	button.add_theme_stylebox_override("hover", _soft_button_style(Color(0, 0, 0, 0.34)))
	button.add_theme_stylebox_override("pressed", _soft_button_style(Color(0, 0, 0, 0.48)))
	button.add_theme_stylebox_override("focus", _soft_button_style(Color(1, 1, 1, 0.12)))
	return button


func _make_inventory_button(glyph: String, accessible_name: String) -> Button:
	var button := Button.new()
	button.text = glyph
	button.tooltip_text = accessible_name
	button.accessibility_name = accessible_name
	button.custom_minimum_size = Vector2(62, 62)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#3b332b"))
	button.add_theme_color_override("font_hover_color", Color("#1d1916"))
	button.add_theme_stylebox_override("normal", _inventory_style(Color("#d7c9a9"), Color("#f0e8d4"), 2))
	button.add_theme_stylebox_override("hover", _inventory_style(Color("#eadfc3"), Color.WHITE, 3))
	button.add_theme_stylebox_override("pressed", _inventory_style(Color("#c6b58d"), Color("#fff8df"), 3))
	button.add_theme_stylebox_override("focus", _inventory_style(Color("#d7c9a9"), Color.WHITE, 3))
	button.add_theme_stylebox_override("disabled", _inventory_style(Color("#9f947d"), Color("#c8bea7"), 2))
	return button


func _inventory_style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := _panel_style(color, border, width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 7
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	return style


func _soft_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style


func _panel_style(color: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("close_popup") and modal_layer.visible:
		_close_modal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") and current_place == "childhood" and not modal_layer.visible:
		_move_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") and current_place == "childhood" and not modal_layer.visible:
		_move_right()
		get_viewport().set_input_as_handled()
