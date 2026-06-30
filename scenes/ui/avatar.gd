class_name Avatar
extends Control
## 영혼/적의 캐릭터 실루엣(placeholder) — 머리+몸통 휴머노이드 + 직업 엠블럼.
## 단색 도형보다 '캐릭터'다움. 색은 직업색, 가슴 엠블럼으로 직업 구분.
## 기사=사각 · 독술사=마름모 · 처형인=역삼각 · 광전사=삼각 · 치유사=십자 · 시간술사=육각.

var job: String = ""
var col: Color = Color.WHITE

func setup(p_job: String, p_col: Color, sz := 44) -> Avatar:
	job = p_job
	col = p_col
	custom_minimum_size = Vector2(sz, sz)
	queue_redraw()
	return self

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var line := col.darkened(0.5)
	var top := h * 0.42

	# 몸통(망토 실루엣)
	var body := PackedVector2Array([
		Vector2(cx - w * 0.33, h * 0.97), Vector2(cx - w * 0.20, top),
		Vector2(cx + w * 0.20, top), Vector2(cx + w * 0.33, h * 0.97)])
	draw_colored_polygon(body, col)
	var bl := body.duplicate(); bl.append(body[0])
	draw_polyline(bl, line, 2.0)

	# 머리
	var hr := w * 0.17
	var hc := Vector2(cx, top - hr * 0.35)
	draw_circle(hc, hr, col.lightened(0.16))
	draw_arc(hc, hr, 0, TAU, 22, line, 2.0)

	# 가슴 엠블럼(직업) — 밝은 대비색
	_emblem(Vector2(cx, h * 0.64), w * 0.15, col.lightened(0.45))

func _emblem(c: Vector2, r: float, ec: Color) -> void:
	match job:
		Jobs.KNIGHT:
			draw_rect(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), ec)
		Jobs.PLAGUE:
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), ec)
		Jobs.HEADSMAN:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.8), c + Vector2(r, -r * 0.8), c + Vector2(0, r)]), ec)
		Jobs.BERSERKER:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r * 0.8), c + Vector2(r, r * 0.8), c + Vector2(0, -r)]), ec)
		Jobs.MENDER:
			var t := r
			var wd := maxf(2.0, r * 0.5)
			draw_rect(Rect2(c - Vector2(t, wd * 0.5), Vector2(t * 2, wd)), ec)
			draw_rect(Rect2(c - Vector2(wd * 0.5, t), Vector2(wd, t * 2)), ec)
		Jobs.CHRONO:
			var hex := PackedVector2Array()
			for i in 6:
				var a := PI / 6.0 + float(i) * PI / 3.0
				hex.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(hex, ec)
		_:
			draw_circle(c, r, ec)
