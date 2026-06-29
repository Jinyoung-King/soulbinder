extends Control
## 지역 맵(허브) — 분기 노드 그래프. 현재 위치에서 갈 수 있는 노드를 골라 전진.
## 정예(위험·큰보상) vs 휴식(안전·느림)의 갈림길. 보스 클리어 시 지역 완료.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	v.offset_left = 30; v.offset_right = -30
	add_child(v)

	var ri := GameState.region_idx
	var pos := GameState.run_pos
	var done: bool = pos != "" and RunMap.node(ri, pos).type == "boss"
	var reach: Array = [] if done else RunMap.reachable(ri, pos)
	var last_region: bool = ri >= RunMap.region_count() - 1

	var title := _label(RunMap.region(ri).name, 28, Color(0.85, 0.82, 0.98))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var head := "지역 클리어" if done else "갈림길을 선택하라 — 정예는 위험하지만 더 강해진다"
	var sub := _label("%s    ·    거둔 영혼 %d · 증언 %d" % [head, GameState.roster.size(), GameState.story_fragments.size()], 16, Color(0.6, 0.58, 0.72))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	# 출전 팀 HP 상태(휴식 결정용)
	var status: Array[String] = []
	for idx in GameState.party:
		if idx >= 0 and idx < GameState.roster.size():
			var e: Dictionary = GameState.roster[idx]
			status.append("%s %d/%d" % [e.name, int(e.get("hp", 0)), GameState.max_hp(e)])
	if not status.is_empty():
		var hp := _label("출전 팀  ·  " + "   ".join(status), 15, Color(0.7, 0.62, 0.6))
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hp)

	v.add_child(_sep(6))

	# 레이어별 컬럼
	var graph := HBoxContainer.new()
	graph.add_theme_constant_override("separation", 8)
	graph.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(graph)
	for layer in RunMap.max_layer(ri) + 1:
		if layer > 0:
			var arr := _label("→", 22, Color(0.38, 0.38, 0.5))
			arr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			graph.add_child(arr)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		for id in RunMap.order(ri):
			if RunMap.node(ri, id).layer == layer:
				col.add_child(_node_card(ri, id, reach))
		graph.add_child(col)

	v.add_child(_sep(8))

	if done:
		var msg := _label(RunMap.region(ri).get("outro", "지역을 클리어했다."), 18, Color(0.78, 0.74, 0.9))
		msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(msg)
		if last_region:  # 최종 결말 — 진실 공개
			var truth := _label("【 그날 밤의 진실 】  " + GameState.truth_hint(), 17, Color(0.85, 0.72, 0.55))
			truth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			truth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(truth)

	# 하단 버튼
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	if done and not last_region:
		btns.add_child(_btn("다음 지역으로", Color(0.6, 0.45, 0.95), func():
			GameState.region_idx += 1
			GameState.reset_run()
			get_tree().reload_current_scene()))
	elif done:
		btns.add_child(_btn("처음부터 (회복)", Color(0.6, 0.45, 0.95), func():
			GameState.region_idx = 0
			GameState.reset_run()
			get_tree().reload_current_scene()))
	btns.add_child(_btn("영혼 편성", Color(0.5, 0.62, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/party.tscn")))
	btns.add_child(_btn("증언의 서", Color(0.62, 0.55, 0.78), func(): get_tree().change_scene_to_file("res://scenes/ui/codex.tscn")))
	btns.add_child(_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn")))

func _node_card(ri: int, id: String, reach: Array) -> Control:
	var n := RunMap.node(ri, id)
	var cleared := GameState.run_cleared.has(id)
	var choosable := reach.has(id) and not cleared

	var accent := Color(0, 0, 0, 0)
	var state_txt := "잠김"
	var name_col := Color(0.5, 0.48, 0.58)
	if cleared:
		accent = Color(0.45, 0.78, 0.5); state_txt = "✓ 클리어"; name_col = Color(0.8, 0.85, 0.82)
	elif choosable:
		accent = Color(0.7, 0.55, 1.0); state_txt = "▶ 선택 가능"; name_col = Color.WHITE

	# 타입별 보상/위험 한 줄
	var info := ""
	match n.type:
		"battle": info = "전투 · 적 %d" % n.enemies.size()
		"elite": info = "정예 · 적 %d · 보상 +%dLv" % [n.enemies.size(), RunMap.ELITE_BONUS]
		"rest": info = "휴식 · 팀 회복 + %dLv" % RunMap.REST_LEVELS
		"boss": info = "보스 · 적 %d" % n.enemies.size()

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(186, 104)
	card.add_theme_stylebox_override("panel", UIKit.panel(accent, 12, cleared or choosable))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	box.add_child(_label(n.name, 16, name_col))
	box.add_child(_label(info, 13, _type_col(n.type)))
	box.add_child(_label(state_txt, 13, accent if accent.a > 0 else Color(0.5, 0.48, 0.58)))

	if choosable:
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(func(): _enter(ri, id))
		card.add_child(btn)
	return card

func _type_col(t: String) -> Color:
	match t:
		"elite": return Color(0.95, 0.7, 0.35)
		"rest": return Color(0.5, 0.8, 0.7)
		"boss": return Color(0.95, 0.45, 0.5)
		_: return Color(0.62, 0.6, 0.72)

func _enter(ri: int, id: String) -> void:
	var n := RunMap.node(ri, id)
	if n.type == "rest":
		GameState.heal_party()  # 전투 사이 회복 — 휴식의 핵심 가치
		GameState.level_party(RunMap.REST_LEVELS)
		GameState.run_pos = id
		if not GameState.run_cleared.has(id):
			GameState.run_cleared.append(id)
		get_tree().reload_current_scene()
	else:
		GameState.cur_node = id
		get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
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
