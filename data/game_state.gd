extends Node
## 전역 상태(오토로드). 버전 + 거둔 영혼 로스터/사연(전투 사이 영구 보존).

const VERSION := "v0.10"  ## 빌드 버전(타이틀 표기) — 빌드마다 올릴 것

const PARTY_MAX := 3  ## 출전 팀 최대 인원
const EXP_PER_ENEMY := 3  ## 전투 승리 시 생존 영혼이 적 1체당 얻는 경험치

## 거둔 영혼 목록. 각 항목: {job, name, lore, level}.
var roster: Array[Dictionary] = []
## 출전 팀 = roster 인덱스 배열(최대 PARTY_MAX). 편성 화면에서 변경.
var party: Array[int] = []
## 거두며 해금한 '그날 밤의 증언' 조각.
var story_fragments: Array[String] = []

## ── 분기 런 진행 ──
var run_pos: String = ""           # 현재 위치 노드 id("" = 런 시작)
var run_cleared: Array[String] = []  # 클리어한 노드 id
var cur_node: String = ""          # 진입한 전투 노드(battle 씬이 읽음)

## 런 처음부터 다시(로스터·레벨은 유지 = NG+식).
func reset_run() -> void:
	run_pos = ""
	run_cleared = []
	cur_node = ""

## 출전 팀 전원 레벨 +n (휴식·정예 보상).
func level_party(n: int) -> void:
	for idx in party:
		if idx >= 0 and idx < roster.size():
			roster[idx].level += n

func _ready() -> void:
	if roster.is_empty():
		roster = [
			{"job": Jobs.KNIGHT, "name": "기사", "lore": "왕을 끝까지 지키려다 성문 앞에서 스러진 근위병.", "level": 1, "exp": 0},
			{"job": Jobs.PLAGUE, "name": "독술사", "lore": "역병을 막으려다 역병의 일부가 된 궁정 약사.", "level": 1, "exp": 0},
			{"job": Jobs.HEADSMAN, "name": "처형인", "lore": "마지막 명령으로 동료의 목을 친 뒤 스스로 무너진 형리.", "level": 1, "exp": 0},
		]
		party = [0, 1, 2]

## 영혼을 로스터에 추가 + 사연 조각 해금.
func bind_soul(entry: Dictionary) -> void:
	if not entry.has("exp"):
		entry["exp"] = 0
	roster.append(entry)
	if entry.has("lore") and entry.lore != "":
		story_fragments.append(entry.lore)

## 다음 레벨까지 필요한 경험치(레벨이 오를수록 증가).
func exp_need(level: int) -> int:
	return 5 + (level - 1) * 3

## 경험치 부여 + 누적 레벨업 처리. 오른 레벨 수 반환.
func grant_exp(idx: int, amount: int) -> int:
	var e: Dictionary = roster[idx]
	e["exp"] = int(e.get("exp", 0)) + amount
	var gained := 0
	while int(e.exp) >= exp_need(int(e.level)):
		e["exp"] = int(e.exp) - exp_need(int(e.level))
		e["level"] = int(e.level) + 1
		gained += 1
	return gained
