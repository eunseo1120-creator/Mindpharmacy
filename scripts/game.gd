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
var title_label: Label
var subtitle_label: Label
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
	backdrop.color = Color("#0e0c0b")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 68
	page.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_label = Label.new()
	title_label.text = "마음 약방"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", COLOR_PAPER)
	title_box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.text = "문이 없는 약방"
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", COLOR_MUTED)
	title_box.add_child(subtitle_label)

	var hint_button := _make_button("힌트")
	hint_button.pressed.connect(_show_hint)
	header.add_child(hint_button)
	var reset_button := _make_button("처음부터")
	reset_button.pressed.connect(_confirm_reset)
	header.add_child(reset_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	page.add_child(body)

	var game_shell := PanelContainer.new()
	game_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_shell.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, COLOR_GOLD, 2))
	body.add_child(game_shell)

	var game_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		game_margin.add_theme_constant_override("margin_" + side, 10)
	game_shell.add_child(game_margin)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = 4.0 / 3.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	game_margin.add_child(aspect)

	var scene_root := Control.new()
	scene_root.custom_minimum_size = Vector2(800, 600)
	aspect.add_child(scene_root)

	room_art = RoomArt.new()
	room_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root.add_child(room_art)

	hotspot_layer = Control.new()
	hotspot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_root.add_child(hotspot_layer)

	left_button = _make_arrow_button("‹", "왼쪽 방향")
	left_button.anchor_left = 0.015
	left_button.anchor_top = 0.44
	left_button.anchor_right = 0.09
	left_button.anchor_bottom = 0.59
	left_button.pressed.connect(_move_left)
	scene_root.add_child(left_button)

	right_button = _make_arrow_button("›", "오른쪽 방향")
	right_button.anchor_left = 0.91
	right_button.anchor_top = 0.44
	right_button.anchor_right = 0.985
	right_button.anchor_bottom = 0.59
	right_button.pressed.connect(_move_right)
	scene_root.add_child(right_button)

	var inventory_panel := PanelContainer.new()
	inventory_panel.custom_minimum_size.x = 238
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, Color("#796243"), 2))
	body.add_child(inventory_panel)

	var inventory_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inventory_margin.add_theme_constant_override("margin_" + side, 14)
	inventory_panel.add_child(inventory_margin)

	var inventory_column := VBoxContainer.new()
	inventory_column.add_theme_constant_override("separation", 9)
	inventory_margin.add_child(inventory_column)
	var inventory_title := Label.new()
	inventory_title.text = "소지품"
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title.add_theme_font_size_override("font_size", 21)
	inventory_title.add_theme_color_override("font_color", COLOR_PAPER)
	inventory_column.add_child(inventory_title)
	var divider := HSeparator.new()
	inventory_column.add_child(divider)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_column.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 8)
	scroll.add_child(inventory_list)
	combine_button = _make_button("아이템 조합")
	combine_button.pressed.connect(_combine_items)
	inventory_column.add_child(combine_button)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 44
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", COLOR_PAPER)
	page.add_child(status_label)

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
	card.custom_minimum_size = Vector2(580, 440)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#d2bf97"), COLOR_GOLD, 3))
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
	modal_title.add_theme_font_size_override("font_size", 28)
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
	if current_place == "childhood":
		scene_id = "childhood_" + DIRECTIONS[direction_index]
	room_art.set_scene(scene_id, flags)
	title_label.text = "마음 약방" if current_place == "pharmacy" else "거대한 두려움의 방"
	subtitle_label.text = "문이 없는 약방" if current_place == "pharmacy" else _direction_name()
	left_button.visible = current_place == "childhood"
	right_button.visible = current_place == "childhood"
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
	if inventory.is_empty():
		var empty := Label.new()
		empty.text = "─\n아직 아무것도 없다."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", COLOR_MUTED)
		inventory_list.add_child(empty)
	else:
		for item in inventory:
			var item_button := _make_button("◇  " + _item_name(item))
			item_button.toggle_mode = true
			item_button.button_pressed = item == selected_item
			item_button.pressed.connect(_select_item.bind(item))
			inventory_list.add_child(item_button)
	combine_button.disabled = inventory.size() < 2


func _open_letter() -> void:
	if flags.get("letter_opened", false):
		_enter_childhood()
		return
	flags["letter_opened"] = true
	_show_modal(
		"첫 번째 편지",
		"[center]약사님,\n\n밤이 되면 집이 너무 커져요.\n문은 바로 앞에 있는데, 혼자서는 열 수가 없어요.\n\n제가 무서움을 지나갈 수 있는 약을 만들어 주세요.[/center]",
		[{"label": "기억의 방으로", "callback": _enter_childhood}]
	)
	room_art.set_scene("pharmacy", flags)


func _enter_childhood() -> void:
	_close_modal()
	current_place = "childhood"
	direction_index = 0
	_set_status("좌우 화살표로 방을 둘러보세요.")
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


func _return_to_pharmacy() -> void:
	_close_modal()
	current_place = "pharmacy"
	_set_status("조제대가 은은하게 빛난다.")
	_render()


func _brew_medicine() -> void:
	if flags.get("medicine_brewed", false):
		_set_status("작은 병 안에서 따뜻한 빛이 흔들린다.")
		return
	if not inventory.has("courage"):
		_set_status("조제할 감정 재료가 없다.")
		return
	_remove_item("courage")
	flags["medicine_brewed"] = true
	_show_modal(
		"투명망토 물약",
		"[center]용기의 눈물이 천천히 금빛으로 변한다.\n\n첫 번째 기억의 약이 완성되었다.\n\n[b]프로토타입 완료[/b][/center]",
		[]
	)
	_set_status("첫 번째 편지의 약을 완성했다.")
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
	_show_modal("힌트", "[center]" + hint + "[/center]", [])


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
	return {
		"front": "정면 · 거대한 문",
		"right": "오른쪽 · 망가진 장난감",
		"back": "뒤쪽 · 옷장과 서랍",
		"left": "왼쪽 · 침대와 책꽂이"
	}.get(DIRECTIONS[direction_index], "")


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
	}.get(item, item)


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
	var button := _make_button(glyph)
	button.accessibility_name = accessible_name
	button.tooltip_text = accessible_name
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 48)
	button.modulate = Color(1, 1, 1, 0.82)
	return button


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
