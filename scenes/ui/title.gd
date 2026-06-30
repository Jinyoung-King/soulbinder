extends Control
## 타이틀 화면(임시 골격) — 파이프라인 검증용. 다크 톤 + 타이틀 + 시작 버튼.
## 게임 콘텐츠(전투·수집)는 이후 단계에서.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

func _ready() -> void:
	# 배경(분위기 그라데이션 + 비네트)
	add_child(UIKit.backdrop(Color(0.09, 0.07, 0.14), Color(0.03, 0.03, 0.06)))
	# 중앙 컬럼
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 18)
	add_child(v)
	# 타이틀
	var title := _label("SOULBINDER", 76, Color(0.85, 0.78, 1.0))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color(0.35, 0.18, 0.5, 0.9))
	v.add_child(title)
	v.add_child(_label("영혼을 엮는 자", 24, Color(0.65, 0.62, 0.78)))
	v.add_child(_label("거둔 영혼 %d" % GameState.roster.size(), 18, Color(0.55, 0.52, 0.66)))
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 24); v.add_child(sp)
	# 시작 버튼 — 첫 전투로
	var play := Button.new()
	play.text = "시작"
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/prologue.tscn"))
	play.custom_minimum_size = Vector2(280, 60)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_override("font", FONT)
	play.add_theme_font_size_override("font_size", 28)
	UIKit.style_button(play, Color(0.6, 0.45, 0.95))
	v.add_child(play)
	# 영혼 편성 버튼
	var party := Button.new()
	party.text = "영혼 편성"
	party.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/party.tscn"))
	party.custom_minimum_size = Vector2(280, 50)
	party.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	party.add_theme_font_override("font", FONT)
	party.add_theme_font_size_override("font_size", 22)
	UIKit.style_button(party, Color(0.5, 0.62, 0.95))
	v.add_child(party)
	# 증언의 서 버튼
	var codex := Button.new()
	codex.text = "증언의 서"
	codex.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/codex.tscn"))
	codex.custom_minimum_size = Vector2(280, 50)
	codex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	codex.add_theme_font_override("font", FONT)
	codex.add_theme_font_size_override("font_size", 22)
	UIKit.style_button(codex, Color(0.62, 0.55, 0.78))
	v.add_child(codex)
	# 승천 난이도 선택(해금 시에만)
	if GameState.ascension_max > 0:
		var asc := HBoxContainer.new()
		asc.alignment = BoxContainer.ALIGNMENT_CENTER
		asc.add_theme_constant_override("separation", 10)
		var lbl := _label("승천  A%d" % GameState.ascension, 20, Color(0.9, 0.65, 0.45))
		lbl.custom_minimum_size = Vector2(140, 0)
		var minus := _ascbtn("−")
		var plus := _ascbtn("+")
		minus.pressed.connect(func():
			GameState.ascension = clampi(GameState.ascension - 1, 0, GameState.ascension_max)
			lbl.text = "승천  A%d" % GameState.ascension)
		plus.pressed.connect(func():
			GameState.ascension = clampi(GameState.ascension + 1, 0, GameState.ascension_max)
			lbl.text = "승천  A%d" % GameState.ascension)
		asc.add_child(minus); asc.add_child(lbl); asc.add_child(plus)
		v.add_child(asc)
	# 버전(우하단)
	var ver := _label(GameState.VERSION, 16, Color(0.5, 0.5, 0.6))
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	ver.offset_left = -120.0; ver.offset_top = -34.0; ver.offset_right = -16.0; ver.offset_bottom = -10.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)

func _ascbtn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(48, 44)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 24)
	UIKit.style_button(b, Color(0.9, 0.65, 0.45))
	return b

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
