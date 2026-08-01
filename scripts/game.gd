extends Control

const RoomArt = preload("res://scripts/room_art.gd")
const SaveManagerScript = preload("res://scripts/save_manager.gd")
const InventoryItemButtonScript = preload("res://scripts/inventory_item_button.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansKR-Variable.ttf")

const COLOR_INK := Color("#211a18")
const COLOR_PANEL := Color("#2c2521")
const COLOR_PANEL_LIGHT := Color("#44372e")
const COLOR_PAPER := Color("#d7c39b")
const COLOR_GOLD := Color("#d6ad5c")
const COLOR_MUTED := Color("#a99878")
const DIRECTIONS := ["front", "right", "back", "left"]
const DIARY_PAGE_COUNT := 12
const STORYBOOK_PAGES := [
	"점박이 곰은 문 앞에 서서 몸을 떨고 있었어요.\n그때 하얀 곰이 와서 물어봤어요.\n\n“이 문을 나가면 바로 밖인데, 왜 안 나가고 있어?”",
	"점박이 곰은 몸을 웅크리면서 말했어요.\n\n“이 밖으로 나가면 크고 무서운 것들이 많아서, 다시 못 돌아올 수도 있대.”\n\n하얀 곰은 가만히 들었어요.",
	"점박이 곰은 다시 몸을 떨며 이어서 말했어요.\n\n“그리고 나는 털 색깔이 얼룩덜룩해서 비웃음을 당할 거야.”\n\n하얀 곰은 또 가만히 듣고 있었어요.",
	"점박이 곰은 문 앞에서 계속 고민하고 또 고민했어요.\n그때 하얀 곰이 말했어요.\n\n“내가 옆에 있어줄게. 같이 나가자. 용기를 내 봐.”\n\n점박이 곰이 문을 열자 하얀 햇살과 예쁜 꽃들이 보였어요.",
	"하얀 곰은 또다시 입을 열었어요.\n\n“혼자가 무섭다면 함께해도 괜찮아. 도와줄게.”"
]

var current_place := "pharmacy"
var direction_index := 0
var inventory: Array[String] = []
var selected_item := ""
var flags: Dictionary = {}
var phone_input := ""
var shoe_input := ""
var diary_page := 0
var storybook_page := 0
var developer_mode := false

var room_art: Control
var hotspot_layer: Control
var inventory_list: VBoxContainer
var status_label: Label
var left_button: Button
var right_button: Button
var closeup_layer: Control
var closeup_image: TextureRect
var closeup_hotspot_layer: Control
var closeup_caption_panel: PanelContainer
var closeup_caption: RichTextLabel
var closeup_actions: HBoxContainer
var closeup_back_button: Button
var modal_layer: ColorRect
var modal_title: Label
var modal_image: TextureRect
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
		developer_mode = bool(saved.get("developer_mode", false))
		_migrate_childhood_save()
		_set_status("저장된 기억에서 이어갑니다.")
	else:
		_set_status("빛나는 편지함을 눌러 보세요.")
	_render()


func _build_ui() -> void:
	var ui_theme := Theme.new()
	ui_theme.default_font = UI_FONT
	theme = ui_theme

	var backdrop := ColorRect.new()
	backdrop.color = Color("#050505")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var screen_margin := MarginContainer.new()
	screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_margin.add_theme_constant_override("margin_left", 24)
	screen_margin.add_theme_constant_override("margin_right", 24)
	screen_margin.add_theme_constant_override("margin_top", 22)
	screen_margin.add_theme_constant_override("margin_bottom", 68)
	add_child(screen_margin)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 16)
	screen_margin.add_child(body)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = 4.0 / 3.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	aspect.custom_minimum_size = Vector2(720, 540)
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(aspect)

	var scene_root := Control.new()
	scene_root.custom_minimum_size = Vector2(720, 540)
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
	inventory_margin.custom_minimum_size.x = 104
	inventory_margin.add_theme_constant_override("margin_left", 6)
	inventory_margin.add_theme_constant_override("margin_right", 6)
	body.add_child(inventory_margin)

	var inventory_center := CenterContainer.new()
	inventory_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_margin.add_child(inventory_center)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(92, 542)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.tooltip_text = "소지품이 6개를 넘으면 위아래로 스크롤할 수 있습니다."
	inventory_center.add_child(scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 10)
	scroll.add_child(inventory_list)

	var settings_button := Button.new()
	settings_button.text = "≡"
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

	_build_closeup(scene_root)
	_build_modal()


func _build_closeup(scene_root: Control) -> void:
	closeup_layer = Control.new()
	closeup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closeup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	closeup_layer.visible = false
	closeup_layer.z_index = 60
	scene_root.add_child(closeup_layer)

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	closeup_layer.add_child(black)

	closeup_image = TextureRect.new()
	closeup_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closeup_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	closeup_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	closeup_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	closeup_layer.add_child(closeup_image)

	closeup_hotspot_layer = Control.new()
	closeup_hotspot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closeup_hotspot_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	closeup_layer.add_child(closeup_hotspot_layer)

	var action_center := CenterContainer.new()
	action_center.anchor_left = 0.08
	action_center.anchor_top = 0.7
	action_center.anchor_right = 0.92
	action_center.anchor_bottom = 0.8
	closeup_layer.add_child(action_center)
	closeup_actions = HBoxContainer.new()
	closeup_actions.add_theme_constant_override("separation", 10)
	action_center.add_child(closeup_actions)

	closeup_caption_panel = PanelContainer.new()
	closeup_caption_panel.anchor_left = 0.07
	closeup_caption_panel.anchor_top = 0.74
	closeup_caption_panel.anchor_right = 0.93
	closeup_caption_panel.anchor_bottom = 0.92
	closeup_caption_panel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0.82), Color.TRANSPARENT, 0))
	closeup_layer.add_child(closeup_caption_panel)
	closeup_caption = RichTextLabel.new()
	closeup_caption.bbcode_enabled = true
	closeup_caption.fit_content = false
	closeup_caption.scroll_active = false
	closeup_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closeup_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	closeup_caption.add_theme_font_size_override("normal_font_size", 20)
	closeup_caption.add_theme_font_size_override("bold_font_size", 21)
	closeup_caption.add_theme_color_override("default_color", Color.WHITE)
	closeup_caption_panel.add_child(closeup_caption)

	closeup_back_button = _make_arrow_button("↓", "방 화면으로 돌아가기")
	closeup_back_button.anchor_left = 0.46
	closeup_back_button.anchor_top = 0.92
	closeup_back_button.anchor_right = 0.54
	closeup_back_button.anchor_bottom = 1.0
	closeup_back_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	closeup_back_button.pressed.connect(_close_closeup)
	closeup_layer.add_child(closeup_back_button)


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
	card.custom_minimum_size = Vector2(620, 620)
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
	modal_image = TextureRect.new()
	modal_image.custom_minimum_size = Vector2(520, 250)
	modal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	modal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modal_image.visible = false
	column.add_child(modal_image)
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
	var scene_id: String = current_place + "_" + DIRECTIONS[direction_index]
	room_art.set_scene(scene_id, flags)
	left_button.visible = true
	right_button.visible = true
	_build_hotspots()
	_refresh_inventory()
	_save()


