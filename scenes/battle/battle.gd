extends Control
## 수동 턴제 전투 — 첫 수직 슬라이스의 핵심.
## 검증 가설: "다음에 누구를, 어떤 순서로" 고르는 맛(콤보·행동 순서)이 재밌나.
## 라운드 구조: 플레이어가 아군을 한 명씩 골라 행동 → 전원 행동 후 적 페이즈 → 다음 라운드.
## 콤보 의도: 독술사(취약) → 처형인(단두 치명타). 기사(도발+보호막)가 버는 동안 셋업.

const FONT := preload("res://assets/fonts/NotoSansKR.ttf")

const KNIGHT_SHIELD := 20   # 수호의 맹세 보호막량
const KNIGHT_TAUNT := 2     # 도발 지속 턴
const PLAGUE_VULN := 2      # 역병의 표식 취약 턴
const PLAGUE_DMG := 4       # 표식의 소량 피해
const HEADSMAN_DMG := 16    # 단두 기본 피해(취약 대상엔 ×2). 표식+단두 콤보로 잡몹 1사이클 처치

enum Phase { SELECT_ACTOR, SELECT_ACTION, SELECT_TARGET, RESULT }

var allies: Array[Combatant] = []
var enemies: Array[Combatant] = []
var pending: Array[Combatant] = []   # 이번 라운드 아직 행동 안 한 아군
var phase: int = Phase.SELECT_ACTOR
var actor: Combatant = null           # 선택된 행동 주체
var action: String = ""               # "atk" | "skill"
var round_no := 1
var log_lines: Array[String] = []

# UI 노드
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

	# 적 행(상단)
	enemies_box = HBoxContainer.new()
	enemies_box.add_theme_constant_override("separation", 24)
	enemies_box.alignment = BoxContainer.ALIGNMENT_CENTER
	enemies_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	enemies_box.offset_top = 40; enemies_box.offset_bottom = 220
	add_child(enemies_box)

	# 전투 로그(적/아군 행 사이 중앙 밴드)
	log_label = _mk_label("", 17, Color(0.7, 0.68, 0.8))
	log_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	log_label.offset_top = 236; log_label.offset_bottom = 348
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
	allies = [
		_ally(Jobs.KNIGHT),
		_ally(Jobs.PLAGUE),
		_ally(Jobs.HEADSMAN),
	]
	enemies = [
		Combatant.new("부패한 병사", "enemy", Color(0.55, 0.55, 0.6), 35, 7, true),
		Combatant.new("부패한 병사", "enemy", Color(0.55, 0.55, 0.6), 35, 7, true),
	]
	round_no = 1
	log_lines = ["멸망한 왕성 변두리. 부패한 병사들이 일어선다…"]
	_start_round()

func _ally(job: String) -> Combatant:
	var d := Jobs.get_def(job)
	return Combatant.new(d.name, job, d.color, d.hp, d.atk, false)

func _start_round() -> void:
	pending = []
	for a in allies:
		if a.alive():
			pending.append(a)
	phase = Phase.SELECT_ACTOR
	actor = null
	action = ""
	_refresh()

# ── 입력 흐름 ────────────────────────────────────────────────────
func _on_actor(c: Combatant) -> void:
	actor = c
	phase = Phase.SELECT_ACTION
	_refresh()

func _on_action(id: String) -> void:
	action = id
	var needs_target := true
	if id == "skill" and not Jobs.get_def(actor.job).needs_target:
		needs_target = false
	if needs_target:
		phase = Phase.SELECT_TARGET
		_refresh()
	else:
		_resolve(null)

func _on_target(enemy: Combatant) -> void:
	_resolve(enemy)

func _on_back() -> void:
	phase = Phase.SELECT_ACTOR
	actor = null
	action = ""
	_refresh()

# ── 행동 처리 ────────────────────────────────────────────────────
func _resolve(target: Combatant) -> void:
	if action == "atk":
		var dealt := target.take_damage(actor.atk)
		_log("%s ▸ %s 공격, %d 피해%s" % [actor.display_name, target.display_name, dealt, _kill(target)])
	else:
		_resolve_skill(target)
		actor.cd = Jobs.get_def(actor.job).cd
	_finish_actor()

