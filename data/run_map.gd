class_name RunMap
extends RefCounted
## 분기 진행 맵 — 지역(REGIONS)마다 레이어 노드 그래프. 현재 노드의 next 중 하나를 골라 전진.
## 노드 타입: battle(일반)·elite(강적+추가보상)·rest(전투X, 팀 회복+레벨)·boss(지역 끝).
## 핵심 결정: 정예(위험·큰보상) vs 휴식(안전·느림). 전투 노드 적은 거둘 수 있는 영혼.
## 여러 지역을 거치며 '그날 밤의 진실'이 결말로 드러난다.

const REST_LEVELS := 1   # 휴식 시 출전 팀 레벨 증가
const ELITE_BONUS := 1   # 정예 처치 시 팀 추가 레벨(일반 +1에 더해)

## 지역별 적 템플릿 풀. battle/elite 노드는 여기서 매 런 샘플링 → 런마다 적·수집 대상이 달라짐.
## (보스 노드는 고정 enemies로 서사 유지) 밸런스는 풀 티어로 한정.
const POOLS := [
	[  # 1장 · 왕성 (보통 티어)
		{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 36, "atk": 7, "lore": "성문이 부서지던 순간까지 창을 거두지 않았다."},
		{"name": "역병 운반자", "job": Jobs.PLAGUE, "hp": 30, "atk": 6, "lore": "도망치다 쓰러진 자리에서 역병을 퍼뜨렸다."},
		{"name": "피에 굶주린 광인", "job": Jobs.BERSERKER, "hp": 44, "atk": 8, "lore": "복수를 외치다 제 편마저 베고 미쳐 버린 검사."},
		{"name": "방랑하는 망령", "job": Jobs.HEADSMAN, "hp": 40, "atk": 8, "lore": "거리를 떠돌며 산 자의 목을 노린다."},
		{"name": "떠도는 치유사", "job": Jobs.MENDER, "hp": 38, "atk": 6, "lore": "죽은 자를 억지로 일으켜 세우려 했다."},
		{"name": "뒤틀린 시계공", "job": Jobs.CHRONO, "hp": 34, "atk": 6, "lore": "시간을 되돌리려다 자신만 그 순간에 갇혔다."},
	],
	[  # 2장 · 왕궁 심층 (강한 티어)
		{"name": "배신한 친위병", "job": Jobs.KNIGHT, "hp": 52, "atk": 9, "lore": "왕을 지키라는 칼로 왕의 등을 노렸다."},
		{"name": "흑사병 사령", "job": Jobs.PLAGUE, "hp": 46, "atk": 8, "lore": "역병을 무기로 바꾼 자."},
		{"name": "광란의 검사", "job": Jobs.BERSERKER, "hp": 60, "atk": 10, "lore": "충성도 광기도 같은 칼끝이었다."},
		{"name": "처형인의 망령", "job": Jobs.HEADSMAN, "hp": 56, "atk": 10, "lore": "그날 밤 가장 많은 목을 친 칼."},
		{"name": "피의 사제", "job": Jobs.MENDER, "hp": 58, "atk": 8, "lore": "산 자의 피로 죽은 자를 일으켜 세웠다."},
		{"name": "옥좌의 시계공", "job": Jobs.CHRONO, "hp": 50, "atk": 8, "lore": "왕의 시간마저 멈추려 했던 궁정 마도사."},
	],
]

