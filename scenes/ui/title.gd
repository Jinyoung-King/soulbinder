extends Control
## 타이틀 화면(임시 골격) — 파이프라인 검증용. 다크 톤 + 타이틀 + 시작 버튼.
## 게임 콘텐츠(전투·수집)는 이후 단계에서.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

func _ready() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
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
	# 버전(우하단)
	var ver := _label(GameState.VERSION, 16, Color(0.5, 0.5, 0.6))
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	ver.offset_left = -120.0; ver.offset_top = -34.0; ver.offset_right = -16.0; ver.offset_bottom = -10.0
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