func _build_hotspots() -> void:
	for child in hotspot_layer.get_children():
		child.queue_free()
	if current_place == "pharmacy":
		if DIRECTIONS[direction_index] == "right":
			_add_hotspot("편지함", Rect2(0.12, 0.17, 0.42, 0.5), _open_letter)
		if DIRECTIONS[direction_index] == "front" and flags.get("chapter_returned", false):
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
			_add_hotspot("구형 전화기", Rect2(0.29, 0.48, 0.1, 0.12), _open_phone)
			_add_hotspot("전화기 아래 알파벳 책장", Rect2(0.27, 0.57, 0.27, 0.25), _inspect_alphabet_bookcase)
			if not flags.get("alphabet_book_collected", false) and not flags.get("diary_revealed", false):
				_add_hotspot("바닥에 놓인 X 책", Rect2(0.08, 0.8, 0.18, 0.15), _inspect_floor_book)
		"right":
			if not flags.get("bear_repaired", false):
				_add_hotspot("뜯어진 곰인형", Rect2(0.43, 0.69, 0.19, 0.22), _inspect_torn_bear)
			if not flags.get("blocks_collected", false):
				_add_hotspot("색깔 블록", Rect2(0.61, 0.84, 0.24, 0.13), _collect_blocks)
			_add_hotspot("장난감 기차 레일", Rect2(0.62, 0.7, 0.34, 0.21), _place_train_on_rail)
			_add_hotspot("기차 그림 액자", Rect2(0.48, 0.1, 0.19, 0.23), _inspect_train_photo)
			_add_hotspot("텔레비전", Rect2(0.12, 0.25, 0.33, 0.32), _inspect_tv)
			_add_hotspot("TV 아래 서랍", Rect2(0.06, 0.57, 0.44, 0.2), _inspect_tv_drawer)
		"back":
			_add_hotspot("열린 문" if flags.get("childhood_complete", false) else "닫힌 문", Rect2(0.37, 0.14, 0.25, 0.7), _return_to_pharmacy if flags.get("childhood_complete", false) else _use_door)
			_add_hotspot("서랍장", Rect2(0.04, 0.53, 0.29, 0.32), _inspect_dresser)
			_add_hotspot("옷장", Rect2(0.66, 0.18, 0.32, 0.67), _inspect_wardrobe)
		"left":
			_add_hotspot("침대", Rect2(0.43, 0.38, 0.35, 0.43), _inspect_bed)
			_add_hotspot("신발장", Rect2(0.76, 0.48, 0.22, 0.3), _inspect_shoe_cabinet)
			_add_hotspot("소파 쿠션", Rect2(0.02, 0.4, 0.43, 0.35), _inspect_sofa)
			_add_hotspot("멈춘 시계", Rect2(0.17, 0.15, 0.14, 0.18), _inspect_clock)


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
			var item_button := _make_inventory_button(_item_symbol(item), _item_name(item)) as InventoryItemButton
			item_button.item_id = item
			item_button.item_dropped.connect(_combine_dragged_items)
			var item_texture := _item_texture(item)
			if item_texture != null:
				item_button.text = ""
				item_button.icon = item_texture
				item_button.expand_icon = true
			item_button.toggle_mode = true
			item_button.button_pressed = item == selected_item
			item_button.pressed.connect(_select_item.bind(item))
			inventory_list.add_child(item_button)
		else:
			var empty_slot := _make_inventory_button("", "빈 소지품 칸")
			empty_slot.disabled = true
			inventory_list.add_child(empty_slot)


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
	room_art.set_scene("pharmacy_" + DIRECTIONS[direction_index], flags)


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


func _inspect_dresser() -> void:
	if not flags.get("dresser_open", false):
		_show_interactive_closeup("낡은 서랍장", "서랍을 직접 눌러 열어 보자.", "res://assets/closeups/childhood/dresser-closed.png", [{"label": "서랍 열기", "rect": Rect2(0.1, 0.26, 0.8, 0.55), "callback": _open_dresser}])
	elif not flags.get("needle_collected", false):
		_open_dresser()
	else:
		_show_closeup("빈 서랍", "바늘을 꺼낸 자리에는 실밥만 남아 있다.", [], "res://assets/closeups/childhood/dresser-open-empty.jpg")


func _open_dresser() -> void:
	flags["dresser_open"] = true
	_show_interactive_closeup("열린 서랍", "그림 속 바늘을 눌러 집어 든다.", "res://assets/closeups/childhood/dresser-open.png", [{"label": "바늘", "rect": Rect2(0.03, 0.1, 0.27, 0.28), "callback": _collect_needle}])
	_save()


func _collect_needle() -> void:
	_add_item("needle")
	flags["needle_collected"] = true
	_set_status("서랍에서 작은 바늘을 얻었다.")
	_show_closeup("빈 서랍", "바늘을 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/dresser-open-empty.jpg")
	_render()


func _inspect_wardrobe() -> void:
	if not flags.get("wardrobe_open", false):
		_show_interactive_closeup("나무 옷장", "옷장 문을 직접 눌러 보자.", "res://assets/closeups/childhood/wardrobe-closed.png", [{"label": "옷장 열기", "rect": Rect2(0.18, 0.08, 0.64, 0.78), "callback": _open_wardrobe}])
	elif not flags.get("thread_collected", false):
		_open_wardrobe()
	else:
		_show_closeup("열린 옷장", "풀린 실을 떼어 낸 니트가 걸려 있다.", [], "res://assets/closeups/childhood/wardrobe-open-no-thread.jpg")


func _open_wardrobe() -> void:
	flags["wardrobe_open"] = true
	_show_interactive_closeup("열린 옷장", "니트 아래로 늘어진 실을 눌러 집어 든다.", "res://assets/closeups/childhood/wardrobe-open.png", [{"label": "풀린 실", "rect": Rect2(0.48, 0.38, 0.31, 0.52), "callback": _collect_thread}])
	_save()


func _collect_thread() -> void:
	_add_item("thread")
	flags["thread_collected"] = true
	_set_status("올이 풀린 니트에서 실을 얻었다.")
	_show_closeup("열린 옷장", "실을 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/wardrobe-open-no-thread.jpg")
	_render()


func _inspect_torn_bear() -> void:
	if not flags.get("bear_collected", false):
		_add_item("torn_bear")
		flags["bear_collected"] = true
	_show_interactive_closeup("뜯어진 곰인형", "바느질 세트를 선택한 뒤, 벌어진 배 부분을 눌러 수선한다.", "res://assets/closeups/childhood/torn-bear-closeup.png", [{"label": "벌어진 솔기", "rect": Rect2(0.25, 0.38, 0.5, 0.42), "callback": _attempt_sew_bear}])
	_set_status("곰인형 클로즈업에서 바느질 세트를 선택한 뒤 벌어진 부분을 누르세요.")
	_save()


func _attempt_sew_bear() -> void:
	if selected_item != "sewing_kit" or not inventory.has("torn_bear"):
		_set_status("인벤토리에서 바느질 세트를 먼저 선택하세요.")
		return
	_sew_bear()


func _sew_bear() -> void:
	_remove_item("sewing_kit")
	_remove_item("torn_bear")
	_add_item("repaired_bear")
	flags["bear_repaired"] = true
	selected_item = ""
	_show_closeup(
		"꼬매진 곰인형",
		"열 번 남짓한 바늘땀이 상처 난 천을 단단히 붙잡고 있다.",
		[],
		"res://assets/closeups/childhood/stitched-bear-closeup.png"
	)
	_set_status("꼬매진 곰인형을 얻었다.")
	_render()


func _collect_blocks() -> void:
	_add_item("block_red")
	_add_item("block_yellow")
	_add_item("block_blue")
	flags["blocks_collected"] = true
	_set_status("빨간색, 노란색, 파란색 기차 블록을 얻었다.")
	_render()


func _inspect_train_photo() -> void:
	flags["train_order_seen"] = true
	_show_modal(
		"액자 속 장난감 기차",
		"객차의 순서는 [color=#b79642]노란색[/color] → [color=#63758a]파란색[/color] → [color=#8f4e43]빨간색[/color]이다.",
		[],
		"res://assets/closeups/childhood/train-order-frame.png"
	)
	_set_status("기차 블록의 순서를 기억했다: 노랑, 파랑, 빨강.")
	_save()


