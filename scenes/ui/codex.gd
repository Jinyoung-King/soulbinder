extends Control
## 증언의 서 — 거둔 영혼들의 '그날 밤 증언'(lore)을 모아 읽는 화면.
## 핵심 테마(수집=서사)를 가시화. 모을수록 truth_hint로 진실 윤곽이 드러난다.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.045, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 12)
	v.offset_left = 80; v.offset_right = -80; v.offset_top = 26; v.offset_bottom = -24
	add_child(v)

	var title := _label("증언의 서  ·  그날 밤", 28, Color(0.85, 0.82, 0.98))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := _label("모은 증언 %d" % GameState.story_fragments.size(), 16, Color(0.6, 0.58, 0.72))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	# 진실 윤곽(모을수록 또렷)
	var truth := _label(GameState.truth_hint(), 18, Color(0.82, 0.74, 0.6))
	truth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	truth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(truth)

	v.add_child(_sep(6))

	# 증언 목록(스크롤)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	if GameState.story_fragments.is_empty():
		var empty := _label("아직 거둔 증언이 없다. 전투에서 쓰러진 영혼을 거두어라.", 16, Color(0.5, 0.48, 0.6))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty)
	else:
		var i := 0
		for frag in GameState.story_fragments:
			i += 1
			list.add_child(_entry(i, frag))

	# 하단 버튼
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 14)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(btns)
	btns.add_child(_btn("지도로", Color(0.6, 0.45, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/map.tscn")))
	btns.add_child(_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn")))

func _entry(idx: int, frag: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.panel(Color(0.5, 0.45, 0.7, 0.5), 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	box.add_child(_label("%d. %s" % [idx, frag.get("name", "이름 없는 영혼")], 18, Color(0.88, 0.84, 0.98)))
	var lore := _label("“%s”" % frag.get("lore", ""), 15, Color(0.68, 0.66, 0.78))
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lore)
	return card

func _btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 50)
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
