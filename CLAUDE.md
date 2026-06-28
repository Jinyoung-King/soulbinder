# 프로젝트: soulbinder (Godot 4 게임)

## 게임 개요
**영혼 수집·육성 턴제 RPG.** "영혼을 엮는 자(강령술사)"가 쓰러진 자의 영혼을 거두어
팀을 짜고, 수동 턴제 전투로 스토리를 헤쳐나간다. 영혼마다 생전 직업(타입)·사연(스토리)·
고유 기술이 있어, 수집 한 번이 곧 캐릭터+서사+팀 옵션을 동시에 더한다(확장성 최고).
4기둥: 📖스토리 · 🌿경우의수(팀조합·전술·분기) · ⛏노가다(수집·육성) · 🎰중독성.

핵심 설계 원칙(crux-mage 교훈): **경우의수=의미 있는 선택**이 곧 플레이어의 행위 →
관전자 문제 회피. 빌드/팀이 *플레이를 실제로 바꾸도록*.

## 환경
- Godot 4.6.3, GDScript — 로컬 godot 바이너리는 별도(이 환경엔 미설치 시 다운로드).
- **가로(landscape) 1280×720**, 웹(HTML5) 타깃. 응답·주석 한국어.
- 헤드리스 검증: `godot --headless --import --path .` 후 `godot --headless --path . <scene> --quit-after N`.
  ※ export(웹빌드) 성공 ≠ 파스 검증 — 반드시 헤드리스 씬 실행으로 SCRIPT/Parse 에러 확인.
- 시각 검증: WSLg + `--rendering-driver opengl3`(--headless 빼기)로 오프스크린 렌더 PNG 캡처 가능.
- 웹 배포: main 푸시 → GitHub Actions(.github/workflows/deploy.yml) → gh-pages. 버전은 GameState.VERSION.
- 아트는 단색 도형 placeholder부터(crux처럼). 검증 먼저, 확장 나중.

## 구조(초기)
- scenes/ui/ — title 등 화면 (.tscn + .gd)
- scenes/ui/ui_kit.gd — 공용 UI 스타일(class_name UIKit): panel()/button_box()/style_button()
- data/ — game_state.gd(오토로드) 외 Resource 정의 차차 추가
- assets/fonts/ — NotoSansKR

## 작업 규칙
- 요청 범위만, 단일 사용 코드에 추상화 금지. 변경 후 헤드리스 검증 + 한 줄 실행안내.
- 큰 기능은 작은 수직 슬라이스로 검증 먼저(crux 교훈).
