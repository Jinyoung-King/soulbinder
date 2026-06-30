extends Control
## 사건(이벤트) 노드 — 비전투 선택. 위험·보상으로 런 단위 '경우의 수'를 더한다.
## 무작위 사건 1개 제시 → 두 선택지 중 하나 → 결과 적용 후 지도로(노드 클리어).

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

# 사건 정의: title/flavor + 두 선택지(label/desc/effect 콜백 키)
var events := []
var box: VBoxContainer

func _ready() -> void:
	events = [
		{
			"title": "버려진 제단",
			"flavor": "검은 제단이 영혼의 일부를 요구한다. 대가를 치르면 힘을 약속한다.",
			"a": {"label": "피의 대가를 치른다", "desc": "출전 팀 HP 25% 소모 → 유물 획득", "fx": "altar"},
			"b": {"label": "그냥 지나간다", "desc": "아무 일도 없다", "fx": "none"},
		},
		{
			"title": "유랑하는 영혼",
			"flavor": "떠도는 영혼이 너의 곁에 서고 싶어 한다.",
			"a": {"label": "거두어 함께한다", "desc": "무작위 영혼 1체 영입(로스터 추가)", "fx": "recruit"},
			"b": {"label": "힘만 빌린다", "desc": "출전 팀 전원 +1 레벨", "fx": "level"},
		},
		{
			"title": "마른 우물",
			"flavor": "우물 바닥에서 무언가 빛이 일렁인다. 손을 넣어볼까.",
			"a": {"label": "손을 넣는다 (도박)", "desc": "절반은 유물, 절반은 저주(HP 30%)", "fx": "gamble"},
			"b": {"label": "물러나 숨을 고른다", "desc": "출전 팀 완전 회복", "fx": "rest"},
		},
		{
			"title": "고대 무기고",
			"flavor": "먼지 쌓인 무기고. 힘이 잠들어 있으나 대가 없이는 깨어나지 않는다.",
			"a": {"label": "무장을 갖춘다", "desc": "유물 획득 (대가: 팀 HP 20%)", "fx": "armory"},
			"b": {"label": "힘을 끌어낸다", "desc": "출전 팀 전원 +1 레벨", "fx": "level"},
		},
		{
			"title": "쌍둥이 영혼",
			"flavor": "두 영혼이 함께 떠돈다. 둘 다 거두기엔 너의 부름이 약하다.",
			"a": {"label": "둘 다 거둔다", "desc": "무작위 영혼 2체 영입", "fx": "twin"},
			"b": {"label": "하나만, 그리고 쉰다", "desc": "1체 영입 + 출전 팀 회복", "fx": "recruit_rest"},
		},
	]

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.045, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	box = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.offset_left = 120; box.offset_right = -120
	add_child(box)

	_show_event(events[randi() % events.size()])

func _show_event(ev: Dictionary) -> void:
	_clear(box)
	box.add_child(_label("— 사건 · %s —" % ev.title, 30, Color(0.85, 0.82, 0.98)))
	var fl := _label(ev.flavor, 19, Color(0.7, 0.68, 0.82))
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(fl)
	box.add_child(_sp(20))
	box.add_child(_choice(ev.a, Color(0.62, 0.55, 0.85)))
	box.add_child(_choice(ev.b, Color(0.5, 0.55, 0.62)))

func _choice(c: Dictionary, accent: Color) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [c.label, c.desc]
	b.custom_minimum_size = Vector2(620, 70)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 19)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_button(b, accent)
	b.pressed.connect(func(): _apply(c.fx))
	return b

func _apply(fx: String) -> void:
	var result := ""
	match fx:
		"altar":
			GameState.damage_party(0.25)
			var rid := GameState.grant_random_relic()
			result = "피를 바쳤다. 유물 [%s] 획득." % Relics.get_def(rid).name if rid != "" else "피를 바쳤으나… 더 받을 유물이 없다."
		"recruit":
			var nm := GameState.bind_random_soul()
			result = "%s 이(가) 합류했다. (편성에서 출전 가능)" % nm
		"level":
			GameState.level_party(1)
			result = "영혼의 힘을 빌렸다. 출전 팀 +1 레벨."
		"gamble":
			if randi() % 2 == 0:
				var rid2 := GameState.grant_random_relic()
				result = "빛이 손에 감긴다 — 유물 [%s] 획득!" % Relics.get_def(rid2).name if rid2 != "" else "빛이 손에 감겼으나 남은 유물이 없다."
			else:
				GameState.damage_party(0.30)
				result = "검은 손이 너를 움켜쥔다 — 출전 팀 HP 30% 소실!"
		"rest":
			GameState.heal_party()
			result = "숨을 고른다. 출전 팀 완전 회복."
		"armory":
			GameState.damage_party(0.20)
			var rid3 := GameState.grant_random_relic()
			result = "무장을 갖췄다. 유물 [%s] 획득." % Relics.get_def(rid3).name if rid3 != "" else "무장을 갖췄으나 더 받을 유물이 없다."
		"twin":
			var n1 := GameState.bind_random_soul()
			var n2 := GameState.bind_random_soul()
			result = "%s, %s 이(가) 합류했다." % [n1, n2]
		"recruit_rest":
			var n3 := GameState.bind_random_soul()
			GameState.heal_party()
			result = "%s 이(가) 합류하고, 팀이 회복했다." % n3
		_:
			result = "조용히 지나친다."
	_show_result(result)

func _show_result(text: String) -> void:
	_clear(box)
	var r := _label(text, 22, Color(0.85, 0.82, 0.95))
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(r)
	box.add_child(_sp(16))
	var go := Button.new()
	go.text = "지도로 ▸"
	go.custom_minimum_size = Vector2(220, 54)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_override("font", FONT)
	go.add_theme_font_size_override("font_size", 20)
	UIKit.style_button(go, Color(0.6, 0.45, 0.95))
	go.pressed.connect(func():
		# 노드 클리어 처리 후 지도로
		GameState.run_pos = GameState.cur_node
		if not GameState.run_cleared.has(GameState.cur_node):
			GameState.run_cleared.append(GameState.cur_node)
		get_tree().change_scene_to_file("res://scenes/ui/map.tscn"))
	box.add_child(go)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _sp(h: int) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c

func _clear(node: Node) -> void:
	for ch in node.get_children():
		ch.queue_free(); node.remove_child(ch)
