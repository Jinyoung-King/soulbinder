extends Control
## 영혼 편성 화면 — 거둔 영혼(로스터) 중 최대 3인을 출전 팀으로.
## '경우의수(팀조합)' 기둥을 처음으로 직접 체감시키는 화면. 클릭으로 토글.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

var slots_box: HBoxContainer
var grid: GridContainer
var hint: Label
var start_btn: Button

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.offset_left = 40; root.offset_right = -40; root.offset_top = 24; root.offset_bottom = -24
	add_child(root)

	var title := _label("영혼 편성  ·  출전 팀 (최대 %d)" % GameState.PARTY_MAX, 28, Color(0.85, 0.82, 0.98))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	# 출전 슬롯 행
	slots_box = HBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 16)
	slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(slots_box)

	root.add_child(_sep(8))
	var label2 := _label("보유 영혼 (클릭해서 출전 토글)", 18, Color(0.6, 0.58, 0.72))
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label2)

	# 보유 영혼 그리드(스크롤)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var center := CenterContainer.new()  # 그리드를 가로 가운데 정렬(늘어나 잘리지 않게)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	center.add_child(grid)

	hint = _label("", 16, Color(0.9, 0.7, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

	# 하단 버튼
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(btns)
	start_btn = _btn("편성 완료 ▸ 지도", Color(0.6, 0.45, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/map.tscn"))
	btns.add_child(start_btn)
	btns.add_child(_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn")))

	_refresh()

func _refresh() -> void:
	_clear(slots_box)
	_clear(grid)

	# 출전 슬롯 3칸
	for s in GameState.PARTY_MAX:
		if s < GameState.party.size():
			slots_box.add_child(_slot_card(s, GameState.party[s]))
		else:
			slots_box.add_child(_empty_slot())

	# 보유 영혼 카드
	for idx in GameState.roster.size():
		grid.add_child(_roster_card(idx))

	var n := GameState.party.size()
	hint.text = "" if n > 0 else "출전 영혼을 최소 1명 선택하세요."
	start_btn.disabled = n == 0

func _toggle(idx: int) -> void:
	if GameState.party.has(idx):
		GameState.party.erase(idx)
	elif GameState.party.size() < GameState.PARTY_MAX:
		GameState.party.append(idx)
	else:
		hint.text = "출전은 최대 %d명까지. 먼저 한 명을 빼세요." % GameState.PARTY_MAX
		return
	_refresh()

# ── 카드들 ───────────────────────────────────────────────────────
func _roster_card(idx: int) -> Control:
	var e: Dictionary = GameState.roster[idx]
	var d := Jobs.get_def(e.job)
	var picked := GameState.party.has(idx)
	var order := GameState.party.find(idx)
	const W := 268  # 카드 폭 고정(4열 화면 안에 들어오게)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(W, 158)
	card.add_theme_stylebox_override("panel", UIKit.panel(Color(0.7, 0.55, 1.0) if picked else Color(0, 0, 0, 0), 12, picked))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.custom_minimum_size = Vector2(W - 24, 0)
	card.add_child(box)

	box.add_child(_wrap("%s%s" % [e.name, ("   ◆ 출전 %d" % (order + 1)) if picked else ""], 19, Color.WHITE if picked else Color(0.82, 0.82, 0.88), W))
	box.add_child(_wrap("%s · Lv %d · HP %d / 공격 %d" % [d.name, e.level, d.hp + (int(e.level) - 1) * 5, d.atk + int(e.level) - 1], 14, d.color.lightened(0.1), W))
	box.add_child(_wrap(d.skill + " — " + d.desc, 13, Color(0.62, 0.6, 0.72), W))
	var lore := _wrap(e.lore, 12, Color(0.5, 0.48, 0.6), W)
	lore.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(lore)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func(): _toggle(idx))
	card.add_child(btn)
	return card

func _slot_card(slot: int, idx: int) -> Control:
	var e: Dictionary = GameState.roster[idx]
	var d := Jobs.get_def(e.job)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 70)
	card.add_theme_stylebox_override("panel", UIKit.panel(d.color, 12, true))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	box.add_child(_label("출전 %d" % (slot + 1), 13, Color(0.7, 0.68, 0.82)))
	box.add_child(_label("%s  ·  %s Lv%d" % [e.name, d.name, e.level], 17, Color.WHITE))
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func(): _toggle(idx))  # 슬롯 클릭 = 빼기
	card.add_child(btn)
	return card

func _empty_slot() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(210, 70)
	card.add_theme_stylebox_override("panel", UIKit.panel(Color(0, 0, 0, 0), 12, false))
	var l := _label("— 비어 있음 —", 16, Color(0.45, 0.43, 0.52))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(l)
	return card

# ── 헬퍼 ─────────────────────────────────────────────────────────
func _btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 54)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 20)
	UIKit.style_button(b, accent)
	b.pressed.connect(cb)
	return b

## 카드용: 폭 고정 + 자동 줄바꿈(긴 텍스트가 카드를 넓히지 않게).
func _wrap(text: String, size: int, color: Color, width: int) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width - 24, 0)
	return l

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

func _clear(node: Node) -> void:
	for ch in node.get_children():
		ch.queue_free()
		node.remove_child(ch)
