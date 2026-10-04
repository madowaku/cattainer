class_name BoardCell
extends Button

var index: int = 0
var active: bool = true
var visual_amount: float = 1.0
var wobble: float = 0.0
var highlight: Color = Color.TRANSPARENT
var motion: Tween = null
var reduced_motion: bool = false

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for key: String in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	tooltip_text = "Click to cut / restore cardboard"

func set_active(value: bool, animate: bool = true) -> void:
	active = value
	if motion != null:
		motion.kill()
	if not animate or reduced_motion:
		visual_amount = 1.0 if active else 0.0
		queue_redraw()
		return
	motion = create_tween()
	motion.tween_method(_set_amount, visual_amount, 1.0 if active else 0.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_amount(value: float) -> void:
	visual_amount = value
	queue_redraw()

func reject() -> void:
	if reduced_motion:
		return
	if motion != null:
		motion.kill()
	motion = create_tween()
	motion.tween_method(_set_wobble, 0.0, 1.0, 0.21)
	motion.tween_callback(func() -> void: wobble = 0.0; queue_redraw())

func _set_wobble(value: float) -> void:
	wobble = sin(value * TAU * 3.0) * (1.0 - value) * 4.0
	queue_redraw()

func _draw() -> void:
	var base: Rect2 = Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var recess: StyleBoxFlat = UIFeedback.panel_style(Color("59402c"), Color("a07850"), 4, false)
	draw_style_box(recess, base)
	for side: int in range(4):
		var start: Vector2 = base.position + Vector2(5, 5)
		var end: Vector2 = base.end - Vector2(5, 5)
		if side == 0 or side == 1:
			start.y = base.position.y + 5 if side == 0 else base.end.y - 5
			end.y = start.y
		else:
			start.x = base.position.x + 5 if side == 2 else base.end.x - 5
			end.x = start.x
		draw_dashed_line(start, end, Color(0.85, 0.7, 0.52, 0.36), 1.0, 4.0)
	if visual_amount > 0.01:
		var amount: float = maxf(visual_amount, 0.0)
		var tile: Rect2 = Rect2(base.get_center() - base.size * amount * 0.5 + Vector2(wobble, 0), base.size * amount)
		var tint: Color = Color("dba969")
		if is_hovered() and not disabled:
			tint = Color("efc38a")
		var surface: StyleBoxFlat = UIFeedback.panel_style(tint, Color("9d693a"), 4, false)
		surface.border_color = Color("a36f3e")
		surface.border_width_bottom = 3
		surface.border_width_top = 2
		draw_style_box(surface, tile)
		draw_line(tile.position + Vector2(3, 3), tile.position + Vector2(tile.size.x - 3, 3), Color("ffe0aa"), 1.5)
		# Fine kraft fibers are rendered natively, not a separate generated texture.
		for i: int in range(38):
			var fx: float = fmod(float(i * 17 + index * 7), 59.0) / 59.0
			var fy: float = fmod(float(i * 29 + index * 3), 61.0) / 61.0
			var point: Vector2 = tile.position + Vector2(4, 4) + (tile.size - Vector2(8, 8)) * Vector2(fx, fy)
			draw_line(point, point + Vector2(1.6, 0.4), Color(0.4, 0.25, 0.12, 0.15), 0.65)
		if highlight.a > 0.0:
			draw_style_box(UIFeedback.panel_style(highlight, highlight.lightened(0.3), 5, false), tile.grow(-3))
	if has_focus():
		draw_style_box(get_theme_stylebox("focus", "Button"), base.grow(-2))
