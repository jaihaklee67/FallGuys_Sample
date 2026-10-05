# FallGuys_Sample

UEFN(Unreal Editor for Fortnite)으로 만든 폴가이즈 스타일 장애물 레이스 맵입니다.
MCP(Claude)와 함께 기획, 레벨 디자인, Verse 코드, 사운드, UI를 만든 결과물이고, 강의 자료의 기준 완성본으로 씁니다.

## 게임 요약

- 제한 시간 5분 타임어택, 플레이어마다 따로 골인
- 체크포인트 4개, 시소·플리퍼·주먹·에어벤트·호버패드 등 장애물
- 실시간 순위 HUD, 결과 화면(순위·걸린 시간 / TIME OVER!), 마지막 10초 알람
- 직접 만든 배경음악과 효과음(wav)

## 폴더 구성

| 폴더 / 파일 | 설명 |
|---|---|
| `FallGuys_Sample.uefnproject` | UEFN 프로젝트 파일 (이 폴더를 UEFN에서 열면 됩니다) |
| `Content/` | 레벨(`FallGuys_Sample.umap`), Verse 코드(`*.verse`), 가져온 오디오(`Audio/`), UI 이미지(`UI/`, `Italic/`) |
| `docs/` | 구조 정리 문서, 3강 계획안, 강의 슬라이드 |
| `audio_source/` | 효과음과 배경음악 wav 원본 (UEFN으로 가져오기 전 파일) |

## Verse 코드 (Content/)

- `race_manager.verse` : 타이머, 골인 감지와 기록, 체크포인트 진행도, 실시간 순위, 결과 화면, 알람, 배경음악
- `flipper_knockback.verse` : 플리퍼, 기둥, 주먹 튕김
- `seesaw_controller.verse` : 시소와 범퍼 기둥
- `sfx_manager.verse` : 리스폰, 낙사, 체크포인트, 에어벤트 소리
- `minimap_manager.verse` : 미니맵에 플레이어별 색깔 동그라미 표시

자세한 설명은 [docs/FallGuys_구조정리.md](docs/FallGuys_구조정리.md)를 참고하세요.

## 열어볼 때 주의

- UEFN에서 프로젝트를 열면 로컬 캐시(`Saved/`, `Intermediate/` 등)가 새로 만들어집니다. 이 폴더들은 저장소에 포함하지 않았습니다.
- 세션 시작 때 검증 창이 뜨면 `Run Validation Fix-up`이 Audio Player의 소리 연결을 지울 수 있으니 주의하세요.
- 2인 이상 멀티플레이와 모바일 화면은 아직 충분히 검증하지 못했습니다.