func _place_train_on_rail() -> void:
	if flags.get("storybook_page_4_found", false):
		_set_status("기차가 지나간 레일 아래에는 아무것도 남지 않았다.")
		return
	if flags.get("storybook_page_4_revealed", false):
		_show_interactive_closeup("레일 아래의 종이", "드러난 동화책 페이지를 눌러 집어 든다.", "res://assets/closeups/childhood/storybook-page-piece.png", [{"label": "동화책 네 번째 페이지", "rect": Rect2(0.23, 0.24, 0.55, 0.5), "callback": _collect_storybook_page_4}])
		return
	if selected_item != "repaired_train":
		_set_status("레일 위를 달릴 수 있는 수리된 장난감 기차가 필요하다.")
		return
	_remove_item("repaired_train")
	flags["train_repaired"] = true
	flags["storybook_page_4_revealed"] = true
	selected_item = ""
	_show_interactive_closeup("레일 아래의 종이", "기차가 움직이자 눌려 있던 페이지가 드러났다. 종이를 눌러 집어 든다.", "res://assets/closeups/childhood/storybook-page-piece.png", [{"label": "동화책 네 번째 페이지", "rect": Rect2(0.23, 0.24, 0.55, 0.5), "callback": _collect_storybook_page_4}])
	_set_status("레일 아래에 드러난 동화책 페이지를 누르세요.")
	_render()



func _collect_storybook_page_4() -> void:
	_add_item("storybook_page_4")
	flags["storybook_page_4_found"] = true
	_set_status("동화책의 네 번째 페이지를 인벤토리에 넣었다.")
	_close_closeup()
	_render()


func _inspect_bed() -> void:
	if flags.get("bear_placed_under_bed", false):
		if not flags.get("storybook_page_3_found", false):
			_show_interactive_closeup("침대 위의 종이", "침대 위에 떨어진 페이지를 눌러 집어 든다.", "res://assets/closeups/childhood/bed-storybook.png", [{"label": "동화책 세 번째 페이지", "rect": Rect2(0.34, 0.24, 0.4, 0.46), "callback": _collect_storybook_page_3}])
		else:
			_show_closeup("침대 밑의 곰인형", "꼬매진 곰인형이 침대 밑을 지키고 있다.", [], "res://assets/closeups/childhood/bed-bear-under.png")
		return
	_show_interactive_closeup("빈 침대", "꼬매진 곰인형을 선택한 뒤 침대 밑 빈자리를 누른다.", "res://assets/closeups/childhood/bed-empty.jpg", [{"label": "침대 밑 빈자리", "rect": Rect2(0.2, 0.53, 0.62, 0.29), "callback": _place_bear}])


func _place_bear() -> void:
	if selected_item != "repaired_bear":
		_set_status("인벤토리에서 꼬매진 곰인형을 먼저 선택하세요.")
		return
	_remove_item("repaired_bear")
	selected_item = ""
	flags["bear_placed_under_bed"] = true
	_show_interactive_closeup("침대 위의 종이", "곰인형을 놓자 침대 위에 페이지가 떨어졌다. 종이를 눌러 집어 든다.", "res://assets/closeups/childhood/bed-storybook.png", [{"label": "동화책 세 번째 페이지", "rect": Rect2(0.34, 0.24, 0.4, 0.46), "callback": _collect_storybook_page_3}])
	_save()


func _collect_storybook_page_3() -> void:
	_add_item("storybook_page_3")
	flags["storybook_page_3_found"] = true
	_show_closeup("침대 밑의 곰인형", "동화책의 세 번째 페이지를 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/bed-bear-under.png")
	_set_status("동화책의 세 번째 페이지를 인벤토리에 넣었다.")
	_render()


func _reveal_storybook() -> void:
	_collect_storybook_page_3()


func _inspect_shoe_cabinet() -> void:
	if flags.get("shoe_cabinet_unlocked", false):
		_show_interactive_closeup("열린 신발장", "" if flags.get("mother_note_collected", false) else "왼쪽 칸의 접힌 쪽지를 눌러 확인한다.", "res://assets/closeups/childhood/shoe-cabinet-open.png", [] if flags.get("mother_note_collected", false) else [{"label": "엄마의 쪽지", "rect": Rect2(0.08, 0.19, 0.42, 0.52), "callback": _reveal_mother_note}])
		return
	_show_interactive_closeup("잠긴 신발장", "구두나 왼쪽 문의 전자 잠금장치를 직접 누른다.", "res://assets/closeups/childhood/shoe-cabinet-locked.png", [{"label": "낡은 구두", "rect": Rect2(0.5, 0.42, 0.4, 0.34), "callback": _inspect_old_shoe}, {"label": "전자 잠금장치", "rect": Rect2(0.08, 0.25, 0.36, 0.46), "callback": _show_shoe_keypad}])


func _inspect_old_shoe() -> void:
	flags["shoe_size_seen"] = true
	_show_closeup(
		"낡은 구두 안쪽",
		"닳은 안감에 숫자가 선명하게 남아 있다.\n\n[center][font_size=34]240[/font_size][/center]",
		[],
		"res://assets/closeups/childhood/old-shoe-240.png"
	)
	_set_status("낡은 구두의 발 사이즈 240을 확인했다.")
	_save()


func _show_shoe_keypad() -> void:
	shoe_input = ""
	_show_modal("신발장 비밀번호", "[center][font_size=34]— — —[/font_size][/center]", [])
	for digit in range(10):
		var button := _make_button(str(digit))
		button.pressed.connect(_shoe_digit.bind(str(digit)))
		modal_actions.add_child(button)


func _shoe_digit(digit: String) -> void:
	if shoe_input.length() >= 3:
		shoe_input = ""
	shoe_input += digit
	modal_body.text = "[center][font_size=34]" + " ".join(shoe_input.split("")) + "[/font_size][/center]"
	if shoe_input.length() != 3:
		return
	if shoe_input == "240" and flags.get("shoe_size_seen", false):
		flags["shoe_cabinet_unlocked"] = true
		_show_interactive_closeup("양쪽 문이 열린다", "왼쪽 칸의 접힌 쪽지를 누른다.", "res://assets/closeups/childhood/shoe-cabinet-open.png", [{"label": "엄마의 쪽지", "rect": Rect2(0.08, 0.19, 0.42, 0.52), "callback": _reveal_mother_note}])
		_set_status("240을 입력해 신발장을 열었다.")
		_save()
	else:
		_set_status("비밀번호가 맞지 않는다. 오른쪽 구두 안쪽을 다시 살펴보자.")


func _reveal_mother_note() -> void:
	_add_item("mother_note")
	flags["mother_note_collected"] = true
	_show_closeup(
		"엄마의 쪽지",
		"[font_size=21]“엄마 나갔다 올게.\nTV는 소리 14로 맞춰서 봐.\n시끄러우면 아빠 화낸다.”[/font_size]",
		[],
		"res://assets/closeups/childhood/mother-note.png"
	)
	_set_status("TV 볼륨을 14에 맞추라는 쪽지를 발견했다.")
	_render()


func _inspect_tv_drawer() -> void:
	if not flags.get("tv_drawer_open", false):
		_show_interactive_closeup("TV 아래 서랍장", "서랍을 직접 눌러 연다.", "res://assets/closeups/childhood/tv-drawer-closed.png", [{"label": "서랍 열기", "rect": Rect2(0.08, 0.48, 0.84, 0.32), "callback": _open_tv_drawer}])
	elif not flags.get("empty_remote_collected", false):
		_open_tv_drawer()
	else:
		_show_closeup("열린 TV 서랍", "리모컨을 꺼낸 서랍은 비어 있다.", [], "res://assets/closeups/childhood/tv-drawer-open-empty.jpg")


func _open_tv_drawer() -> void:
	flags["tv_drawer_open"] = true
	_show_interactive_closeup("열린 TV 서랍", "그림 속 리모컨을 눌러 집어 든다.", "res://assets/closeups/childhood/tv-drawer-open.png", [{"label": "건전지 없는 리모컨", "rect": Rect2(0.31, 0.47, 0.42, 0.3), "callback": _collect_empty_remote}])
	_save()


func _collect_empty_remote() -> void:
	_add_item("empty_remote")
	flags["empty_remote_collected"] = true
	_set_status("건전지 없는 리모컨을 얻었다.")
	_show_closeup("열린 TV 서랍", "리모컨을 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/tv-drawer-open-empty.jpg")
	_render()