## 노드 인카운터 생성 — 보스는 고정 enemies, 그 외엔 풀에서 count만큼 무작위 샘플.
## elite는 스탯 강화(+이름 접두). 매 런 달라진다.
static func gen_enemies(ri: int, n: Dictionary) -> Array:
	if n.has("enemies"):
		return n.enemies  # 보스 등 고정
	var pool: Array = POOLS[clampi(ri, 0, POOLS.size() - 1)]
	var idxs := []
	for i in pool.size():
		idxs.append(i)
	# Fisher-Yates 셔플
	for i in range(idxs.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var t = idxs[i]; idxs[i] = idxs[j]; idxs[j] = t
	var count: int = mini(n.get("count", 2), pool.size())
	var elite: bool = n.type == "elite"
	var out := []
	for k in count:
		var src: Dictionary = pool[idxs[k]]
		var e := src.duplicate(true)
		if elite:
			e.hp = int(round(e.hp * 1.3))
			e.atk += 2
			e.name = "정예 " + e.name
		out.append(e)
	return out

const REGIONS := [
	{
		"name": "1장 · 그날의 잔해 · 왕성",
		"entry": "n0",
		"order": ["n0", "n1", "n2", "n3", "n4", "n5", "n6"],
		"outro": "성을 가로질렀다. 거둔 증언이 한 방향을 가리킨다 — 더 깊은 안쪽, 옥좌를.",
		"nodes": {
			"n0": {"type": "battle", "name": "성문 앞", "layer": 0, "next": ["n1", "n2"], "count": 2,
				"intro": "성문 앞. 가장 먼저 쓰러졌던 자들이 너를 막아선다."},
			"n1": {"type": "elite", "name": "정예 · 잔존 수비대", "layer": 1, "next": ["n3"], "count": 2,
				"intro": "정예. 마지막까지 버틴 자들이 길목을 지킨다."},
			"n2": {"type": "rest", "name": "야영지", "layer": 1, "next": ["n3"],
				"intro": "무너진 벽 아래 잠시 영혼들을 추스른다."},
			"n3": {"type": "battle", "name": "무너진 시가지", "layer": 2, "next": ["n4", "n5"], "count": 3,
				"intro": "무너진 시가지. 광기가 거리를 메웠다."},
			"n4": {"type": "elite", "name": "정예 · 광신 집단", "layer": 3, "next": ["n6"], "count": 3,
				"intro": "정예. 거짓 신탁에 미친 자들이 달려든다."},
			"n5": {"type": "event", "name": "버려진 사당", "layer": 3, "next": ["n6"],
				"intro": "버려진 사당에서 이상한 기척이 느껴진다."},
			"n6": {"type": "boss", "name": "왕의 침소 · 보스", "layer": 4, "next": [],
				"intro": "왕의 침소. 그날 밤의 끝이 여기 있다.",
				"enemies": [
					{"name": "왕의 그림자", "job": Jobs.HEADSMAN, "hp": 120, "atk": 16, "lore": "왕이 마지막으로 내린 명령, 그 자체가 된 그림자."},
					{"name": "충성스런 시종", "job": Jobs.KNIGHT, "hp": 40, "atk": 7, "lore": "주인을 두고 달아나지 못한 채 그 곁에서 굳었다."},
				]},
		},
	},
	{
		"name": "2장 · 옥좌로 가는 길 · 왕궁 심층",
		"entry": "m0",
		"order": ["m0", "m1", "m2", "m3", "m4", "m5", "m6"],
		"outro": "옥좌의 그림자가 흩어진다. 그날 밤의 진실이 마침내 드러난다.",
		"nodes": {
			"m0": {"type": "battle", "name": "피의 회랑", "layer": 0, "next": ["m1", "m2"], "count": 2,
				"intro": "피의 회랑. 안으로 들어설수록 적은 더 강해진다."},
			"m1": {"type": "elite", "name": "정예 · 배신한 친위대", "layer": 1, "next": ["m3"], "count": 2,
				"intro": "정예. 가장 가까이서 왕을 지키던 자들이 칼을 돌렸다."},
			"m2": {"type": "event", "name": "옛 침전", "layer": 1, "next": ["m3"],
				"intro": "먼지 쌓인 침전에 무언가 남아 있다."},
			"m3": {"type": "battle", "name": "거울의 방", "layer": 2, "next": ["m4", "m5"], "count": 3,
				"intro": "거울의 방. 무수한 그림자가 너를 노려본다."},
			"m4": {"type": "elite", "name": "정예 · 피의 사제단", "layer": 3, "next": ["m6"], "count": 3,
				"intro": "정예. 산 자의 피로 죽은 자를 부리는 사제단."},
			"m5": {"type": "rest", "name": "옥좌 앞 제단", "layer": 3, "next": ["m6"],
				"intro": "옥좌 앞 제단에서 마지막으로 숨을 고른다."},
			"m6": {"type": "boss", "name": "옥좌 · 찬탈자의 그림자", "layer": 4, "next": [],
				"intro": "옥좌. 그날 밤 성문을 연 자가 왕관을 쓴 채 기다린다.",
				"enemies": [
					{"name": "찬탈자의 그림자", "job": Jobs.HEADSMAN, "hp": 138, "atk": 19, "lore": "그날 밤 성문을 연 자. 왕관을 위해 왕국을 통째로 팔았다."},
					{"name": "배신한 친위대장", "job": Jobs.KNIGHT, "hp": 70, "atk": 11, "lore": "찬탈자에게 충성을 옮긴 칼."},
				]},
		},
	},
]

static func region(ri: int) -> Dictionary:
	return REGIONS[clampi(ri, 0, REGIONS.size() - 1)]

static func region_count() -> int:
	return REGIONS.size()

static func entry(ri: int) -> String:
	return region(ri).entry

static func order(ri: int) -> Array:
	return region(ri).order

static func node(ri: int, id: String) -> Dictionary:
	return region(ri).nodes[id]

## 현재 위치(pos)에서 선택 가능한 다음 노드들. 시작("")이면 진입 노드.
static func reachable(ri: int, pos: String) -> Array:
	if pos == "":
		return [entry(ri)]
	return node(ri, pos).next

static func max_layer(ri: int) -> int:
	var m := 0
	for id in order(ri):
		m = maxi(m, node(ri, id).layer)
	return m
