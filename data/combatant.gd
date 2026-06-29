class_name Combatant
extends RefCounted
## 전투 중 한 유닛의 런타임 상태(아군 영혼·적 공용).
## 영구 데이터(레벨/경험치/사연)는 이후 Soul로 분리. 지금은 전투에 필요한 것만.

const VULN_MULT := 1.5  # 취약 상태일 때 받는 피해 배수

var display_name: String
var job: String          # 적은 "enemy" 등 임의 식별자, 아군은 Jobs.* 키
var color: Color
var max_hp: int
var hp: int
var atk: int
var is_enemy: bool
var level := 1  # 표시용(아군 전투 카드)
var lore := ""  # 거둘 때 해금되는 '증언'(적 수집용)

# 상태(턴 단위로 감소/소비)
var shield := 0          # 흡수량(소비될 때까지 유지)
var vulnerable := 0      # 취약 남은 턴(받는 피해 ↑)
var taunt := 0           # 도발 남은 턴(적이 이 유닛을 우선 노림)
var cd := 0              # 고유기술 쿨다운 남은 턴

func _init(p_name: String, p_job: String, p_color: Color, p_hp: int, p_atk: int, p_enemy: bool) -> void:
	display_name = p_name
	job = p_job
	color = p_color
	max_hp = p_hp
	hp = p_hp
	atk = p_atk
	is_enemy = p_enemy

func alive() -> bool:
	return hp > 0

## raw 피해 적용. apply_vuln=true면 취약 배수 반영, 보호막이 먼저 흡수.
## 반환: 실제로 HP에 들어간 피해(로그용).
func take_damage(raw: int, apply_vuln := true) -> int:
	var dmg := raw
	if apply_vuln and vulnerable > 0:
		dmg = int(round(dmg * VULN_MULT))
	if shield > 0:
		var absorbed := mini(shield, dmg)
		shield -= absorbed
		dmg -= absorbed
	hp = maxi(0, hp - dmg)
	return dmg

## 라운드 종료 시 상태 1턴 감소(보호막은 소비 전까지 유지).
func tick() -> void:
	vulnerable = maxi(0, vulnerable - 1)
	taunt = maxi(0, taunt - 1)
	cd = maxi(0, cd - 1)

## 카드에 표시할 상태 뱃지 텍스트(없으면 빈 문자열).
func status_text() -> String:
	var parts: Array[String] = []
	if shield > 0: parts.append("방패%d" % shield)
	if vulnerable > 0: parts.append("취약%d" % vulnerable)
	if taunt > 0: parts.append("도발%d" % taunt)
	return "  ".join(parts)