func _inspect_sofa() -> void:
	if flags.get("sofa_cushion_lifted", false):
		if flags.get("sofa_battery_collected", false):
			_show_closeup("들린 소파 쿠션", "건전지를 꺼낸 자리는 비어 있다.", [], "res://assets/closeups/childhood/sofa-cushion-lifted-empty.jpg")
		else:
			_lift_sofa_cushion()
		return
	_show_interactive_closeup("소파 쿠션", "쿠션을 직접 눌러 들어 올린다.", "res://assets/closeups/childhood/sofa-cushion.png", [{"label": "소파 쿠션", "rect": Rect2(0.15, 0.2, 0.72, 0.57), "callback": _lift_sofa_cushion}])


func _lift_sofa_cushion() -> void:
	flags["sofa_cushion_lifted"] = true
	_show_interactive_closeup("쿠션 아래", "그림 속 건전지를 눌러 집어 든다.", "res://assets/closeups/childhood/sofa-cushion-lifted.png", [{"label": "건전지", "rect": Rect2(0.4, 0.42, 0.25, 0.2), "callback": _collect_sofa_battery}])
	_set_status("쿠션 밑에 있는 건전지를 누르세요.")
	_render()


func _collect_sofa_battery() -> void:
	_add_item("battery_1")
	flags["sofa_battery_collected"] = true
	_show_closeup("들린 소파 쿠션", "건전지를 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/sofa-cushion-lifted-empty.jpg")
	_set_status("소파 쿠션 밑에서 건전지 한 개를 얻었다.")
	_render()


func _inspect_clock() -> void:
	if flags.get("clock_turned", false):
		if flags.get("clock_battery_collected", false):
			_show_closeup("멈춘 시계의 뒷면", "건전지를 꺼낸 칸은 비어 있다.", [], "res://assets/closeups/childhood/clock-back-empty.jpg")
		else:
			_turn_clock()
		return
	_show_interactive_closeup("멈춘 벽시계", "시계를 직접 눌러 뒤집는다.", "res://assets/closeups/childhood/clock-front.png", [{"label": "시계 뒤집기", "rect": Rect2(0.22, 0.08, 0.56, 0.78), "callback": _turn_clock}])


func _turn_clock() -> void:
	flags["clock_turned"] = true
	_show_interactive_closeup("시계 뒷면", "건전지 칸의 건전지를 눌러 꺼낸다.", "res://assets/closeups/childhood/clock-back.png", [{"label": "건전지", "rect": Rect2(0.39, 0.34, 0.22, 0.33), "callback": _collect_clock_battery}])
	_set_status("시계 뒷면의 건전지를 누르세요.")
	_render()


func _collect_clock_battery() -> void:
	_add_item("battery_2")
	flags["clock_battery_collected"] = true
	_show_closeup("시계 뒷면", "건전지를 인벤토리에 넣었다.", [], "res://assets/closeups/childhood/clock-back-empty.jpg")
	_set_status("멈춘 시계에서 건전지 한 개를 얻었다.")
	_render()


func _inspect_tv() -> void:
	if selected_item != "powered_remote":
		_set_status("TV는 꺼져 있다. 건전지가 든 리모컨이 필요하다.")
		_show_modal("꺼진 TV", "검은 화면 아래의 수신등만 희미하게 켜져 있다.", [], "res://assets/closeups/childhood/tv-screen.png")
		return
	_show_volume_control()


func _show_volume_control() -> void:
	var volume := int(flags.get("tv_volume", 0))
	if volume == 14 and flags.get("storybook_page_5_revealed", false) and not flags.get("storybook_page_5_found", false):
		_show_interactive_closeup("볼륨 14", "현재 볼륨 14 · 화면에 나타난 페이지를 눌러 집어 든다.", "res://assets/closeups/childhood/tv-volume-14.png", [{"label": "동화책 다섯 번째 페이지", "rect": Rect2(0.56, 0.66, 0.33, 0.24), "callback": _collect_storybook_page_5}])
		return
	_show_interactive_closeup("리모컨 볼륨", "[font_size=24]현재 볼륨  " + str(volume) + "[/font_size]\n리모컨 그림의 + / − 버튼을 직접 누른다.", "res://assets/closeups/childhood/remote-volume.png", [{"label": "볼륨 올리기", "rect": Rect2(0.42, 0.48, 0.17, 0.13), "callback": _change_tv_volume.bind(1)}, {"label": "볼륨 내리기", "rect": Rect2(0.42, 0.62, 0.17, 0.14), "callback": _change_tv_volume.bind(-1)}])


func _change_tv_volume(delta: int) -> void:
	var volume := clampi(int(flags.get("tv_volume", 0)) + delta, 0, 30)
	flags["tv_volume"] = volume
	if volume == 14:
		flags["tv_volume_set"] = true
		if not flags.get("storybook_page_5_found", false):
			flags["storybook_page_5_revealed"] = true
			_show_volume_control()
		_set_status("볼륨 14에서 나타난 동화책 페이지를 누르세요.")
	else:
		_show_volume_control()
	_save()


func _collect_storybook_page_5() -> void:
	_add_item("storybook_page_5")
	flags["storybook_page_5_found"] = true
	_set_status("동화책의 다섯 번째 페이지를 인벤토리에 넣었다.")
	_show_volume_control()
	_render()


func _combine_dragged_items(source: String, target: String) -> void:
	if source == target or not inventory.has(source) or not inventory.has(target):
		return
	var combined := true
	if _same_pair(source, target, "needle", "thread"):
		_consume_pair(source, target)
		_add_item("sewing_kit")
		flags["sewing_kit_made"] = true
		_set_status("바늘을 실에 끼워 바느질 세트를 만들었다.")
	elif _same_pair(source, target, "block_yellow", "block_blue"):
		if not flags.get("train_order_seen", false):
			_set_status("블록의 순서를 알려 주는 단서를 먼저 찾아야 한다.")
			combined = false
		else:
			_consume_pair(source, target)
			_add_item("train_pair_yellow_blue")
			_show_closeup("연결된 기차 블록", "노란 기관차와 파란 객차가 연결되었다.", [], "res://assets/items/childhood/train-pair-yellow-blue.png")
			_set_status("노란 블록과 파란 블록을 연결했다. 마지막 객차가 필요하다.")
	elif _same_pair(source, target, "train_pair_yellow_blue", "block_red"):
		_consume_pair(source, target)
		_add_item("repaired_train")
		flags["train_blocks_combined"] = true
		_show_closeup("수리된 장난감 기차", "액자에서 본 순서대로 노랑, 파랑, 빨강 객차를 연결했다.", [], "res://assets/items/childhood/repaired-train-blocks.png")
		_set_status("수리된 장난감 기차를 얻었다.")
	elif (
		(source == "empty_remote" and target in ["battery_1", "battery_2"])
		or (target == "empty_remote" and source in ["battery_1", "battery_2"])
	):
		_consume_pair(source, target)
		_add_item("remote_one_battery")
		_set_status("리모컨에 건전지 한 개를 넣었다. 한 개가 더 필요하다.")
	elif (
		(source == "remote_one_battery" and target in ["battery_1", "battery_2"])
		or (target == "remote_one_battery" and source in ["battery_1", "battery_2"])
	):
		_consume_pair(source, target)
		_add_item("powered_remote")
		flags["remote_powered"] = true
		_show_modal("작동하는 리모컨", "건전지 두 개를 넣자 작은 전원등이 켜졌다.", [], "res://assets/closeups/childhood/remote-powered.png")
		_set_status("건전지가 들어간 리모컨을 얻었다.")
	elif source in ["storybook_page_3", "storybook_page_4", "storybook_page_5"] and target in ["storybook_page_3", "storybook_page_4", "storybook_page_5"]:
		_consume_pair(source, target)
		_add_item("storybook_page_pair")
		_set_status("찾은 동화책 페이지 두 장을 맞췄다. 마지막 한 장이 더 필요하다.")
	elif (
		(source == "storybook_page_pair" and target in ["storybook_page_3", "storybook_page_4", "storybook_page_5"])
		or (target == "storybook_page_pair" and source in ["storybook_page_3", "storybook_page_4", "storybook_page_5"])
	):
		_consume_pair(source, target)
		_add_item("completed_storybook")
		flags["storybook_completed"] = true
		_set_status("세 페이지를 모두 맞춰 ‘점박이 곰과 하얀 곰’을 완성했다.")
		_refresh_inventory()
		_save()
		_open_storybook(0)
		return
	elif _same_pair(source, target, "torn_shoe", "clear_tape"):
		_consume_pair(source, target)
		_add_item("repaired_shoe")
		flags["shoe_repaired"] = true
		_show_modal("되찾은 이름", "실내화 안쪽, 테이프에 가려졌던 글씨가 드러난다.\n\n[center][font_size=32]윤 · 슬 · 기[/font_size][/center]\n\n낙서는 이름이 아니다.", [])
		_set_status("지워지지 않은 본래의 이름을 찾았다.")
	elif _same_pair(source, target, "bus_ticket", "phone"):
		_remove_item("bus_ticket")
		flags["phone_unlocked"] = true
		_show_modal("잠금 화면", "표의 날짜 10월 9일을 입력했다.\n\n메모 앱에는 한 문장만 남아 있다.\n[italic]“내일 오전 9시, 창가의 화분에 물 주기.”[/italic]", [])
		_set_status("휴대전화가 열렸다. 내일을 위한 작은 약속을 찾았다.")
	elif source in ["courage_vial", "will_vial", "self_trust_vial"] and target in ["courage_vial", "will_vial", "self_trust_vial"]:
		if not flags.get("records_seen", false):
			_set_status("세 감정이 어떤 의미인지 기록을 먼저 확인해야 한다.")
			combined = false
		else:
			_consume_pair(source, target)
			_add_item("emotion_vial_pair")
			_set_status("두 감정의 병이 하나로 이어졌다. 마지막 병을 더해 보자.")
	elif (
		(source == "emotion_vial_pair" and target in ["courage_vial", "will_vial", "self_trust_vial"])
		or (target == "emotion_vial_pair" and source in ["courage_vial", "will_vial", "self_trust_vial"])
	):
		_consume_pair(source, target)
		_add_item("heart_key")
		flags["heart_key_made"] = true
		_show_modal("마음의 열쇠", "[center]용기, 의지, 자기 신뢰가 하나의 열쇠가 된다.\n\n상처가 사라진 것은 아니다.\n하지만 이제 문을 열 사람을 알고 있다.[/center]", [])
		_set_status("마음의 열쇠가 완성되었다.")
	else:
		combined = false
		_set_status("이 두 물건은 서로 맞지 않는다.")
	if combined:
		selected_item = ""
		_refresh_inventory()
		_save()


