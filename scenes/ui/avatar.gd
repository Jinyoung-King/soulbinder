class_name Avatar
extends Control
## 영혼/적의 단색 도형 아바타 — 직업을 실루엣으로 즉시 읽히게(placeholder 아트).
## 기사=사각(방패) · 독술사=마름모 · 처형인=역삼각(칼날) · 광전사=삼각(돌격) · 치유사=원+십자.

var job: String = ""
var col: Color = Color.WHITE

func setup(p_job: String, p_col: Color, sz := 40) -> Avatar:
	job = p_job
	col = p_col
	custom_minimum_size = Vector2(sz, sz)
	queue_redraw()
	return self

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.42
	var line := col.darkened(0.45)
	match job:
		Jobs.KNIGHT:  # 사각(방패)
			var rect := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
			draw_rect(rect, col)
			draw_rect(rect, line, false, 2.0)
		Jobs.PLAGUE:  # 마름모
			_poly([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)], line)
		Jobs.HEADSMAN:  # 역삼각(칼날)
			_poly([c + Vector2(-r, -r * 0.85), c + Vector2(r, -r * 0.85), c + Vector2(0, r)], line)
		Jobs.BERSERKER:  # 삼각(돌격)
			_poly([c + Vector2(-r, r * 0.85), c + Vector2(r, r * 0.85), c + Vector2(0, -r)], line)
		Jobs.MENDER:  # 원 + 십자
			draw_circle(c, r, col)
			var t := r * 0.5
			var w := maxf(2.0, r * 0.22)
			draw_rect(Rect2(c - Vector2(t, w * 0.5), Vector2(t * 2, w)), line)
			draw_rect(Rect2(c - Vector2(w * 0.5, t), Vector2(w, t * 2)), line)
		_:  # 기본=원
			draw_circle(c, r, col)
			draw_arc(c, r, 0, TAU, 24, line, 2.0)

func _poly(pts: Array, line: Color) -> void:
	var pv := PackedVector2Array(pts)
	draw_colored_polygon(pv, col)
	var loop := pv.duplicate()
	loop.append(pv[0])
	draw_polyline(loop, line, 2.0)
