extends Button
class_name InventoryItemButton

signal item_dropped(source_item: String, target_item: String)

var item_id := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_id.is_empty() or disabled:
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(72, 72)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.85, 0.79, 0.66, 0.94)
	preview_style.border_color = Color(1, 1, 1, 0.9)
	preview_style.set_border_width_all(2)
	preview_style.set_corner_radius_all(10)
	preview.add_theme_stylebox_override("panel", preview_style)
	if icon != null:
		var preview_icon := TextureRect.new()
		preview_icon.texture = icon
		preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(preview_icon)
	else:
		var preview_label := Label.new()
		preview_label.text = text
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(preview_label)
	set_drag_preview(preview)
	return {"kind": "inventory_item", "item_id": item_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and str(data.get("kind", "")) == "inventory_item"
		and not item_id.is_empty()
		and str(data.get("item_id", "")) != item_id
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(str(data.get("item_id", "")), item_id)