func _same_pair(source: String, target: String, first: String, second: String) -> bool:
	return (source == first and target == second) or (source == second and target == first)


func _consume_pair(source: String, target: String) -> void:
	_remove_item(source)
	_remove_item(target)


func _inspect_floor_book() -> void:
	_show_interactive_closeup("바닥에 떨어진 책", "표지의 X 책을 눌러 집어 든다.", "res://assets/closeups/childhood/alphabet-book-floor.png", [] if flags.get("alphabet_book_collected", false) else [{"label": "알파벳 X 책", "rect": Rect2(0.2, 0.12, 0.6, 0.72), "callback": _collect_alphabet_book}])


func _collect_alphabet_book() -> void:
	_add_item("alphabet_book")
	flags["alphabet_book_collected"] = true
	_close_modal()
	_set_status("바닥에서 알파벳 X 책을 주웠다. 전화기 아래 책장의 빈자리가 떠오른다.")
	_render()


func _inspect_alphabet_bookcase() -> void:
	if flags.get("diary_revealed", false):
		if flags.get("diary_collected", false):
			_show_closeup("열린 비밀 칸", "", [], "res://assets/closeups/childhood/alphabet-bookcase-empty-after-diary.jpg")
		else:
			_show_interactive_closeup("숨겨진 그림일기", "그림 속 일기장을 눌러 꺼낸다.", "res://assets/closeups/childhood/alphabet-bookcase-diary.png", [{"label": "그림일기", "rect": Rect2(0.3, 0.42, 0.42, 0.42), "callback": _collect_picture_diary}])
		return
	_show_interactive_closeup("알파벳 책장", "X 책을 선택한 뒤 가운데 빈자리를 누른다.", "res://assets/closeups/childhood/alphabet-bookcase-empty.png", [{"label": "책장의 빈자리", "rect": Rect2(0.42, 0.22, 0.18, 0.5), "callback": _insert_alphabet_book}])
	if not inventory.has("alphabet_book"):
		_set_status("책장의 가운데 한 자리가 비어 있다. 바닥에 떨어진 책을 찾아보자.")


func _insert_alphabet_book() -> void:
	if not inventory.has("alphabet_book"):
		_set_status("빈자리에 맞는 책이 필요하다.")
		return
	_remove_item("alphabet_book")
	flags["diary_revealed"] = true
	selected_item = ""
	_show_interactive_closeup("숨겨진 그림일기", "그림 속 일기장을 눌러 꺼낸다.", "res://assets/closeups/childhood/alphabet-bookcase-diary.png", [{"label": "그림일기", "rect": Rect2(0.3, 0.42, 0.42, 0.42), "callback": _collect_picture_diary}])
	_set_status("알파벳 책장의 비밀 칸에서 그림일기를 발견했다.")
	_refresh_inventory()
	_save()


func _collect_picture_diary() -> void:
	_add_item("picture_diary")
	flags["diary_collected"] = true
	_set_status("그림일기를 얻었다. 소지품에서 여러 번 펼쳐 단서를 확인할 수 있다.")
	_refresh_inventory()
	_save()
	_show_closeup("열린 비밀 칸", "", [], "res://assets/closeups/childhood/alphabet-bookcase-empty-after-diary.jpg")


func _open_diary(page: int = 0) -> void:
	diary_page = clampi(page, 0, DIARY_PAGE_COUNT)
	flags["diary_page_%02d_seen" % diary_page] = true
	var image_path := "res://assets/closeups/childhood/diary/cover.png" if diary_page == 0 else "res://assets/closeups/childhood/diary/page-%02d.png" % diary_page
	var hotspots: Array = []
	if diary_page > 0:
		hotspots.append({"label": "이전 장", "rect": Rect2(0.0, 0.12, 0.14, 0.7), "callback": _open_diary.bind(diary_page - 1)})
	if diary_page < DIARY_PAGE_COUNT:
		hotspots.append({"label": "다음 장", "rect": Rect2(0.86, 0.12, 0.14, 0.7), "callback": _open_diary.bind(diary_page + 1)})
	_show_interactive_closeup("그림일기", "", image_path, hotspots)
	_save()


func _diary_caption(page: int) -> String:
	return {
		0: "표지에는 아이와 부모, 하얀 곰인형 몽이가 함께 그려져 있다.",
		1: "몽이를 안고 10부터 거꾸로 세면 큰 소리가 멈췄다고 적혀 있다.",
		2: "엄마는 처음 보는 아저씨를 아빠에게 비밀로 해 달라고 했다.",
		3: "아빠가 엄마에게 나가라고 소리쳤고, 아이는 다시 숫자를 거꾸로 셌다.",
		4: "엄마는 미안하다는 말과 함께 바퀴 달린 가방을 끌고 어두운 밖으로 나갔다.",
		5: "5쪽은 크게 찢겨 나가 읽을 수 없다.",
		6: "6쪽도 대부분 찢겨 나가 있다.",
		7: "7쪽에는 종잇조각과 희미한 크레용 자국만 남아 있다.",
		8: "8쪽은 가장자리만 남고 통째로 사라졌다.",
		9: "엄마가 돌아오지 않는 동안 아빠는 이상한 냄새를 풍기며 무서운 말을 했다.",
		10: "아빠가 던진 장난감 기차가 부서졌다는 기록이다.",
		11: "몽이마저 망가졌고, 아이는 자신이 고칠 수 있을지 묻고 있다.",
		12: "아이는 몸의 얼룩 때문에 밖에 나가면 안 된다는 말을 믿고 집에서 기다렸다."
	}.get(page, "")


