class_name Encounters
extends RefCounted
## 지역 진행 = 전투 노드의 연속. 노드마다 적 구성·난이도·서사 도입이 다르다.
## 적은 거둘 수 있는 영혼이므로 name/job/lore 보유. hp/atk로 노드별 난이도 차등.
## 적 직업은 수집 시 해금되는 archetype과 직결(광인=광전사 등).

const REGION_NAME := "그날의 잔해 · 왕성"

const NODES := [
	{
		"name": "성문 앞",
		"intro": "성문 앞. 가장 먼저 쓰러졌던 자들이 너를 막아선다.",
		"enemies": [
			{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 34, "atk": 6, "lore": "성문이 부서지던 순간까지 창을 거두지 않았다."},
			{"name": "역병 운반자", "job": Jobs.PLAGUE, "hp": 28, "atk": 6, "lore": "도망치다 쓰러진 자리에서 역병을 퍼뜨렸다."},
		],
	},
	{
		"name": "무너진 시가지",
		"intro": "무너진 시가지. 광기가 거리를 메웠다.",
		"enemies": [
			{"name": "부패한 근위병", "job": Jobs.KNIGHT, "hp": 40, "atk": 7, "lore": "약탈을 막으려다 약탈자가 되어 죽었다."},
			{"name": "역병 운반자", "job": Jobs.PLAGUE, "hp": 32, "atk": 6, "lore": "마지막 숨까지 역병을 토했다."},
			{"name": "피에 굶주린 광인", "job": Jobs.BERSERKER, "hp": 44, "atk": 8, "lore": "복수를 외치다 제 편마저 베고 미쳐 버린 검사."},
		],
	},
	{
		"name": "약탈당한 신전",
		"intro": "약탈당한 신전. 기도 대신 비명이 고여 있다.",
		"enemies": [
			{"name": "타락한 사제", "job": Jobs.PLAGUE, "hp": 42, "atk": 7, "lore": "신께 빌다 신을 저주하며 죽었다."},
			{"name": "신전 광신도", "job": Jobs.BERSERKER, "hp": 50, "atk": 9, "lore": "거짓 신탁을 외치며 칼을 휘둘렀다."},
			{"name": "근위장", "job": Jobs.KNIGHT, "hp": 54, "atk": 8, "lore": "끝까지 신전을 사수하라는 명을 지켰다."},
		],
	},
	{
		"name": "왕의 침소 · 보스",
		"intro": "왕의 침소. 그날 밤의 끝이 여기 있다.",
		"enemies": [
			{"name": "왕의 그림자", "job": Jobs.HEADSMAN, "hp": 96, "atk": 12, "lore": "왕이 마지막으로 내린 명령, 그 자체가 된 그림자."},
			{"name": "충성스런 시종", "job": Jobs.KNIGHT, "hp": 34, "atk": 6, "lore": "주인을 두고 달아나지 못한 채 그 곁에서 굳었다."},
		],
	},
]

static func count() -> int:
	return NODES.size()

static func get_node(i: int) -> Dictionary:
	return NODES[clampi(i, 0, NODES.size() - 1)]
