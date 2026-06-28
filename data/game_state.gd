extends Node
## 전역 상태(오토로드). 버전 + 거둔 영혼 로스터/사연(전투 사이 영구 보존).

const VERSION := "v0.5"  ## 빌드 버전(타이틀 표기) — 빌드마다 올릴 것

## 거둔 영혼 목록. 각 항목: {job, name, lore, level}.
## 시작 파티 3인은 첫 실행 시 시딩. 전투는 앞 3인을 파티로 사용(팀빌더는 다음 슬라이스).
var roster: Array[Dictionary] = []
## 거두며 해금한 '그날 밤의 증언' 조각.
var story_fragments: Array[String] = []

func _ready() -> void:
	if roster.is_empty():
		roster = [
			{"job": Jobs.KNIGHT, "name": "기사", "lore": "왕을 끝까지 지키려다 성문 앞에서 스러진 근위병.", "level": 1},
			{"job": Jobs.PLAGUE, "name": "독술사", "lore": "역병을 막으려다 역병의 일부가 된 궁정 약사.", "level": 1},
			{"job": Jobs.HEADSMAN, "name": "처형인", "lore": "마지막 명령으로 동료의 목을 친 뒤 스스로 무너진 형리.", "level": 1},
		]

## 영혼을 로스터에 추가 + 사연 조각 해금.
func bind_soul(entry: Dictionary) -> void:
	roster.append(entry)
	if entry.has("lore") and entry.lore != "":
		story_fragments.append(entry.lore)