func _open_storybook(page: int = 0) -> void:
	storybook_page = clampi(page, 0, STORYBOOK_PAGES.size())
	var hotspots: Array = []
	if storybook_page > 0:
		hotspots.append({"label": "이전 페이지", "rect": Rect2(0.0, 0.1, 0.14, 0.68), "callback": _open_storybook.bind(storybook_page - 1)})
	if storybook_page < STORYBOOK_PAGES.size():
		hotspots.append({"label": "다음 페이지" if storybook_page < STORYBOOK_PAGES.size() - 1 else "맨 뒷장", "rect": Rect2(0.86, 0.1, 0.14, 0.68), "callback": _open_storybook.bind(storybook_page + 1)})
	if storybook_page == STORYBOOK_PAGES.size():
		flags["storybook_code_seen"] = true
		_show_interactive_closeup("점박이 곰과 하얀 곰 · 맨 뒷장", "책의 맨 뒷장에 연필로 눌러쓴 숫자\n[font_size=44][b]1366[/b][/font_size]", "res://assets/items/childhood/storybook.png", hotspots)
		_set_status("완성된 동화책의 맨 뒷장에서 1366을 확인했다.")
	else:
		_show_interactive_closeup("점박이 곰과 하얀 곰 · %d/5" % (storybook_page + 1), STORYBOOK_PAGES[storybook_page], "res://assets/closeups/childhood/storybook/page-%02d.jpg" % (storybook_page + 1), hotspots)
	_save()


func _open_phone() -> void:
	phone_input = ""
	_show_closeup("구형 다이얼 전화기", "[font_size=28]— — — —[/font_size]\n다이얼의 숫자 구멍을 차례로 누른다.", [], "res://assets/items/childhood/rotary-phone.png")
	var positions := {
		"1": Vector2(0.474, 0.412), "2": Vector2(0.485, 0.450), "3": Vector2(0.479, 0.493),
		"4": Vector2(0.463, 0.526), "5": Vector2(0.438, 0.544), "6": Vector2(0.411, 0.545),
		"7": Vector2(0.387, 0.529), "8": Vector2(0.371, 0.498), "9": Vector2(0.362, 0.460),
		"0": Vector2(0.371, 0.425)
	}
	for digit in positions:
		_add_closeup_hotspot("다이얼 " + digit, Rect2(positions[digit] - Vector2(0.022, 0.03), Vector2(0.044, 0.06)), _dial_digit.bind(digit))


func _dial_digit(digit: String) -> void:
	if phone_input.length() >= 4:
		phone_input = ""
	phone_input += digit
	var display := " ".join(phone_input.split(""))
	closeup_caption.text = "[center][font_size=30]" + display + "[/font_size]\n다이얼의 숫자 구멍을 차례로 누른다.[/center]"
	if phone_input.length() == 4:
		if phone_input == "1366" and inventory.has("completed_storybook") and flags.get("storybook_code_seen", false):
			_add_item("courage")
			_add_item("door_key")
			flags["phone_code_entered"] = true
			flags["courage_obtained"] = true
			_close_modal()
			_set_status("전화기 아래 칸이 열렸다. 용기의 눈물과 열쇠를 얻었다.")
			_render()
		elif phone_input == "1366":
			_set_status("번호는 맞지만, 완성된 동화책의 맨 뒷장을 직접 확인해야 한다.")
		else:
			_set_status("연결되지 않는다. 번호를 다시 생각해 보자.")


func _use_door() -> void:
	if selected_item != "door_key":
		_set_status("닫힌 문에는 작은 열쇠구멍이 있다.")
		return
	_remove_item("door_key")
	flags["childhood_complete"] = true
	flags["chapter_returned"] = true
	selected_item = ""
	_set_status("문이 열렸다. 열린 문을 누르면 약방으로 돌아갑니다.")
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
	direction_index = 0
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
	if item == "picture_diary":
		_open_diary(0)
		return
	if item == "completed_storybook":
		_open_storybook(0)
		return
	selected_item = "" if selected_item == item else item
	if selected_item.is_empty():
		_set_status("아이템 선택을 해제했다.")
	else:
		_set_status(_item_name(selected_item) + " 선택됨")
	_refresh_inventory()
	if not selected_item.is_empty() and not closeup_layer.visible:
		_inspect_inventory_item(selected_item)


func _inspect_inventory_item(item: String) -> void:
	var body := _item_name(item) + "을(를) 선택했다. 아래 화살표로 방 화면에 돌아간 뒤 사용할 곳을 누르거나, 다른 아이템 위로 드래그해 조합한다."
	if item == "mother_note":
		body = "[font_size=21]“엄마 나갔다 올게.\nTV는 소리 14로 맞춰서 봐.\n시끄러우면 아빠 화낸다.”[/font_size]"
	var path := _item_texture_path(item)
	if not path.is_empty():
		_show_closeup(_item_name(item), body, [], path)


func _show_hint() -> void:
	var hint := "빛나는 편지함을 살펴보세요."
	if current_place == "pharmacy":
		if flags.get("chapter_returned", false):
			hint = "정면의 조제대를 살펴보세요."
		else:
			hint = "오른쪽 방향의 편지함을 살펴보세요."
	elif current_place == "childhood":
		if not flags.get("alphabet_book_collected", false):
			hint = "정면 책장 앞 바닥에 떨어진 알파벳 X 책을 찾으세요."
		elif not flags.get("diary_revealed", false):
			hint = "정면의 전화기 아래 알파벳 책장을 열고 X 책을 빈자리에 꽂으세요."
		elif not flags.get("diary_collected", false):
			hint = "알파벳 책장 비밀 칸에서 그림일기를 꺼내세요."
		elif not flags.get("diary_page_01_seen", false):
			hint = "소지품의 그림일기를 펼쳐 첫 번째 기록부터 읽어 보세요."
		elif not flags.get("needle_collected", false):
			hint = "뒤쪽 서랍장을 열어 바늘을 찾으세요."
		elif not flags.get("thread_collected", false):
			hint = "뒤쪽 옷장을 열고 올이 풀린 니트에서 실을 얻으세요."
		elif not flags.get("sewing_kit_made", false):
			hint = "바늘과 실을 조합해 바느질 세트를 만드세요."
		elif not flags.get("bear_collected", false):
			hint = "오른쪽 바닥의 뜯어진 곰인형을 살펴보세요."
		elif not flags.get("bear_repaired", false):
			hint = "곰인형을 열어 클로즈업한 뒤 바느질 세트를 선택하고 벌어진 배를 누르세요."
		elif not flags.get("storybook_page_3_found", false):
			hint = "꼬매진 곰인형을 선택하고 왼쪽 침대를 누르세요."
		elif not flags.get("blocks_collected", false):
			hint = "오른쪽 바닥의 빨강, 노랑, 파랑 기차 블록을 주우세요."
		elif not flags.get("train_order_seen", false):
			hint = "오른쪽 벽의 기차 그림 액자에서 색 순서를 확인하세요."
		elif not flags.get("train_blocks_combined", false):
			hint = "노랑, 파랑, 빨강 블록을 조합해 기차를 수리하세요."
		elif not flags.get("train_repaired", false):
			hint = "수리된 기차를 선택하고 오른쪽 바닥의 레일을 누르세요."
		elif not flags.get("shoe_size_seen", false):
			hint = "왼쪽 신발장의 열린 오른쪽 칸에서 낡은 구두 안쪽을 확인하세요."
		elif not flags.get("shoe_cabinet_unlocked", false):
			hint = "왼쪽 신발장 잠금장치에 구두 크기 240을 입력하세요."
		elif not flags.get("mother_note_collected", false):
			hint = "열린 신발장 왼쪽 칸에서 엄마의 쪽지를 읽으세요."
		elif not flags.get("empty_remote_collected", false):
			hint = "오른쪽 TV 아래 서랍을 열어 리모컨을 찾으세요."
		elif not flags.get("sofa_battery_collected", false):
			hint = "왼쪽 소파 쿠션을 들고 그림 속 첫 번째 건전지를 누르세요."
		elif not flags.get("clock_battery_collected", false):
			hint = "왼쪽 벽의 멈춘 시계를 뒤집고 그림 속 두 번째 건전지를 누르세요."
		elif not flags.get("remote_powered", false):
			hint = "건전지 없는 리모컨과 건전지 두 개를 조합하세요."
		elif not flags.get("tv_volume_set", false):
			hint = "작동하는 리모컨을 선택해 TV 볼륨을 14로 맞추세요."
		elif not flags.get("storybook_completed", false):
			hint = "침대, 기차 레일, TV에서 얻은 동화책 3·4·5쪽을 서로 드래그해 완성하세요."
		elif not flags.get("storybook_code_seen", false):
			hint = "완성된 동화책을 펼치고 맨 뒷장의 번호를 확인하세요."
		elif not flags.get("courage_obtained", false):
			hint = "동화책 맨 뒷장의 1366을 정면 구형 전화기에 입력하세요."
		else:
			hint = "열쇠를 선택한 뒤 뒤쪽의 닫힌 문을 눌러 보세요."
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
	var actions: Array = [
		{"label": "힌트 보기", "callback": _show_hint},
		{
			"label": "개발자 모드 끄기" if developer_mode else "개발자 모드 켜기",
			"callback": _toggle_developer_mode
		}
	]
	if developer_mode:
		actions.append({"label": "개발자 메뉴", "callback": _open_developer_menu})
	actions.append({"label": "처음부터", "callback": _confirm_reset})
	var developer_status := "\n\n[color=#8b5d35]개발자 모드가 켜져 있습니다.[/color]" if developer_mode else ""
	_show_modal(
		"설정",
		"[center]게임 진행은 자동으로 저장됩니다." + developer_status + "[/center]",
		actions
	)


