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
const HEAL_AMT := 18        # 치유의 빛 회복량(아군)
const ENEMY_HEAL := 14      # 적 치유사 회복량

const FX_HIT := 0.55        # 피격 연출 길이
const STEP := 0.45          # 적 행동 사이 텀(하나씩 보이게)
const ENEMY_SKILL_CD := 2   # 적 고유기 재사용 쿨다운
const ENRAGE_ATK := 8       # 보스 격노 시 공격 증가(HP 절반 이하)

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
var fast := false                     # true면 연출 딜레이 생략(밸런스 시뮬·빠른 전투용)
var busy := false                     # 연출 재생 중 입력 무시
var show_tip := false                 # 첫 전투 콤보 안내
var card_of: Dictionary = {}          # Combatant → 카드 노드(연출 위치용)

# UI 노드
var banner: Label
var flash: ColorRect
var enemies_box: HBoxContainer
var allies_box: HBoxContainer
var log_label: Label
var prompt_label: Label
var action_box: HBoxContainer

func _ready() -> void:
	if not fast:  # 시뮬 모드는 UI 생성 생략(성능)
		_build_ui()
	_start_battle()

func _build_ui() -> void:
	add_child(UIKit.backdrop())  # 분위기 그라데이션 + 비네트

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

	# 전투 로그(적/아군 행 사이 중앙 밴드) — 잘 보이게 크게
	log_label = _mk_label("", 21, Color(0.88, 0.86, 0.96))
	log_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	log_label.offset_top = 230; log_label.offset_bottom = 356
	log_label.add_theme_constant_override("line_spacing", 4)
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

	# 화면 플래시(치명타·강타 강조)
	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1, 1, 1, 0)
	flash.z_index = 200
	add_child(flash)

	# 빠른 전투 토글(우상단)
	var speed_btn := Button.new()
	speed_btn.add_theme_font_override("font", FONT)
	speed_btn.add_theme_font_size_override("font_size", 16)
	speed_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
	speed_btn.offset_left = -132; speed_btn.offset_top = 10; speed_btn.offset_right = -12; speed_btn.offset_bottom = 46
	speed_btn.text = "속도 x%d" % int(GameState.battle_speed)
	UIKit.style_button(speed_btn, Color(0.5, 0.6, 0.7))
	speed_btn.pressed.connect(func():
		GameState.battle_speed = 3.0 if GameState.battle_speed < 2.0 else 1.0
		speed_btn.text = "속도 x%d" % int(GameState.battle_speed))
	add_child(speed_btn)

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
		GameState.cur_node = RunMap.entry(GameState.region_idx)
	var node := RunMap.node(GameState.region_idx, GameState.cur_node)
	node_type = node.type
	enemies = []
	for e in RunMap.gen_enemies(GameState.region_idx, node):  # 보스=고정, 그 외=풀에서 무작위
		var ec := _enemy_soul(e.name, e.job, e.lore, e.hp, e.atk)
		ec.cd = 1 + enemies.size()  # 고유기 첫 사용을 스태거(1마리씩 시차)
		enemies.append(ec)
	if node_type == "boss" and not enemies.is_empty():
		enemies[0].is_boss = true  # 첫 적 = 격노 페이즈 대상
	# 유물 효과 + 패시브(전투 시작)
	var has_chrono := false
	for a in allies:
		if GameState.has_relic("vigor"): a.atk += 2
		if GameState.has_relic("vital"): a.shield += 10
		if GameState.has_relic("armor"): a.dmg_reduce += 1
		if GameState.has_relic("swift"): a.cd = 0  # 신속: 고유기 즉시
		if a.job == Jobs.KNIGHT: a.dmg_reduce += 1  # 불굴
		if a.job == Jobs.CHRONO: has_chrono = true
	if GameState.has_relic("radiance"):
		for e in enemies:
			e.vulnerable = 1
	if GameState.has_relic("ward"):  # 약화: 적 공격 -2
		for e in enemies:
			e.atk = maxi(1, e.atk - 2)
	if has_chrono:  # 시간 왜곡: 적 고유기 1턴 지연
		for e in enemies:
			e.cd += 1
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
	var mhp := GameState.max_hp(entry)
	var c := Combatant.new(entry.name, entry.job, d.color, mhp, d.atk + (lvl - 1), false)
	c.hp = clampi(int(entry.get("hp", mhp)), 1, mhp)  # 누적 피해 유지(최소 1로 진입)
	c.level = lvl
	return c

