class_name Relics
extends RefCounted
## 유물 — 정예/보스 처치 시 얻는 패시브 보너스. 런 내내 유지(런마다 조합이 달라짐).
## 모두 단일 적용 지점(전투 시작/라운드 시작/피해 계산)이라 안전.

const TABLE := {
	"vigor": {"name": "분노의 룬", "desc": "출전 영혼 공격 +2"},
	"vital": {"name": "수호의 부적", "desc": "전투 시작 시 전원 보호막 +10"},
	"armor": {"name": "강철 피부", "desc": "받는 피해 -1"},
	"regen": {"name": "재생의 성배", "desc": "매 라운드 전원 체력 +3"},
	"radiance": {"name": "저주의 등불", "desc": "전투 시작 시 적 전체 취약"},
}
const IDS := ["vigor", "vital", "armor", "regen", "radiance"]

static func get_def(id: String) -> Dictionary:
	return TABLE[id]