func _toggle_developer_mode() -> void:
	developer_mode = not developer_mode
	_save()
	_open_settings()


func _open_developer_menu() -> void:
	if not developer_mode:
		_open_settings()
		return
	_show_modal(
		"개발자 메뉴",
		"[center]장면 이동과 퍼즐 상태를 빠르게 테스트합니다.\n테스트 변경 사항도 자동 저장됩니다.[/center]",
		[
			{"label": "현재 챕터 퍼즐 준비 완료", "callback": _developer_solve_current},
			{"label": "약방으로 이동", "callback": _developer_jump.bind("pharmacy")},
			{"label": "유년기로 이동", "callback": _developer_jump.bind("childhood")},
			{"label": "청소년기로 이동", "callback": _developer_jump.bind("school")},
			{"label": "성년기로 이동", "callback": _developer_jump.bind("adult")},
			{"label": "진실의 방으로 이동", "callback": _developer_jump.bind("truth")}
		]
	)


func _developer_jump(place: String) -> void:
	if not developer_mode or not place in ["pharmacy", "childhood", "school", "adult", "truth"]:
		return
	_close_modal()
	current_place = place
	direction_index = 0
	selected_item = ""
	_set_status("[개발자] " + _direction_name())
	_render()


func _developer_solve_current() -> void:
	if not developer_mode:
		return
	match current_place:
		"pharmacy":
			_add_item("courage_vial")
			_add_item("will_vial")
			_add_item("self_trust_vial")
			flags["medicine_brewed"] = true
			flags["school_medicine_brewed"] = true
			flags["adult_medicine_brewed"] = true
			flags["chapter_returned"] = false
		"childhood":
			flags.merge({
				"alphabet_book_collected": true,
				"diary_revealed": true,
				"diary_collected": true,
				"diary_page_01_seen": true,
				"dresser_open": true,
				"needle_collected": true,
				"wardrobe_open": true,
				"thread_collected": true,
				"sewing_kit_made": true,
				"bear_collected": true,
				"bear_repaired": true,
				"storybook_page_3_found": true,
				"blocks_collected": true,
				"train_order_seen": true,
				"train_blocks_combined": true,
				"train_repaired": true,
				"storybook_page_4_found": true,
				"storybook_completed": true,
				"storybook_code_seen": true,
				"shoe_size_seen": true,
				"shoe_cabinet_unlocked": true,
				"mother_note_collected": true,
				"tv_drawer_open": true,
				"empty_remote_collected": true,
				"sofa_cushion_lifted": true,
				"clock_turned": true,
				"remote_powered": true,
				"tv_volume": 14,
				"tv_volume_set": true,
				"storybook_page_5_found": true,
				"phone_code_entered": true,
				"courage_obtained": true
			}, true)
			_add_item("picture_diary")
			_add_item("completed_storybook")
			_add_item("courage")
			_add_item("door_key")
		"school":
			flags.merge({
				"desk_read": true,
				"locker_open": true,
				"shoe_repaired": true,
				"attendance_read": true,
				"blackboard_solved": true,
				"whispers_quiet": true
			}, true)
			_add_item("will")
			_add_item("school_key")
		"adult":
			flags.merge({
				"power_off": true,
				"stars_read": true,
				"dream_note_read": true,
				"phone_unlocked": true,
				"plant_watered": true
			}, true)
			_add_item("phone")
			_add_item("self_trust")
			_add_item("adult_key")
		"truth":
			flags["mirror_seen"] = true
			flags["records_seen"] = true
			_add_item("courage_vial")
			_add_item("will_vial")
			_add_item("self_trust_vial")
	_close_modal()
	_set_status("[개발자] 현재 챕터의 마지막 상호작용을 테스트할 수 있습니다.")
	_render()


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
	phone_input = ""
	shoe_input = ""
	diary_page = 0
	storybook_page = 0
	_close_modal()
	_set_status("빛나는 편지함을 눌러 보세요.")
	_render()


func _show_modal(heading: String, body: String, actions: Array, image_path: String = "") -> void:
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		_show_closeup(heading, body, actions, image_path)
		return
	_close_closeup()
	for child in modal_actions.get_children():
		child.queue_free()
	modal_title.text = heading
	modal_body.text = body
	modal_image.texture = null
	modal_image.visible = false
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		modal_image.texture = load(image_path) as Texture2D
		modal_image.visible = modal_image.texture != null
	for action in actions:
		var button := _make_button(str(action["label"]))
		button.pressed.connect(action["callback"])
		modal_actions.add_child(button)
	modal_layer.visible = true


func _close_modal() -> void:
	modal_layer.visible = false
	_close_closeup()


func _show_closeup(heading: String, body: String, actions: Array, image_path: String) -> void:
	modal_layer.visible = false
	for child in closeup_actions.get_children():
		child.queue_free()
	_clear_closeup_hotspots()
	closeup_image.texture = load(image_path) as Texture2D
	closeup_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if "/items/" in image_path else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var caption := body.strip_edges()
	closeup_caption_panel.visible = not caption.is_empty()
	closeup_caption.text = "[center]" + caption + "[/center]" if not caption.is_empty() else ""
	for action in actions:
		var button := _make_button(str(action["label"]))
		button.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0.76), Color(1, 1, 1, 0.38), 1))
		button.add_theme_stylebox_override("hover", _panel_style(Color(0.08, 0.07, 0.06, 0.94), COLOR_GOLD, 2))
		button.pressed.connect(action["callback"])
		closeup_actions.add_child(button)
	closeup_layer.visible = true
	status_label.visible = false


func _clear_closeup_hotspots() -> void:
	if closeup_hotspot_layer == null:
		return
	for child in closeup_hotspot_layer.get_children():
		child.queue_free()


func _add_closeup_hotspot(label_text: String, normalized_rect: Rect2, callback: Callable) -> void:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = label_text
	button.accessibility_name = label_text
	button.anchor_left = normalized_rect.position.x
	button.anchor_top = normalized_rect.position.y
	button.anchor_right = normalized_rect.end.x
	button.anchor_bottom = normalized_rect.end.y
	button.add_theme_stylebox_override("normal", _transparent_style())
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.92, 0.75, 0.34, 0.06), Color(0.92, 0.75, 0.34, 0.62), 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color.TRANSPARENT, COLOR_GOLD, 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.92, 0.75, 0.34, 0.12), COLOR_GOLD, 2))
	button.pressed.connect(callback)
	closeup_hotspot_layer.add_child(button)