func _enemy_soul(p_name: String, job: String, lore: String, hp: int, atk: int) -> Combatant:
	var c := Combatant.new(p_name, job, Color(0.55, 0.55, 0.6), hp, atk, true)
	c.lore = lore
	return c

func _start_round() -> void:
	if GameState.has_relic("regen"):  # 매 라운드 재생
		for a in allies:
			if a.alive():
				a.heal(3)
	for a in allies:  # 치유사 패시브: 생명의 가호
		if a.alive() and a.job == Jobs.MENDER:
			var low := _lowest_living(allies)
			if low: low.heal(4)
	if GameState.has_relic("bulwark"):  # 성벽: 매 라운드 보호막
		for a in allies:
			if a.alive(): a.shield += 4
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

# ── 행동 처리(연출 포함) ─────────────────────────────────────────
## 광폭화(광전사): HP 절반 이하면 공격 +3.
func _atk_bonus(c: Combatant) -> int:
	return 3 if c.job == Jobs.BERSERKER and c.hp * 2 <= c.max_hp else 0

## 사냥꾼(처형인): 체력 40% 이하 적에게 피해 배수.
func _hunter(actor_c: Combatant, target: Combatant) -> float:
	return 1.5 if actor_c.job == Jobs.HEADSMAN and target.hp * 5 <= target.max_hp * 2 else 1.0

func _resolve(target: Combatant) -> void:
	await _lunge(actor)
	if action == "atk":
		var raw := int(round((actor.atk + _atk_bonus(actor)) * _hunter(actor, target)))
		var dealt := target.take_damage(raw)
		if actor.job == Jobs.PLAGUE and target.alive():  # 맹독: 기본 공격도 취약
			target.vulnerable = maxi(target.vulnerable, 1)
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
			await _hit(actor, "방어!", Color(0.55, 0.75, 1.0), false)
		Jobs.PLAGUE:
			target.vulnerable = PLAGUE_VULN
			var dealt := target.take_damage(PLAGUE_DMG)
			_log("%s ▸ 역병의 표식! %s 취약 %d턴 (%d 피해)%s" % [actor.display_name, target.display_name, PLAGUE_VULN, dealt, _kill(target)])
			await _hit(target, "취약! -%d" % dealt, Color(0.6, 0.95, 0.5), false)
		Jobs.HEADSMAN:
			var crit := target.vulnerable > 0
			var raw := HEADSMAN_DMG * 2 if crit else HEADSMAN_DMG
			raw = int(round(raw * _hunter(actor, target)))  # 사냥꾼 패시브
			var dealt := target.take_damage(raw, false)  # 치명타는 이미 반영, 취약 중복 ×1.5 방지
			var tag := " 치명타!" if crit else ""
			if crit:
				_screen_flash(Color(1, 0.85, 0.3))
			_log("%s ▸ 단두!%s %s에 %d 피해%s" % [actor.display_name, tag, target.display_name, dealt, _kill(target)])
			await _hit(target, ("-%d 치명!" % dealt) if crit else "-%d" % dealt, Color(1, 0.85, 0.3) if crit else Color(1, 0.5, 0.45), crit)
		Jobs.BERSERKER:
			var hits: Array[String] = []
			var aoe := BERSERK_DMG + _atk_bonus(actor)  # 광폭화 반영
			for e in enemies:
				if e.alive():
					var dd := e.take_damage(aoe)
					hits.append("%s %d%s" % [e.display_name, dd, _kill(e)])
					await _hit(e, "-%d" % dd, Color(1, 0.55, 0.25), false)
			actor.take_damage(BERSERK_RECOIL, false)  # 자해 반동(취약 무관)
			_log("%s ▸ 광란! 적 전체 — %s | 반동 %d" % [actor.display_name, ", ".join(hits), BERSERK_RECOIL])
			await _hit(actor, "반동 -%d" % BERSERK_RECOIL, Color(0.9, 0.5, 0.5), false)
		Jobs.MENDER:
			var t := _lowest_living(allies)
			if t:
				var h := t.heal(HEAL_AMT)
				_log("%s ▸ 치유의 빛! %s 체력 +%d" % [actor.display_name, t.display_name, h])
				await _hit(t, "+%d" % h, Color(0.5, 0.95, 0.7), false)
		Jobs.CHRONO:
			var t := _best_other_ally(actor)  # 가장 센 다른 아군에게 추가 행동
			if t:
				pending.append(t)  # 이번 라운드 한 번 더 행동
				_log("%s ▸ 가속! %s가 한 번 더 행동한다" % [actor.display_name, t.display_name])
				await _hit(t, "+행동", Color(0.62, 0.68, 1.0), false)
		_:
			pass

