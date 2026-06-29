extends Control
## 수동 턴제 전투 — 첫 수직 슬라이스의 핵심.
## 검증 가설: "다음에 누구를, 어떤 순서로" 고르는 맛(콤보·행동 순서)이 재밌나.
## 라운드 구조: 플레이어가 아군을 한 명씩 골라 행동 → 전원 행동 후 적 페이즈 → 다음 라운드.
## 콤보 의도: 독술사(취약) → 처형인(단두 치명타). 기사(도발+보호막)가 버는 동안 셋업.
## 체감을 위해 행동/피격은 카드 번쩍 + 데미지 숫자로 연출하고, 적은 하나씩 순차로 행동한다.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

const KNIGHT_SHIELD := 20   # 수호의 맹세 보호막량
const KNIGHT_TAUNT := 2     # 도발 지속 턴
const PLAGUE_VULN := 2      # 역병의 표식 취약 턴
const PLAGUE_DMG := 4       # 표식의 소량 피해
const HEADSMAN_DMG := 16    # 단두 기본 피해(취약 대상엔 ×2). 표식+단두 콤보로 잡몹 1사이클 처치
const BERSERK_DMG := 11     # 광란: 모든 적에게 입히는 피해(취약 시 ×1.5 적용)
const BERSERK_RECOIL := 5   # 광란 자해 반동

const FX_HIT := 0.55        # 피격 연출 길이
const STEP := 0.45          # 적 행동 사이 텀(하나씩 보이게)

enum Phase { SELECT_ACTOR, SELECT_ACTION, SELECT_TARGET, ENEMY, COLLECT, RESULT }

const SELECT_ACCENT := Color(0.7, 0.55, 1.0)  # 선택 가능 카드 강조(영혼 보라)

var allies: Array[Combatant] = []
var ally_src: Array[int] = []         # allies[i] ↔ roster 인덱스(레벨업 반영용)
var enemies: Array[Combatant] = []
var pending: Array[Combatant] = []   # 이번 라운드 아직 행동 안 한 아군
var phase: int = Phase.SELECT_ACTOR
var actor: Combatant = null           # 선택된 행동 주체
var action: String = ""               # "atk" | "skill"
var round_no := 1
var log_lines: Array[String] = []
var node_type := "battle"             # 현재 노드 타입(elite 보상 판정)
var busy := false                     # 연출 재생 중 입력 무시
var show_tip := false                 # 첫 전투 콤보 안내
var card_of: Dictionary = {}          # Combatant → 카드 노드(연출 위치용)

# UI 노드
var banner: Label
var enemies_box: HBoxContainer
var allies_box: HBoxContainer
var log_label: Label
var prompt_label: Label
var action_box: HBoxContainer

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 차례 배너(최상단)
	banner = _mk_label("", 26, Color(0.85, 0.82, 0.98))
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 8; banner.offset_bottom = 40
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(banner)

	# 적 행(상단)
	enemies_box = HBoxContainer.new()
	enemies_box.add_theme_constant_override("separation", 24)
	enemies_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	enemies_box.offset_top = 54; enemies_box.offset_bottom = 224
	add_child(enemies_box)

	# 전투 로그(적/아군 행 사이 중앙 밴드)
	log_label = _mk_label("", 17, Color(0.7, 0.68, 0.8))
	log_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	log_label.offset_top = 240; log_label.offset_bottom = 348
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(log_label)

	# 아군 행(하단부)
	allies_box = HBoxContainer.new()
	allies_box.add_theme_constant_override("separation", 24)
	allies_box.alignment = BoxContainer.ALIGNMENT_CENTER
	allies_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	allies_box.offset_top = 360; allies_box.offset_bottom = 540
	add_child(allies_box)

	# 프롬프트 + 행동 버튼(하단)
	prompt_label = _mk_label("", 20, Color(0.85, 0.82, 0.95))
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_label.offset_top = -150; prompt_label.offset_bottom = -110
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt_label)

	action_box = HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 14)
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	action_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	action_box.offset_top = -90; action_box.offset_bottom = -24
	add_child(action_box)

	_start_battle()

