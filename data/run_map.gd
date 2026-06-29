class_name RunMap
extends RefCounted
## 분기 진행 맵 — 지역(REGIONS)마다 레이어 노드 그래프. 현재 노드의 next 중 하나를 골라 전진.
## 노드 타입: battle(일반)·elite(강적+추가보상)·rest(전투X, 팀 회복+레벨)·boss(지역 끝).
## 핵심 결정: 정예(위험·큰보상) vs 휴식(안전·느림). 전투 노드 적은 거둘 수 있는 영혼.
## 여러 지역을 거치며 '그날 밤의 진실'이 결말로 드러난다.

const REST_LEVELS := 1   # 휴식 시 출전 팀 레벨 증가
const ELITE_BONUS := 1   # 정예 처치 시 팀 추가 레벨(일반 +1에 더해)

const REGIONS := [
	{
		"name": "1장 · 그날의 잔해 · 왕성",
		"entry": "n0",
		"order": ["n0", "n1", "n2", "n3", "n4", "n5", "n6"],
		"outro": "성을 가로질렀다. 거둔 증언이 한 방향을 가리킨다 — 더 깊은 안쪽, 옥좌를.",
		"nodes": {
			"n0": {"type": "battle", "name": "성문 앞", "layer": 0, "next": ["n1", "n2"],
				"intro": "성문 앞. 가장 먼저 쓰러졌던 자들이 너를 막아선다.",
				"enemies": [
					{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 34, "atk": 6, "lore": "성문이 부서지던 순간까지 창을 거두지 않았다."},
					{"name": "역병 운반자", "job": Jobs.PLAGUE, "hp": 28, "atk": 6, "lore": "도망치다 쓰러진 자리에서 역병을 퍼뜨렸다."},
				]},
			"n1": {"type": "elite", "name": "정예 · 근위장", "layer": 1, "next": ["n3"],
				"intro": "정예. 근위장이 부러진 검을 들고 길목을 지킨다.",
				"enemies": [
					{"name": "근위장", "job": Jobs.KNIGHT, "hp": 62, "atk": 9, "lore": "성이 무너져도 자리를 떠나라는 명만은 받지 못했다."},
					{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 38, "atk": 7, "lore": "대장 곁에서 함께 굳었다."},
				]},
			"n2": {"type": "rest", "name": "야영지", "layer": 1, "next": ["n3"],
				"intro": "무너진 벽 아래 잠시 영혼들을 추스른다."},
			"n3": {"type": "battle", "name": "무너진 시가지", "layer": 2, "next": ["n4", "n5"],
				"intro": "무너진 시가지. 광기가 거리를 메웠다.",
				"enemies": [
					{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 40, "atk": 7, "lore": "약탈을 막으려다 약탈자가 되어 죽었다."},
					{"name": "역병 운반자", "job": Jobs.PLAGUE, "hp": 32, "atk": 6, "lore": "마지막 숨까지 역병을 토했다."},
					{"name": "피에 굶주린 광인", "job": Jobs.BERSERKER, "hp": 44, "atk": 8, "lore": "복수를 외치다 제 편마저 베고 미쳐 버린 검사."},
				]},
			"n4": {"type": "elite", "name": "정예 · 광신 집단", "layer": 3, "next": ["n6"],
				"intro": "정예. 거짓 신탁에 미친 광신도들이 달려든다.",
				"enemies": [
					{"name": "광신 치유사", "job": Jobs.MENDER, "hp": 40, "atk": 6, "lore": "거짓 기적으로 죽어가는 자들을 억지로 붙들어 두었다."},
					{"name": "신전 광신도", "job": Jobs.BERSERKER, "hp": 52, "atk": 9, "lore": "거짓 신탁을 외치며 칼을 휘둘렀다."},
					{"name": "광신 사제", "job": Jobs.PLAGUE, "hp": 46, "atk": 8, "lore": "신께 빌다 신을 저주하며 죽었다."},
				]},
			"n5": {"type": "rest", "name": "폐사당", "layer": 3, "next": ["n6"],
				"intro": "버려진 사당에서 숨을 고른다."},
			"n6": {"type": "boss", "name": "왕의 침소 · 보스", "layer": 4, "next": [],
				"intro": "왕의 침소. 그날 밤의 끝이 여기 있다.",
				"enemies": [
					{"name": "왕의 그림자", "job": Jobs.HEADSMAN, "hp": 96, "atk": 12, "lore": "왕이 마지막으로 내린 명령, 그 자체가 된 그림자."},
					{"name": "충성스런 시종", "job": Jobs.KNIGHT, "hp": 34, "atk": 6, "lore": "주인을 두고 달아나지 못한 채 그 곁에서 굳었다."},
				]},
		},
	},
	{
		"name": "2장 · 옥좌로 가는 길 · 왕궁 심층",
		"entry": "m0",
		"order": ["m0", "m1", "m2", "m3", "m4", "m5", "m6"],
		"outro": "옥좌의 그림자가 흩어진다. 그날 밤의 진실이 마침내 드러난다.",
		"nodes": {
			"m0": {"type": "battle", "name": "피의 회랑", "layer": 0, "next": ["m1", "m2"],
				"intro": "피의 회랑. 안으로 들어설수록 적은 더 강해진다.",
				"enemies": [
					{"name": "배신한 친위병", "job": Jobs.KNIGHT, "hp": 50, "atk": 8, "lore": "왕을 지키라는 칼로 왕의 등을 노렸다."},
					{"name": "흑사병 사령", "job": Jobs.PLAGUE, "hp": 42, "atk": 8, "lore": "역병을 무기로 바꾼 자."},
				]},
			"m1": {"type": "elite", "name": "정예 · 배신한 친위대", "layer": 1, "next": ["m3"],
				"intro": "정예. 가장 가까이서 왕을 지키던 자들이 칼을 돌렸다.",
				"enemies": [
					{"name": "친위대장", "job": Jobs.KNIGHT, "hp": 84, "atk": 11, "lore": "왕의 곁을 가장 가까이서 지켰고, 가장 먼저 등을 돌렸다."},
					{"name": "광란의 검사", "job": Jobs.BERSERKER, "hp": 60, "atk": 10, "lore": "충성도 광기도 같은 칼끝이었다."},
				]},
			"m2": {"type": "rest", "name": "옛 침전", "layer": 1, "next": ["m3"],
				"intro": "먼지 쌓인 침전에서 영혼들을 추스른다."},
			"m3": {"type": "battle", "name": "거울의 방", "layer": 2, "next": ["m4", "m5"],
				"intro": "거울의 방. 무수한 그림자가 너를 노려본다.",
				"enemies": [
					{"name": "처형인의 망령", "job": Jobs.HEADSMAN, "hp": 58, "atk": 10, "lore": "그날 밤 가장 많은 목을 친 칼."},
					{"name": "흑사병 사령", "job": Jobs.PLAGUE, "hp": 48, "atk": 8, "lore": "거울 속에서도 역병을 퍼뜨린다."},
					{"name": "배신한 친위병", "job": Jobs.KNIGHT, "hp": 54, "atk": 9, "lore": "거울에 비친 죄를 외면했다."},
				]},
			"m4": {"type": "elite", "name": "정예 · 피의 사제단", "layer": 3, "next": ["m6"],
				"intro": "정예. 산 자의 피로 죽은 자를 부리는 사제단.",
				"enemies": [
					{"name": "피의 대사제", "job": Jobs.MENDER, "hp": 64, "atk": 8, "lore": "산 자의 피로 죽은 자를 일으켜 세웠다."},
					{"name": "광란의 검사", "job": Jobs.BERSERKER, "hp": 62, "atk": 11, "lore": "피의 의식 속에서 미쳐 날뛰었다."},
					{"name": "흑사병 사령", "job": Jobs.PLAGUE, "hp": 52, "atk": 9, "lore": "사제단의 마지막 숨결."},
				]},
			"m5": {"type": "rest", "name": "옥좌 앞 제단", "layer": 3, "next": ["m6"],
				"intro": "옥좌 앞 제단에서 마지막으로 숨을 고른다."},
			"m6": {"type": "boss", "name": "옥좌 · 찬탈자의 그림자", "layer": 4, "next": [],
				"intro": "옥좌. 그날 밤 성문을 연 자가 왕관을 쓴 채 기다린다.",
				"enemies": [
					{"name": "찬탈자의 그림자", "job": Jobs.HEADSMAN, "hp": 132, "atk": 14, "lore": "그날 밤 성문을 연 자. 왕관을 위해 왕국을 통째로 팔았다."},
					{"name": "배신한 친위대장", "job": Jobs.KNIGHT, "hp": 64, "atk": 10, "lore": "찬탈자에게 충성을 옮긴 칼."},
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