func _resolve_skill(target: Combatant) -> void:
	match actor.job:
		Jobs.KNIGHT:
			actor.shield += KNIGHT_SHIELD
			actor.taunt = KNIGHT_TAUNT
			_log("%s ▸ 수호의 맹세! 보호막 %d + 도발" % [actor.display_name, KNIGHT_SHIELD])
		Jobs.PLAGUE:
			target.vulnerable = PLAGUE_VULN
			var dealt := target.take_damage(PLAGUE_DMG)
			_log("%s ▸ 역병의 표식! %s 취약 %d턴 (%d 피해)%s" % [actor.display_name, target.display_name, PLAGUE_VULN, dealt, _kill(target)])
		Jobs.HEADSMAN:
			var crit := target.vulnerable > 0
			var raw := HEADSMAN_DMG * 2 if crit else HEADSMAN_DMG
			var dealt := target.take_damage(raw, false)  # 치명타는 이미 반영, 취약 중복 ×1.5 방지
			var tag := " 치명타!" if crit else ""
			_log("%s ▸ 단두!%s %s에 %d 피해%s" % [actor.display_name, tag, target.display_name, dealt, _kill(target)])
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
		_enemy_phase()
	else:
		phase = Phase.SELECT_ACTOR
		_refresh()

# ── 적 페이즈 ────────────────────────────────────────────────────
func _enemy_phase() -> void:
	for e in enemies:
		if not e.alive():
			continue
		var target := _enemy_target()
		if target == null:
			break
		var dealt := target.take_damage(e.atk)
		_log("%s ▸ %s 공격, %d 피해%s" % [e.display_name, target.display_name, dealt, _kill(target)])
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
	var taunters: Array[Combatant] = []
	for a in allies:
		if a.alive() and a.taunt > 0:
			taunters.append(a)
	if not taunters.is_empty():
		return taunters[0]
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
	phase = Phase.RESULT
	_log("승리! 영혼을 거둘 수 있다." if won else "패배… 강령술사도 쓰러졌다.")
	_refresh()

# ── 렌더 ─────────────────────────────────────────────────────────
func _refresh() -> void:
	_clear(enemies_box)
	_clear(allies_box)
	_clear(action_box)

	for e in enemies:
		enemies_box.add_child(_unit_card(e, phase == Phase.SELECT_TARGET and e.alive(), _on_target))
	for a in allies:
		var sel := phase == Phase.SELECT_ACTOR and pending.has(a)
		allies_box.add_child(_unit_card(a, sel, _on_actor))

	log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 5)))

	match phase:
		Phase.SELECT_ACTOR:
			prompt_label.text = "[라운드 %d] 행동할 영혼을 선택" % round_no
		Phase.SELECT_ACTION:
			prompt_label.text = "%s — 행동 선택" % actor.display_name
			_add_action_btn("기본 공격", actor.color, func(): _on_action("atk"))
			var d := Jobs.get_def(actor.job)
			var label := "%s (%s)" % [d.skill, d.desc]
			var skill_btn := _add_action_btn(label, actor.color, func(): _on_action("skill"))
			if actor.cd > 0:
				skill_btn.disabled = true
				skill_btn.text = "%s — 재사용 %d턴" % [d.skill, actor.cd]
			_add_action_btn("◂ 뒤로", Color(0.5, 0.5, 0.58), _on_back)
		Phase.SELECT_TARGET:
			prompt_label.text = "%s의 대상을 선택(위쪽 적)" % actor.display_name
			_add_action_btn("◂ 뒤로", Color(0.5, 0.5, 0.58), _on_back)
		Phase.RESULT:
			var won := _all_dead(enemies)
			prompt_label.text = "전투 종료 — " + ("승리" if won else "패배")
			_add_action_btn("다시 전투", Color(0.6, 0.45, 0.95), func(): _start_battle())
			_add_action_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn"))

## 유닛 카드. clickable면 onclick(Combatant) 연결한 버튼으로(선택 가능 시 강조 테두리).
func _unit_card(c: Combatant, clickable: bool, onclick: Callable) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 120)
	var accent := c.color if c.alive() else Color(0.3, 0.3, 0.34)
	card.add_theme_stylebox_override("panel", UIKit.panel(accent if clickable else Color(0, 0, 0, 0), 12, c.alive()))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var dead := not c.alive()
	var name_l := _mk_label(c.display_name + ("  💀" if dead else ""), 18, Color.WHITE if not dead else Color(0.45,0.45,0.5))
	box.add_child(name_l)

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
	box.add_child(_mk_label("HP %d/%d" % [c.hp, c.max_hp], 14, Color(0.7,0.7,0.78)))

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