# ── 전투 시작/라운드 ─────────────────────────────────────────────
func _start_battle() -> void:
	# 파티 = 편성된 출전 팀(레벨 반영). 비어 있으면 앞 3인으로 폴백.
	allies = []
	ally_src = []
	var team := GameState.party.duplicate()
	if team.is_empty():
		for i in mini(GameState.PARTY_MAX, GameState.roster.size()):
			team.append(i)
	for idx in team:
		if idx >= 0 and idx < GameState.roster.size():
			allies.append(_ally(GameState.roster[idx]))
			ally_src.append(idx)
	# 적 = 현재 진입 노드의 인카운터(거둘 수 있는 영혼: 직업·사연 보유)
	if GameState.cur_node == "":
		GameState.cur_node = RunMap.ENTRY
	var node := RunMap.node(GameState.cur_node)
	node_type = node.type
	enemies = []
	for e in node.enemies:
		enemies.append(_enemy_soul(e.name, e.job, e.lore, e.hp, e.atk))
	round_no = 1
	busy = false
	show_tip = GameState.story_fragments.is_empty()  # 아직 한 번도 안 거뒀으면 첫 전투
	log_lines = ["[%s] %s" % [node.name, node.intro]]
	if show_tip:
		log_lines.append("팁: 독술사 ‘역병의 표식’으로 취약을 걸고 → 처형인 ‘단두’로 마무리. 기사로 버티며 콤보를 맞춰요.")
	_start_round()

## 로스터 항목 → 전투 유닛(레벨 스케일링: 레벨당 HP+5/공격+1).
func _ally(entry: Dictionary) -> Combatant:
	var d := Jobs.get_def(entry.job)
	var lvl := int(entry.level)
	return Combatant.new(entry.name, entry.job, d.color, d.hp + (lvl - 1) * 5, d.atk + (lvl - 1), false)

func _enemy_soul(p_name: String, job: String, lore: String, hp: int, atk: int) -> Combatant:
	var c := Combatant.new(p_name, job, Color(0.55, 0.55, 0.6), hp, atk, true)
	c.lore = lore
	return c

func _start_round() -> void:
	pending = []
	for a in allies:
		if a.alive():
			pending.append(a)
	phase = Phase.SELECT_ACTOR
	actor = null
	action = ""
	_refresh()

# ── 입력 흐름(연출 중엔 busy로 잠금) ─────────────────────────────
func _on_actor(c: Combatant) -> void:
	if busy:
		return
	actor = c
	phase = Phase.SELECT_ACTION
	_refresh()

func _on_action(id: String) -> void:
	if busy:
		return
	action = id
	var needs_target := true
	if id == "skill" and not Jobs.get_def(actor.job).needs_target:
		needs_target = false
	if needs_target:
		phase = Phase.SELECT_TARGET
		_refresh()
	else:
		busy = true
		await _resolve(null)
		busy = false

func _on_target(enemy: Combatant) -> void:
	if busy:
		return
	busy = true
	await _resolve(enemy)
	busy = false

func _on_back() -> void:
	if busy:
		return
	phase = Phase.SELECT_ACTOR
	actor = null
	action = ""
	_refresh()

# ── 행동 처리(연출 포함) ─────────────────────────────────────────
func _resolve(target: Combatant) -> void:
	if action == "atk":
		var dealt := target.take_damage(actor.atk)
		_log("%s ▸ %s 공격, %d 피해%s" % [actor.display_name, target.display_name, dealt, _kill(target)])
		await _hit(target, "-%d" % dealt, Color(1, 0.5, 0.45), false)
	else:
		await _resolve_skill(target)
		actor.cd = Jobs.get_def(actor.job).cd
	_refresh()
	await _finish_actor()

func _resolve_skill(target: Combatant) -> void:
	match actor.job:
		Jobs.KNIGHT:
			actor.shield += KNIGHT_SHIELD
			actor.taunt = KNIGHT_TAUNT
			_log("%s ▸ 수호의 맹세! 보호막 %d + 도발" % [actor.display_name, KNIGHT_SHIELD])
			await _hit(actor, "🛡 방어", Color(0.55, 0.75, 1.0), false)
		Jobs.PLAGUE:
			target.vulnerable = PLAGUE_VULN
			var dealt := target.take_damage(PLAGUE_DMG)
			_log("%s ▸ 역병의 표식! %s 취약 %d턴 (%d 피해)%s" % [actor.display_name, target.display_name, PLAGUE_VULN, dealt, _kill(target)])
			await _hit(target, "취약! -%d" % dealt, Color(0.6, 0.95, 0.5), false)
		Jobs.HEADSMAN:
			var crit := target.vulnerable > 0
			var raw := HEADSMAN_DMG * 2 if crit else HEADSMAN_DMG
			var dealt := target.take_damage(raw, false)  # 치명타는 이미 반영, 취약 중복 ×1.5 방지
			var tag := " 치명타!" if crit else ""
			_log("%s ▸ 단두!%s %s에 %d 피해%s" % [actor.display_name, tag, target.display_name, dealt, _kill(target)])
			await _hit(target, ("-%d 치명!" % dealt) if crit else "-%d" % dealt, Color(1, 0.85, 0.3) if crit else Color(1, 0.5, 0.45), crit)
		Jobs.BERSERKER:
			var hits: Array[String] = []
			for e in enemies:
				if e.alive():
					var dd := e.take_damage(BERSERK_DMG)
					hits.append("%s %d%s" % [e.display_name, dd, _kill(e)])
					await _hit(e, "-%d" % dd, Color(1, 0.55, 0.25), false)
			actor.take_damage(BERSERK_RECOIL, false)  # 자해 반동(취약 무관)
			_log("%s ▸ 광란! 적 전체 — %s | 반동 %d" % [actor.display_name, ", ".join(hits), BERSERK_RECOIL])
			await _hit(actor, "반동 -%d" % BERSERK_RECOIL, Color(0.9, 0.5, 0.5), false)
		_:
			pass