func _kill(c: Combatant) -> String:
	return "  (쓰러짐)" if not c.alive() else ""

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
	if not fast:
		await get_tree().create_timer(_d(STEP)).timeout
	for e in enemies:  # 보스 격노(HP 절반 이하, 1회)
		if e.is_boss and e.alive() and not e.enraged and e.hp * 2 <= e.max_hp:
			e.enraged = true
			e.atk += ENRAGE_ATK
			_log("%s — 격노! 공격이 거세진다" % e.display_name)
			_screen_flash(Color(1, 0.3, 0.3))
	for e in enemies:
		if not e.alive():
			continue
		if e.cd == 0:
			await _enemy_skill(e)  # 고유기(쿨다운 0)
			e.cd = ENEMY_SKILL_CD
		else:
			var target := _enemy_target()
			if target == null:
				break
			await _lunge(e)
			var dealt := target.take_damage(e.atk)
			_log("%s ▸ %s 공격, %d 피해%s" % [e.display_name, target.display_name, dealt, _kill(target)])
			await _hit(target, "-%d" % dealt, Color(1, 0.45, 0.4), false)
		_refresh()
		if _all_dead(allies):
			break
		if not fast:
			await get_tree().create_timer(_d(STEP)).timeout
	if _all_dead(allies):
		_end_battle(false)
		return
	# 라운드 종료: 상태 감소
	for c in allies + enemies:
		c.tick()
	round_no += 1
	_start_round()

## 적 고유기 — 직업별. 위협 우선순위·탱 보호·빠른 처치를 강제한다.
func _enemy_skill(e: Combatant) -> void:
	await _lunge(e)
	match e.job:
		Jobs.BERSERKER:  # 광란: 아군 전체 광역(아프게)
			var dmg := e.atk
			for a in allies:
				if a.alive():
					var dd := a.take_damage(dmg)
					await _hit(a, "-%d" % dd, Color(1, 0.55, 0.25), false)
			_log("%s ▸ 광란! 아군 전체에 광역 피해" % e.display_name)
		Jobs.PLAGUE:  # 취약 부여 + 소량(아군이 더 아프게)
			var t := _enemy_target()
			if t:
				t.vulnerable = 2
				var dd := t.take_damage(int(round(e.atk * 0.5)))
				_log("%s ▸ 역병! %s 취약 2턴 (%d 피해)%s" % [e.display_name, t.display_name, dd, _kill(t)])
				await _hit(t, "취약! -%d" % dd, Color(0.7, 0.95, 0.4), false)
		Jobs.HEADSMAN:  # 처형 강타: 도발 무시하고 최저 HP 아군 저격(약체 보호가 과제)
			var t := _lowest_living(allies)
			if t:
				_screen_flash(Color(1, 0.3, 0.3))
				var dd := t.take_damage(e.atk * 2)
				_log("%s ▸ 처형! %s에 %d 피해%s" % [e.display_name, t.display_name, dd, _kill(t)])
				await _hit(t, "처형 -%d" % dd, Color(1, 0.4, 0.45), true)
		Jobs.KNIGHT:  # 방어 태세: 자기 보호막(더 단단하게 → 빨리 잡아야)
			e.shield += 15
			_log("%s ▸ 방어 태세! 보호막 15" % e.display_name)
			await _hit(e, "방패+15", Color(0.55, 0.75, 1.0), false)
		Jobs.MENDER:  # 적 치유사: 아군(적 진영) 회복 → 먼저 잡아야 하는 위협
			var t := _lowest_living(enemies)
			if t:
				var h := t.heal(ENEMY_HEAL)
				_log("%s ▸ 치유! %s 체력 +%d" % [e.display_name, t.display_name, h])
				await _hit(t, "+%d" % h, Color(0.5, 0.95, 0.7), false)
		Jobs.CHRONO:  # 적 시간술사: 연속 공격(추가 행동을 2연타로 표현)
			var t := _enemy_target()
			if t:
				var d1 := t.take_damage(e.atk)
				_log("%s ▸ 시간 가속! %s에 연속 공격 (%d)%s" % [e.display_name, t.display_name, d1, _kill(t)])
				await _hit(t, "-%d" % d1, Color(0.7, 0.75, 1.0), false)
				if t.alive():
					var d2 := t.take_damage(e.atk)
					await _hit(t, "-%d" % d2, Color(0.7, 0.75, 1.0), false)
		_:
			pass

