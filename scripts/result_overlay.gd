class_name ResultOverlay
extends Control

signal next_pressed
signal retry_pressed
var panel: PanelContainer
var column: VBoxContainer
var dim: ColorRect
var decoration: UIFeedback
var reduced_motion: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.15, 0.1, 0.05, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.name = "Paper"
	panel.custom_minimum_size = Vector2(292, 0)
	panel.add_theme_stylebox_override("panel", UIFeedback.panel_style(Color("fff0d3"), Color("d3ac75"), 24))
	center.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	column = VBoxContainer.new()
	column.name = "Content"
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	decoration = UIFeedback.new()
	decoration.top_level = true
	decoration.name = "Celebration"
	decoration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(decoration)
	decoration.hide()
	hide()

func begin() -> VBoxContainer:
	for child: Node in column.get_children():
		column.remove_child(child)
		child.queue_free()
	show()
	panel.scale = Vector2.ONE
	return column

func label(text_value: String, font_size: int = 16, tint: Color = Color("583923")) -> Label:
	var item: Label = Label.new()
	item.text = text_value
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", tint)
	column.add_child(item)
	return item

func button(text_value: String, action: Callable) -> Button:
	var item: Button = Button.new()
	item.text = text_value
	item.custom_minimum_size.y = 40
	item.pressed.connect(action)
	column.add_child(item)
	return item

func present(rank: String, count: int, final_stage: bool, texture: Texture2D) -> void:
	begin()
	label("ALL CATS FIT!", 14)
	var art: TextureRect = TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size.y = 80
	column.add_child(art)
	var stamp: Label = label(rank + "!", 34, Color("b87f16") if rank == "PERFECT" else Color("437a49"))
	label("%d cells · one happy little box" % count, 13)
	if final_stage:
		label("10 / 10 COMPLETE\nEvery cat has a place to call home.", 15)
	var next: Button = button("ALL STAGES  ›" if final_stage else "NEXT STAGE  ›", func() -> void: hide(); next_pressed.emit())
	next.name = "Next"
	var retry: Button = button("KEEP TRIMMING", func() -> void: hide(); retry_pressed.emit())
	retry.name = "Retry"
	decoration.reduced_motion = reduced_motion
	if not reduced_motion:
		stamp.modulate.a = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(stamp, "modulate:a", 1.0, 0.16)
		tween.tween_callback(func() -> void: decoration.show(); decoration.celebrate())
		panel.pivot_offset = panel.size * 0.5
		panel.scale = Vector2(0.92, 0.92)
		create_tween().tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	next.grab_focus()