func _kill(c: Combatant) -> String:
	return "  💀쓰러짐" if not c.alive() else ""

func _finish_actor() -> void:
	pending.erase(actor)
	actor = null
	action = ""
	if _all_dead(enemies):
		_end_battle(true)
		return
	if pending.is_empty():
		phase = Phase.ENEMY
		_refresh()
		await _enemy_phase()
	else:
		phase = Phase.SELECT_ACTOR
		_refresh()

# ── 적 페이즈(하나씩 순차로) ─────────────────────────────────────
func _enemy_phase() -> void:
	await get_tree().create_timer(STEP).timeout
	for e in enemies:
		if not e.alive():
			continue
		var target := _enemy_target()
		if target == null:
			break
		var dealt := target.take_damage(e.atk)
		_log("%s ▸ %s 공격, %d 피해%s" % [e.display_name, target.display_name, dealt, _kill(target)])
		await _hit(target, "-%d" % dealt, Color(1, 0.45, 0.4), false)
		_refresh()
		await get_tree().create_timer(STEP).timeout
	if _all_dead(allies):
		_end_battle(false)
		return
	# 라운드 종료: 상태 감소
	for c in allies + enemies:
		c.tick()
	round_no += 1
	_start_round()

## 도발 중인 아군을 우선, 없으면 살아있는 첫 아군.
func _enemy_target() -> Combatant:
	for a in allies:
		if a.alive() and a.taunt > 0:
			return a
	for a in allies:
		if a.alive():
			return a
	return null

func _all_dead(arr: Array[Combatant]) -> bool:
	for c in arr:
		if c.alive():
			return false
	return true

func _end_battle(won: bool) -> void:
	if won:
		_apply_levelups()
		# 노드 클리어 → 위치 갱신
		GameState.run_pos = GameState.cur_node
		if not GameState.run_cleared.has(GameState.cur_node):
			GameState.run_cleared.append(GameState.cur_node)
		if node_type == "elite":
			GameState.level_party(RunMap.ELITE_BONUS)  # 정예 보상: 팀 추가 레벨
			_log("정예 격파 보상 ▸ 출전 팀 전원 +%d 레벨" % RunMap.ELITE_BONUS)
		phase = Phase.COLLECT
		_log("승리! 쓰러진 영혼 중 하나를 거둘 수 있다.")
	else:
		phase = Phase.RESULT
		_log("패배… 강령술사도 쓰러졌다.")
	_refresh()

## 생존한 참전 영혼(로스터 앞 3인) 레벨업 — 영구 보존.
func _apply_levelups() -> void:
	var ups: Array[String] = []
	for i in allies.size():
		if allies[i].alive() and i < ally_src.size():
			var ri := ally_src[i]
			GameState.roster[ri].level += 1
			ups.append("%s Lv%d" % [GameState.roster[ri].name, GameState.roster[ri].level])
	if not ups.is_empty():
		_log("레벨업 ▸ " + ", ".join(ups))

## 거두기 — 쓰러진 영혼 하나를 로스터에 추가 + 사연 해금.
func _on_collect(e: Combatant) -> void:
	if busy:
		return
	GameState.bind_soul({"job": e.job, "name": e.display_name, "lore": e.lore, "level": 1})
	_log("%s의 영혼을 거뒀다. (보유 %d)" % [e.display_name, GameState.roster.size()])
	_log("“%s”" % e.lore)
	phase = Phase.RESULT
	_refresh()

# ── 피격 연출: 카드 번쩍 + 데미지 숫자 떠오름 ────────────────────
func _hit(c: Combatant, text: String, color: Color, big: bool) -> void:
	var card: Control = card_of.get(c)
	if card == null:
		return
	await get_tree().process_frame  # 카드 레이아웃 확정 후 위치 읽기
	var center := card.global_position + card.size * 0.5
	# 카드 번쩍(밝게 → 원복)
	card.modulate = Color(1.5, 1.4, 1.4)
	# 떠오르는 숫자
	var lbl := _mk_label(text, 34 if big else 26, color)
	lbl.z_index = 100
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_child(lbl)
	lbl.position = center - Vector2(40, 10)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 48, FX_HIT)
	tw.tween_property(lbl, "modulate:a", 0.0, FX_HIT).set_delay(FX_HIT * 0.4)
	tw.tween_property(card, "modulate", Color.WHITE, FX_HIT * 0.5)
	await tw.finished
	lbl.queue_free()