## 도발 중인 아군을 우선, 없으면 최저 HP 아군(집중 공격).
func _enemy_target() -> Combatant:
	var taunter: Combatant = null
	var weakest: Combatant = null
	for a in allies:
		if not a.alive():
			continue
		if a.taunt > 0 and (taunter == null):
			taunter = a
		if weakest == null or a.hp < weakest.hp:
			weakest = a
	return taunter if taunter != null else weakest

## 자신을 제외한, 공격력이 가장 높은 살아있는 아군(가속 대상).
func _best_other_ally(self_c: Combatant) -> Combatant:
	var best: Combatant = null
	for a in allies:
		if a.alive() and a != self_c and (best == null or a.atk > best.atk):
			best = a
	return best

## 살아있는 것 중 HP 최저(치유 대상).
func _lowest_living(arr: Array[Combatant]) -> Combatant:
	var best: Combatant = null
	for c in arr:
		if c.alive() and (best == null or c.hp < best.hp):
			best = c
	return best

func _all_dead(arr: Array[Combatant]) -> bool:
	for c in arr:
		if c.alive():
			return false
	return true

func _end_battle(won: bool) -> void:
	if won:
		_persist_party_hp()  # 전투 종료 HP를 로스터에 기록(어트리션) + 탈진자 허약 부활
		_apply_levelups()
		# 노드 클리어 → 위치 갱신
		GameState.run_pos = GameState.cur_node
		if not GameState.run_cleared.has(GameState.cur_node):
			GameState.run_cleared.append(GameState.cur_node)
		if node_type == "elite":
			GameState.level_party(RunMap.ELITE_BONUS)  # 정예 보상: 팀 추가 레벨
			_log("정예 격파 보상 ▸ 출전 팀 전원 +%d 레벨" % RunMap.ELITE_BONUS)
		if node_type == "elite" or node_type == "boss":  # 유물 획득
			var rid := GameState.grant_random_relic()
			if rid != "":
				_log("유물 획득 ▸ %s (%s)" % [Relics.get_def(rid).name, Relics.get_def(rid).desc])
		phase = Phase.COLLECT
		_log("승리! 쓰러진 영혼 중 하나를 거둘 수 있다.")
	else:
		phase = Phase.RESULT
		_log("패배… 강령술사도 쓰러졌다.")
	_refresh()

## 전투 종료 HP를 로스터에 기록. 쓰러진(탈진) 영혼은 최대 25%로 허약 부활.
func _persist_party_hp() -> void:
	for i in allies.size():
		if i < ally_src.size():
			var ri := ally_src[i]
			var mhp := GameState.max_hp(GameState.roster[ri])
			var h := allies[i].hp
			if h <= 0:
				h = int(ceil(mhp * 0.25))
			GameState.roster[ri]["hp"] = clampi(h, 1, mhp)

## 생존한 참전 영혼 경험치 획득 + 레벨업 — 영구 보존.
func _apply_levelups() -> void:
	var amt := GameState.EXP_PER_ENEMY * enemies.size()
	var ups: Array[String] = []
	for i in allies.size():
		if allies[i].alive() and i < ally_src.size():
			var ri := ally_src[i]
			var gained := GameState.grant_exp(ri, amt)
			var tag := " → Lv%d!" % GameState.roster[ri].level if gained > 0 else ""
			ups.append("%s +%dEXP%s" % [GameState.roster[ri].name, amt, tag])
	if not ups.is_empty():
		_log("획득 ▸ " + ", ".join(ups))

## 거두기 — 쓰러진 영혼 하나를 로스터에 추가 + 사연 해금.
func _on_collect(e: Combatant) -> void:
	if busy:
		return
	GameState.bind_soul({"job": e.job, "name": e.display_name, "lore": e.lore, "level": 1})
	_log("%s의 영혼을 거뒀다. (보유 %d)" % [e.display_name, GameState.roster.size()])
	_log("“%s”" % e.lore)
	phase = Phase.RESULT
	_refresh()

# ── 공격 돌진(행동 주체가 상대 쪽으로 darts) ───────────────────
## 연출 시간 = 기본 / 속도배수(빠른 전투 토글). 최소치로 0 나눗셈 방지.
func _d(base: float) -> float:
	return base / maxf(0.1, GameState.battle_speed)

func _lunge(c: Combatant) -> void:
	if fast:
		return
	var card: Control = card_of.get(c)
	if card == null:
		return
	var dir := Vector2(0, 46 if c.is_enemy else -46)  # 상대 쪽으로 크게 돌진(싸우는 느낌)
	var base := card.position
	var tw := create_tween()
	tw.tween_property(card, "position", base + dir, _d(0.09)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "position", base, _d(0.10))
	await tw.finished

