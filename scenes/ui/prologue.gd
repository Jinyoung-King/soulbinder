extends Control
## 프롤로그 — 첫 전투 전 세계관 도입(멸망한 왕국). 한 줄씩 페이드인 → [계속] → 전투.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

const LINES := [
	"왕국은 하룻밤 사이에 죽었다.",
	"역병인지, 배신인지, 신의 분노인지—",
	"살아남아 증언한 자는 없었다.",
	"",
	"오직 너, 마지막 강령술사만이 그 폐허를 걷는다.",
	"쓰러진 자들의 영혼을 거두어라.",
	"그들의 마지막 기억이, 그날 밤의 진실을 증언하리니.",
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.offset_left = 120; v.offset_right = -120
	add_child(v)

	var labels: Array[Label] = []
	for line in LINES:
		var em: bool = line.begins_with("오직")
		var l := _label(line, 26 if em else 22, Color(0.85, 0.8, 0.98) if em else Color(0.62, 0.6, 0.74))
		l.modulate.a = 0.0
		v.add_child(l)
		labels.append(l)

	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 30); v.add_child(sp)
	var go := Button.new()
	go.text = "계속"
	go.custom_minimum_size = Vector2(240, 56)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.add_theme_font_override("font", FONT)
	go.add_theme_font_size_override("font_size", 24)
	UIKit.style_button(go, Color(0.6, 0.45, 0.95))
	go.modulate.a = 0.0
	go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/battle/battle.tscn"))
	v.add_child(go)

	# 한 줄씩 차례로 페이드인 → 마지막에 버튼
	var tw := create_tween()
	for l in labels:
		tw.tween_property(l, "modulate:a", 1.0, 0.5)
		tw.tween_interval(0.25)
	tw.tween_property(go, "modulate:a", 1.0, 0.5)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