# ── 렌더 ─────────────────────────────────────────────────────────
func _refresh() -> void:
	_clear(enemies_box)
	_clear(allies_box)
	_clear(action_box)
	card_of.clear()

	for e in enemies:
		var e_click := false
		var e_cb := _on_target
		if phase == Phase.SELECT_TARGET and e.alive():
			e_click = true
		elif phase == Phase.COLLECT and not e.alive():
			e_click = true
			e_cb = _on_collect
		enemies_box.add_child(_unit_card(e, e_click, e_cb))
	for a in allies:
		var sel := phase == Phase.SELECT_ACTOR and pending.has(a)
		allies_box.add_child(_unit_card(a, sel, _on_actor))

	log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 5)))
	_set_banner()

	match phase:
		Phase.SELECT_ACTOR:
			prompt_label.text = "행동할 영혼을 선택"
		Phase.SELECT_ACTION:
			prompt_label.text = "%s — 행동 선택" % actor.display_name
			_add_action_btn("기본 공격", actor.color, func(): _on_action("atk"))
			var d := Jobs.get_def(actor.job)
			var skill_btn := _add_action_btn("%s (%s)" % [d.skill, d.desc], actor.color, func(): _on_action("skill"))
			if actor.cd > 0:
				skill_btn.disabled = true
				skill_btn.text = "%s — 재사용 %d턴" % [d.skill, actor.cd]
			_add_action_btn("◂ 뒤로", Color(0.5, 0.5, 0.58), _on_back)
		Phase.SELECT_TARGET:
			prompt_label.text = "%s의 대상을 선택(위쪽 적)" % actor.display_name
			_add_action_btn("◂ 뒤로", Color(0.5, 0.5, 0.58), _on_back)
		Phase.ENEMY:
			prompt_label.text = ""
		Phase.COLLECT:
			prompt_label.text = "거둘 영혼을 선택 (위쪽 쓰러진 적)"
		Phase.RESULT:
			var won := _all_dead(enemies)
			prompt_label.text = "전투 종료 — " + ("승리" if won else "패배")
			if won:
				_add_action_btn("지도로", Color(0.6, 0.45, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/map.tscn"))
				_add_action_btn("팀 편성", Color(0.5, 0.62, 0.95), func(): get_tree().change_scene_to_file("res://scenes/ui/party.tscn"))
			else:
				_add_action_btn("다시 전투", Color(0.6, 0.45, 0.95), func(): _start_battle())
			_add_action_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn"))

func _set_banner() -> void:
	match phase:
		Phase.ENEMY:
			banner.text = "✦ 적의 차례 ✦"
			banner.add_theme_color_override("font_color", Color(1, 0.55, 0.5))
		Phase.COLLECT, Phase.RESULT:
			banner.text = "전투 종료"
			banner.add_theme_color_override("font_color", Color(0.8, 0.78, 0.9))
		_:
			banner.text = "라운드 %d · 당신의 차례" % round_no
			banner.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))

## 유닛 카드. clickable면 onclick(Combatant) 연결한 버튼으로(선택 가능 시 강조 테두리).
func _unit_card(c: Combatant, clickable: bool, onclick: Callable) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 120)
	var accent := c.color if c.alive() else Color(0.3, 0.3, 0.34)
	card.add_theme_stylebox_override("panel", UIKit.panel(SELECT_ACCENT if clickable else Color(0, 0, 0, 0), 12, c.alive()))
	card_of[c] = card

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var dead := not c.alive()
	box.add_child(_mk_label(c.display_name + ("  💀" if dead else ""), 18, Color.WHITE if not dead else Color(0.45, 0.45, 0.5)))

	var bar := ProgressBar.new()
	bar.max_value = c.max_hp
	bar.value = c.hp
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = accent
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	box.add_child(_mk_label("HP %d/%d" % [c.hp, c.max_hp], 14, Color(0.7, 0.7, 0.78)))

	var st := c.status_text()
	box.add_child(_mk_label(st if st != "" else " ", 14, Color(0.95, 0.85, 0.5)))

	if clickable:
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(func(): onclick.call(c))
		card.add_child(btn)
	return card

func _add_action_btn(text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 18)
	UIKit.style_button(b, accent)
	b.pressed.connect(cb)
	action_box.add_child(b)
	return b

func _log(line: String) -> void:
	log_lines.append(line)

func _mk_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _clear(node: Node) -> void:
	for ch in node.get_children():
		ch.queue_free()
		node.remove_child(ch)
