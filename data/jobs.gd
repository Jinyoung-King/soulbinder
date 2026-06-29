class_name Jobs
extends RefCounted
## 생전 직업(영혼 타입) 정적 데이터 테이블.
## 전투 수치·기술 메타만 여기 두고, 실제 기술 로직은 battle.gd가 직업으로 분기한다.
## 슬라이스 핵심 가설: 직업이 '수치'가 아니라 '역할/콤보'로 달라서 행동 순서가 의미를 갖는다.

const KNIGHT := "knight"      # 기사 — 맞아주는 탱. 도발+보호막
const PLAGUE := "plague"      # 독술사 — 취약 표식을 거는 셋업
const HEADSMAN := "headsman"  # 처형인 — 취약 대상에 치명타(피니셔)
const BERSERKER := "berserker"  # 광전사 — 광역 청소(자해 반동). 단일 폭딜과의 조합 갈림
const MENDER := "mender"  # 치유사 — 지속(회복). 어트리션 완화 → 휴식 대신 정예 버티기 전략
const CHRONO := "chrono"  # 시간술사 — 가속(아군 추가 행동). 콤보 증폭(같은 라운드 두 번 때리기)

## 직업별 정의. hp/atk=기본 스탯, skill=고유기술 메타.
const TABLE := {
	KNIGHT: {
		"name": "기사", "color": Color(0.45, 0.62, 0.95),
		"hp": 60, "atk": 8,
		"skill": "수호의 맹세", "desc": "보호막 + 도발(다음 적 턴, 적이 나를 노림)",
		"cd": 2, "needs_target": false,
		"passive": "불굴", "passive_desc": "받는 피해 -1 (항상)",
	},
	PLAGUE: {
		"name": "독술사", "color": Color(0.45, 0.78, 0.42),
		"hp": 30, "atk": 4,
		"skill": "역병의 표식", "desc": "대상에 취약 2턴(받는 피해 증가) + 소량 피해",
		"cd": 1, "needs_target": true,
		"passive": "맹독", "passive_desc": "기본 공격도 취약 1턴을 남긴다",
	},
	HEADSMAN: {
		"name": "처형인", "color": Color(0.85, 0.35, 0.4),
		"hp": 42, "atk": 7,
		"skill": "단두", "desc": "큰 피해. 취약 대상엔 치명타(피해 2배)",
		"cd": 2, "needs_target": true,
		"passive": "사냥꾼", "passive_desc": "체력 40% 이하 적에게 피해 +50%",
	},
	BERSERKER: {
		"name": "광전사", "color": Color(0.95, 0.55, 0.2),
		"hp": 46, "atk": 9,
		"skill": "광란", "desc": "모든 적에게 피해 + 자신도 반동 피해",
		"cd": 2, "needs_target": false,
		"passive": "광폭화", "passive_desc": "자신 HP 절반 이하면 공격 +3",
	},
	MENDER: {
		"name": "치유사", "color": Color(0.45, 0.82, 0.72),
		"hp": 34, "atk": 5,
		"skill": "치유의 빛", "desc": "가장 약한 아군의 체력을 회복",
		"cd": 2, "needs_target": false,
		"passive": "생명의 가호", "passive_desc": "매 라운드 가장 약한 아군 +4 회복",
	},
	CHRONO: {
		"name": "시간술사", "color": Color(0.62, 0.68, 1.0),
		"hp": 32, "atk": 6,
		"skill": "가속", "desc": "아군 하나가 이번 라운드에 한 번 더 행동",
		"cd": 3, "needs_target": false,
		"passive": "시간 왜곡", "passive_desc": "전투 시작 시 적 고유기를 1턴 늦춤",
	},
}

static func get_def(job: String) -> Dictionary:
	return TABLE[job]
