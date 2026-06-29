class_name RunMap
extends RefCounted
## 분기 진행 맵 — 레이어별 노드 그래프. 현재 노드의 next 중 하나를 골라 전진.
## 노드 타입: battle(일반)·elite(강적+추가보상)·rest(전투X, 팀 +레벨)·boss(지역 끝).
## 핵심 결정: 정예(위험·큰보상) vs 휴식(안전·느림). 전투 노드 적은 거둘 수 있는 영혼.

const REGION_NAME := "그날의 잔해 · 왕성"
const ENTRY := "n0"
const ORDER := ["n0", "n1", "n2", "n3", "n4", "n5", "n6"]  # 렌더 순서(레이어별)
const REST_LEVELS := 1   # 휴식 시 출전 팀 레벨 증가
const ELITE_BONUS := 1   # 정예 처치 시 팀 추가 레벨(일반 +1에 더해)

const NODES := {
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
}

static func node(id: String) -> Dictionary:
	return NODES[id]

## 현재 위치(pos)에서 선택 가능한 다음 노드들. 시작("")이면 진입 노드.
static func reachable(pos: String) -> Array:
	if pos == "":
		return [ENTRY]
	return NODES[pos].next

static func max_layer() -> int:
	var m := 0
	for id in ORDER:
		m = maxi(m, NODES[id].layer)
	return m