## 화면 전체 플래시(치명타·강타 강조). 대기 안 함.
func _screen_flash(col: Color) -> void:
	if fast:
		return
	flash.color = Color(col.r, col.g, col.b, 0.28)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, _d(0.35))

# ── 피격 연출: 카드 번쩍 + 데미지 숫자 떠오름 ────────────────────
func _hit(c: Combatant, text: String, color: Color, big: bool) -> void:
	if fast:
		return
	var card: Control = card_of.get(c)
	if card == null:
		return
	await get_tree().process_frame  # 카드 레이아웃 확정 후 위치 읽기
	var center := card.global_position + card.size * 0.5
	# 카드 번쩍(밝게 → 원복) + 흔들림(피격 손맛)
	card.modulate = Color(1.5, 1.4, 1.4)
	var base := card.position
	var sd := _d(0.04)
	var shake := create_tween()
	shake.tween_property(card, "position", base + Vector2(7, 0), sd)
	shake.tween_property(card, "position", base - Vector2(6, 0), sd)
	shake.tween_property(card, "position", base + Vector2(3, 0), sd)
	shake.tween_property(card, "position", base, sd)
	# 떠오르는 숫자
	var lbl := _mk_label(text, 34 if big else 26, color)
	lbl.z_index = 100
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	add_child(lbl)
	lbl.position = center - Vector2(40, 10)
	var fh := _d(FX_HIT)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 48, fh)
	tw.tween_property(lbl, "modulate:a", 0.0, fh).set_delay(fh * 0.4)
	tw.tween_property(card, "modulate", Color.WHITE, fh * 0.5)
	await tw.finished
	lbl.queue_free()

# ── 렌더 ─────────────────────────────────────────────────────────
func _refresh() -> void:
	if fast:
		return  # 시뮬/빠른 전투: 시각 갱신 생략(로직은 외부에서 관리)
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
	# 아군은 선택/행동/타겟 단계 내내 클릭 가능 → 다른 영혼 클릭으로 즉시 재선택(뒤로 버튼 불필요)
	var ally_pick := phase == Phase.SELECT_ACTOR or phase == Phase.SELECT_ACTION or phase == Phase.SELECT_TARGET
	for a in allies:
		allies_box.add_child(_unit_card(a, ally_pick and pending.has(a), _on_actor))

	log_label.text = "\n".join(log_lines.slice(maxi(0, log_lines.size() - 4)))
	_set_banner()

	match phase:
		Phase.SELECT_ACTOR:
			prompt_label.text = "행동할 영혼을 선택 (아래 카드)"
		Phase.SELECT_ACTION:
			prompt_label.text = "%s — 행동 선택  (다른 영혼 클릭 시 교체)" % actor.display_name
			_add_action_btn("기본 공격", actor.color, func(): _on_action("atk"))
			var d := Jobs.get_def(actor.job)
			var skill_btn := _add_action_btn("%s (%s)" % [d.skill, d.desc], actor.color, func(): _on_action("skill"))
			if actor.cd > 0:
				skill_btn.disabled = true
				skill_btn.text = "%s — 재사용 %d턴" % [d.skill, actor.cd]
		Phase.SELECT_TARGET:
			prompt_label.text = "%s의 대상을 선택 (위쪽 적)" % actor.display_name
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
				# 전멸 = 런 실패. 처음부터(전원 회복)로.
				_add_action_btn("처음부터 (회복)", Color(0.6, 0.45, 0.95), func():
					GameState.new_run()
					get_tree().change_scene_to_file("res://scenes/ui/map.tscn"))
			_add_action_btn("타이틀로", Color(0.5, 0.5, 0.58), func(): get_tree().change_scene_to_file("res://scenes/ui/title.tscn"))

func _set_banner() -> void:
	match phase:
		Phase.ENEMY:
			banner.text = "— 적의 차례 —"
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
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var tint := Color(1, 0.5, 0.5) if c.is_enemy else Color.WHITE  # 적=붉은 틴트
	header.add_child(Avatar.new().setup(c.job, accent, 50, tint))
	var title := c.display_name + ("  Lv%d" % c.level if not c.is_enemy else "")
	var name_l := _mk_label(title, 18, Color.WHITE if not dead else Color(0.45, 0.45, 0.5))
	name_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(name_l)
	box.add_child(header)

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
