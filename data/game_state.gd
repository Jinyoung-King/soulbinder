extends Node
## 전역 상태(오토로드). 버전 + 거둔 영혼 로스터/사연(전투 사이 영구 보존).

const VERSION := "v0.22"  ## 빌드 버전(타이틀 표기) — 빌드마다 올릴 것

const PARTY_MAX := 3  ## 출전 팀 최대 인원
var battle_speed := 1.0  ## 전투 연출 속도 배수(빠른 전투 토글, 세션 유지)
const EXP_PER_ENEMY := 3  ## 전투 승리 시 생존 영혼이 적 1체당 얻는 경험치

## 거둔 영혼 목록. 각 항목: {job, name, lore, level}.
var roster: Array[Dictionary] = []
## 출전 팀 = roster 인덱스 배열(최대 PARTY_MAX). 편성 화면에서 변경.
var party: Array[int] = []
## 거두며 해금한 '그날 밤의 증언' 조각. 각 항목 {name, lore}. (런 넘어 영구 보존)
var story_fragments: Array[Dictionary] = []

## ── 분기 런 진행 ──
var region_idx := 0                # 현재 지역(장) 인덱스
var run_pos: String = ""           # 현재 위치 노드 id("" = 런 시작)
var run_cleared: Array[String] = []  # 클리어한 노드 id
var cur_node: String = ""          # 진입한 전투 노드(battle 씬이 읽음)
var relics: Array[String] = []     # 보유 유물(런 내내 유지, 새 런에서 초기화)

func has_relic(id: String) -> bool:
	return relics.has(id)

## 미보유 유물 하나 무작위 지급. 지급된 id 반환(전부 보유면 "").
func grant_random_relic() -> String:
	var avail := []
	for id in Relics.IDS:
		if not relics.has(id):
			avail.append(id)
	if avail.is_empty():
		return ""
	var id: String = avail[randi() % avail.size()]
	relics.append(id)
	return id

## 챕터 리셋(위치·HP만, 유물/지역 유지) — 지역 전환·전멸 복귀 공용.
func reset_run() -> void:
	run_pos = ""
	run_cleared = []
	cur_node = ""
	for e in roster:
		e["hp"] = max_hp(e)

## 완전히 새 런 — 유물·지역까지 초기화(전멸 후 처음부터 / 최종 클리어 후 재도전).
func new_run() -> void:
	relics = []
	region_idx = 0
	reset_run()

## 레벨 기준 최대 HP.
func max_hp(entry: Dictionary) -> int:
	return Jobs.get_def(entry.job).hp + (int(entry.get("level", 1)) - 1) * 5

## 출전 팀 전원 레벨 +n (휴식·정예 보상). 레벨업분만큼 HP도 가산.
func level_party(n: int) -> void:
	for idx in party:
		if idx >= 0 and idx < roster.size():
			var e: Dictionary = roster[idx]
			e["level"] = int(e.level) + n
			e["hp"] = mini(int(e.get("hp", 0)) + 5 * n, max_hp(e))

## 출전 팀 전원 완전 회복(휴식).
func heal_party() -> void:
	for idx in party:
		if idx >= 0 and idx < roster.size():
			roster[idx]["hp"] = max_hp(roster[idx])

func _ready() -> void:
	randomize()  # 런마다 적 구성·수집 대상이 달라지도록 RNG 시드
	if roster.is_empty():
		roster = [
			{"job": Jobs.KNIGHT, "name": "기사", "lore": "왕을 끝까지 지키려다 성문 앞에서 스러진 근위병.", "level": 1, "exp": 0},
			{"job": Jobs.PLAGUE, "name": "독술사", "lore": "역병을 막으려다 역병의 일부가 된 궁정 약사.", "level": 1, "exp": 0},
			{"job": Jobs.HEADSMAN, "name": "처형인", "lore": "마지막 명령으로 동료의 목을 친 뒤 스스로 무너진 형리.", "level": 1, "exp": 0},
		]
		party = [0, 1, 2]
		for e in roster:
			e["hp"] = max_hp(e)  # 시작은 풀피

## 영혼을 로스터에 추가 + 사연 조각 해금.
func bind_soul(entry: Dictionary) -> void:
	if not entry.has("exp"):
		entry["exp"] = 0
	entry["hp"] = max_hp(entry)  # 새로 거둔 영혼은 풀피(교체용 새 몸)
	roster.append(entry)
	if entry.has("lore") and entry.lore != "":
		story_fragments.append({"name": entry.get("name", "이름 없는 영혼"), "lore": entry.lore})

## 모은 증언 수에 따라 드러나는 '그날 밤의 진실' 윤곽.
func truth_hint() -> String:
	var n := story_fragments.size()
	if n == 0:
		return "아직 아무것도 알지 못한다. 영혼을 거두어 그날 밤을 증언하게 하라."
	elif n <= 2:
		return "흩어진 마지막 기억들. 윤곽은 아직 흐릿하다."
	elif n <= 4:
		return "조각들이 한 밤을 가리킨다 — 누군가 안에서 성문을 열었다."
	else:
		return "진실이 가까워진다. 그날, 멸망은 밖이 아니라 왕성 안에서 시작됐다."

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
		e["hp"] = mini(int(e.get("hp", 0)) + 5, max_hp(e))  # 레벨업 시 소폭 회복
		gained += 1
	return gained
