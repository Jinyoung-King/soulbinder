extends Control
## 지역 맵(허브) — 전투 노드의 진행을 보여주고 현재 노드로 진입. 편성도 여기서.
## 클리어 ✓ / 현재 ▶ / 잠김 🔒. 마지막 노드까지 클리어하면 지역 완료 화면.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	v.offset_left = 40; v.offset_right = -40
	add_child(v)

	var done := GameState.region_node >= Encounters.count()

	var title := _label(Encounters.REGION_NAME, 30, Color(0.85, 0.82, 0.98))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var prog := "지역 클리어" if done else "진행 %d / %d" % [GameState.region_node, Encounters.count()]
	var sub := _label("%s    ·    거둔 영혼 %d · 증언 %d" % [prog, GameState.roster.size(), GameState.story_fragments.size()], 17, Color(0.6, 0.58, 0.72))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(_sep(8))

	# 노드 경로
	var path := HBoxContainer.new()
	path.add_theme_constant_override("separation", 10)
	path.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(path)
	for i in Encounters.count():
		if i > 0:
			var arrow := _label("→", 22, Color(0.4, 0.4, 0.5))
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			path.add_child(arrow)
		path.add_child(_node_card(i))

	v.add_child(_sep(10))

	# 완료 메시지 / 진입
	if done:
		var msg := _label("그날 밤의 끝을 보았다. 거둔 증언이 더 깊은 어둠을 가리킨다…", 18, Color(0.78, 0.74, 0.9))
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(msg)

	# 하단 버튼
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	if done:
		btns.add_child(_btn("지역 다시 도전", Color(0.6, 0.45, 0.95), func():
			GameState.region_node = 0
			get_tree().reload_current_scene()))
	else:
		var node := Encounters.get_node(GameState.region_node)
		btns.add_child(_btn("진입 ▸ %s" % node.name, Color(0.6, 0.45, 0.95), func(): get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")))
	btns.add_child(_btn("영혼 편성", Color(0.5, 0.62, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/party.tscn")))
	btns.add_child(_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn")))

func _node_card(i: int) -> Control:
	var node := Encounters.get_node(i)
	var cur := GameState.region_node
	var state := "cleared" if i < cur else ("current" if i == cur else "locked")

	var accent := Color(0, 0, 0, 0)
	var mark := "🔒"
	var name_col := Color(0.5, 0.48, 0.58)
	match state:
		"cleared":
			accent = Color(0.45, 0.78, 0.5); mark = "✓ 클리어"; name_col = Color(0.8, 0.85, 0.82)
		"current":
			accent = Color(0.7, 0.55, 1.0); mark = "▶ 현재"; name_col = Color.WHITE
		"locked":
			mark = "🔒 잠김"

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 110)
	card.add_theme_stylebox_override("panel", UIKit.panel(accent, 12, state != "locked"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	box.add_child(_label("%d. %s" % [i + 1, node.name], 17, name_col))
	box.add_child(_label(mark, 14, accent if accent.a > 0 else Color(0.5, 0.48, 0.58)))
	box.add_child(_label("적 %d" % node.enemies.size(), 13, Color(0.6, 0.58, 0.7)))

	# 현재 노드는 카드 클릭으로도 진입
	if state == "current":
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/battle/battle.tscn"))
		card.add_child(btn)
	return card

func _btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 19)
	UIKit.style_button(b, accent)
	b.pressed.connect(cb)
	return b

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _sep(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