func _show_interactive_closeup(heading: String, body: String, image_path: String, hotspots: Array) -> void:
	_show_closeup(heading, body, [], image_path)
	for hotspot in hotspots:
		_add_closeup_hotspot(str(hotspot["label"]), hotspot["rect"], hotspot["callback"])


func _close_closeup() -> void:
	if closeup_layer == null:
		return
	closeup_layer.visible = false
	closeup_image.texture = null
	if status_label != null:
		status_label.visible = true


func _save() -> void:
	SaveManagerScript.save_game({
		"current_place": current_place,
		"direction_index": direction_index,
		"inventory": inventory,
		"flags": flags,
		"developer_mode": developer_mode
	})


func _migrate_childhood_save() -> void:
	# 구 버전에서는 쿠션/시계를 여는 순간 건전지가 자동 획득되었다.
	if flags.get("sofa_cushion_lifted", false):
		flags["sofa_battery_collected"] = true
	if flags.get("clock_turned", false):
		flags["clock_battery_collected"] = true
	if inventory.has("storybook_page_1"):
		inventory.erase("storybook_page_1")
		_add_item("storybook_page_3")
	if inventory.has("storybook_page_2"):
		inventory.erase("storybook_page_2")
		_add_item("storybook_page_4")
	if flags.get("storybook_page_1_found", false):
		flags["storybook_page_3_found"] = true
	if flags.get("train_repaired", false):
		flags["storybook_page_4_found"] = true
	if flags.get("tv_volume_set", false) and not flags.get("storybook_completed", false):
		_add_item("storybook_page_5")
		flags["storybook_page_5_found"] = true


func _add_item(item: String) -> void:
	if not inventory.has(item):
		inventory.append(item)


func _remove_item(item: String) -> void:
	inventory.erase(item)
	if selected_item == item:
		selected_item = ""


func _direction_name() -> String:
	var names := {
		"pharmacy": ["정면 · 조제대", "오른쪽 · 편지함", "뒤쪽 · 약병 진열장", "왼쪽 · 작업 책상"],
		"childhood": ["정면 · 창가와 긴 책상", "오른쪽 · TV와 장난감 레일", "뒤쪽 · 문, 서랍장과 옷장", "왼쪽 · 침대, 신발장과 소파"],
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
		"sewing_kit": "바느질 세트",
		"repaired_bear": "꼬매진 곰인형",
		"block_red": "빨간 기차 블록",
		"block_yellow": "노란 기차 블록",
		"block_blue": "파란 기차 블록",
		"train_pair_yellow_blue": "노랑·파랑 기차 블록",
		"repaired_train": "수리된 장난감 기차",
		"alphabet_book": "알파벳 X 책",
		"picture_diary": "그림일기",
		"storybook_page_3": "동화책 세 번째 페이지",
		"storybook_page_4": "동화책 네 번째 페이지",
		"storybook_page_5": "동화책 다섯 번째 페이지",
		"storybook_page_pair": "맞춰진 동화책 페이지 두 장",
		"completed_storybook": "완성된 동화책",
		"mother_note": "엄마의 쪽지",
		"empty_remote": "건전지 없는 리모컨",
		"remote_one_battery": "건전지가 하나 든 리모컨",
		"battery_1": "건전지",
		"battery_2": "건전지",
		"powered_remote": "작동하는 리모컨",
		"courage": "용기의 눈물",
		"door_key": "닫힌 문의 열쇠"
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
		,"emotion_vial_pair": "이어진 감정의 병"
		,"heart_key": "마음의 열쇠"
	}.get(item, item)


func _item_symbol(item: String) -> String:
	return {
		"torn_bear": "곰",
		"needle": "침",
		"thread": "실",
		"sewing_kit": "針",
		"repaired_bear": "곰",
		"block_red": "R",
		"block_yellow": "Y",
		"block_blue": "B",
		"train_pair_yellow_blue": "YB",
		"repaired_train": "車",
		"alphabet_book": "X",
		"picture_diary": "日",
		"storybook_page_3": "3",
		"storybook_page_4": "4",
		"storybook_page_5": "5",
		"storybook_page_pair": "頁",
		"completed_storybook": "冊",
		"mother_note": "書",
		"empty_remote": "遥",
		"remote_one_battery": "遥",
		"battery_1": "＋",
		"battery_2": "＋",
		"powered_remote": "遥",
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
		,"emotion_vial_pair": "ⅠⅡ"
		,"heart_key": "♢"
	}.get(item, "·")


func _item_texture_path(item: String) -> String:
	var paths := {
		"torn_bear": "res://assets/items/childhood/torn-bear.png",
		"needle": "res://assets/items/childhood/needle.png",
		"thread": "res://assets/items/childhood/thread.png",
		"sewing_kit": "res://assets/items/childhood/sewing-kit.png",
		"repaired_bear": "res://assets/items/childhood/repaired-bear.png",
		"block_red": "res://assets/items/childhood/block-red.png",
		"block_yellow": "res://assets/items/childhood/block-yellow.png",
		"block_blue": "res://assets/items/childhood/block-blue.png",
		"train_pair_yellow_blue": "res://assets/items/childhood/train-pair-yellow-blue.png",
		"repaired_train": "res://assets/items/childhood/repaired-train-blocks.png",
		"alphabet_book": "res://assets/items/childhood/alphabet-x-book.png",
		"picture_diary": "res://assets/closeups/childhood/diary/cover.png",
		"storybook_page_3": "res://assets/items/childhood/storybook-page.png",
		"storybook_page_4": "res://assets/items/childhood/storybook-page.png",
		"storybook_page_5": "res://assets/items/childhood/storybook-page.png",
		"storybook_page_pair": "res://assets/items/childhood/storybook-page.png",
		"completed_storybook": "res://assets/items/childhood/storybook.png",
		"mother_note": "res://assets/items/childhood/mother-note.png",
		"empty_remote": "res://assets/items/childhood/remote-empty.png",
		"remote_one_battery": "res://assets/items/childhood/remote-empty.png",
		"battery_1": "res://assets/items/childhood/battery.png",
		"battery_2": "res://assets/items/childhood/battery.png",
		"powered_remote": "res://assets/items/childhood/remote-powered.png",
		"courage": "res://assets/items/finale/emotion-vials.png",
		"door_key": "res://assets/items/school/school-key.png",
		"clear_tape": "res://assets/items/school/clear-tape.png",
		"torn_shoe": "res://assets/items/school/torn-shoe.png",
		"repaired_shoe": "res://assets/items/school/repaired-shoe.png",
		"name_card": "res://assets/items/school/name-card.png",
		"will": "res://assets/items/school/will-vial.png",
		"school_key": "res://assets/items/school/school-key.png",
		"bus_ticket": "res://assets/items/adult/bus-ticket.png",
		"phone": "res://assets/items/adult/phone.png",
		"self_trust": "res://assets/items/adult/self-trust-vial.png",
		"adult_key": "res://assets/items/adult/apartment-key.png",
		"courage_vial": "res://assets/items/finale/emotion-vials.png",
		"will_vial": "res://assets/items/school/will-vial.png",
		"self_trust_vial": "res://assets/items/adult/self-trust-vial.png",
		"emotion_vial_pair": "res://assets/items/finale/emotion-vials.png",
		"heart_key": "res://assets/items/finale/heart-key.png"
	}
	return str(paths.get(item, ""))


func _item_texture(item: String) -> Texture2D:
	var path := _item_texture_path(item)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


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
	var button := InventoryItemButtonScript.new() as InventoryItemButton
	button.text = glyph
	button.tooltip_text = accessible_name
	button.accessibility_name = accessible_name
	button.custom_minimum_size = Vector2(82, 82)
	button.add_theme_font_size_override("font_size", 24)
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
	if event.is_action_pressed("close_popup") and (modal_layer.visible or closeup_layer.visible):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left") and not modal_layer.visible and not closeup_layer.visible:
		_move_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right") and not modal_layer.visible and not closeup_layer.visible:
		_move_right()
		get_viewport().set_input_as_handled()
