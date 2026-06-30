class_name UIKit
extends RefCounted
## 공용 UI 스타일 키트 — 몹 도감의 '둥근 다크 카드' 룩을 전 화면에 통일.
## 정적 헬퍼만 제공(StyleBoxFlat 생성·버튼 스타일 적용). 색·라운드·여백을 한 곳에서 관리.

const PANEL_BG := Color(0.12, 0.115, 0.16, 0.92)      # 카드 기본 배경(짙은 남보라)
const PANEL_BG_SOFT := Color(0.16, 0.15, 0.21, 0.92)  # 살짝 밝은 카드
const BORDER := Color(0.34, 0.34, 0.46, 0.55)         # 은은한 테두리

## 분위기 배경 — 세로 그라데이션 + 가장자리 비네트. 평평한 단색 대신 '디자인된' 느낌.
## 반환 Control을 화면 맨 뒤에 add_child 하면 됨(full-rect, 입력 무시).
static func backdrop(top := Color(0.07, 0.06, 0.11), bottom := Color(0.04, 0.035, 0.07)) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 세로 그라데이션
	var g := Gradient.new()
	g.set_color(0, top); g.set_color(1, bottom)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(0, 1)
	gt.width = 8; gt.height = 256
	var grad := TextureRect.new()
	grad.texture = gt
	grad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(grad)
	# 비네트(가장자리 어둡게) — 방사형 그라데이션
	var vg := Gradient.new()
	vg.set_color(0, Color(0, 0, 0, 0)); vg.set_color(1, Color(0, 0, 0, 0.55))
	var vt := GradientTexture2D.new()
	vt.gradient = vg
	vt.fill = GradientTexture2D.FILL_RADIAL
	vt.fill_from = Vector2(0.5, 0.5); vt.fill_to = Vector2(1.05, 1.05)
	vt.width = 256; vt.height = 256
	var vig := TextureRect.new()
	vig.texture = vt
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vig)
	return root

## 카드/패널 스타일박스. accent.a>0이면 그 색 테두리, 아니면 기본 은은한 테두리.
static func panel(accent := Color(0, 0, 0, 0), radius := 12, soft := false, margin := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG_SOFT if soft else PANEL_BG
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	if accent.a > 0.0:
		sb.set_border_width_all(2)
		sb.border_color = accent
	else:
		sb.set_border_width_all(1)
		sb.border_color = BORDER
	return sb

## 버튼 스타일박스(속성/강조색 기반). hl=호버·눌림 변형(더 밝게).
static func button_box(accent: Color, hl := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.34 if hl else 0.18)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = accent.lightened(0.15) if hl else Color(accent.r, accent.g, accent.b, 0.85)
	sb.set_content_margin_all(10)
	return sb

## 버튼에 normal/hover/pressed/disabled 스타일 + 글자색 일괄 적용.
static func style_button(btn: Button, accent: Color) -> void:
	btn.add_theme_stylebox_override("normal", button_box(accent, false))
	btn.add_theme_stylebox_override("hover", button_box(accent, true))
	btn.add_theme_stylebox_override("pressed", button_box(accent, true))
	btn.add_theme_stylebox_override("focus", button_box(accent, false))
	var dis := StyleBoxFlat.new()  # 비활성: 회색 디밍(살 수 없음 등)
	dis.bg_color = Color(0.18, 0.18, 0.22, 0.55)
	dis.set_corner_radius_all(10)
	dis.set_border_width_all(2)
	dis.border_color = Color(0.32, 0.32, 0.38, 0.55)
	dis.set_content_margin_all(10)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.62))
