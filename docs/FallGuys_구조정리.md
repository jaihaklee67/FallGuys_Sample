# FallGuys_Sample 구조 정리 (수업 자료)

UEFN으로 만든 폴가이즈 스타일 장애물 레이스 맵의 구성을 한 문서로 정리했습니다.
"무엇이 어디에 있고, 어떤 파일이 무슨 일을 하고, 효과음은 어떻게 연결되는지"를 따라가며 볼 수 있습니다.

> 이 문서의 내용은 코드와 에디터 설정을 직접 확인해서 쓴 것입니다.
> 다만 **멀티플레이(2인 이상) 동작과 일부 UI 위치는 아직 직접 플레이로 확인하지 못했습니다.** 마지막 장의 체크리스트를 참고하세요.

---

## 1. 게임 흐름

1. 플레이어가 스타트 구역에서 시작합니다. 기본 카운트다운 3초 뒤 **GO!** 소리가 나며 레이스가 시작됩니다.
2. 제한 시간은 **5분**입니다. 화면 위에 큰 카운트다운이 돌고, 남은 시간이 60초 이하이면 빨간색이 됩니다.
3. 코스에는 체크포인트 4개와 여러 장애물(플리퍼, 기둥, 주먹, 시소, 에어벤트 타워, 호버 패드 등)이 있습니다.
4. 플레이어마다 따로 골인합니다. 결승 아치 아래를 지나면 골인으로 인정하고, 골인한 순간의 기록을 고정합니다.
5. **모든 플레이어가 골인하거나 5분이 지나면** 결과 화면(순위와 걸린 시간 또는 TIME OVER!)이 7초 뜨고 게임이 끝납니다.
6. 마지막 10초에는 아직 골인하지 못한 플레이어에게 1초마다 알람이 울립니다.

## 2. 레벨(에디터) 구성

아웃라이너의 폴더 기준입니다.

| 폴더 | 들어 있는 것 |
|---|---|
| `GameFlow/Start` | `Spawner_1~16`(8개씩 2줄, 모두 코스 쪽을 봄), `HUD_Controller`(기본 HUD 숨김), `status_popup`(추락, 리스폰 화면) |
| `GameFlow/Checkpoints` | `Checkpoint_1~4` |
| `GameFlow/Finish` | `race_manager`, `Finish_EndGame`, `Finish_Trigger`, `Finish_Score` |
| `GameFlow/Sound` | `music_manager`, `sfx_manager`, Audio Player 13개(아래 표), Audio Mixer 4개(`Mix_Music_Soft/Deep`, `Mix_SFX_Soft/Deep`) |
| `GameFlow/EndCamera` | `end_camera`, 고정 위치 카메라 `EndCam_1~16`(플레이어마다 하나) |
| `SeesawHazards` | 시소 위 범퍼 기둥 8개(`SS_Pole_1~8`), 바운서 2개(`BNC_SS_1/2`) |

### 사운드 장치 이름과 역할 (`GameFlow/Sound`)

| 장치 이름 | 소리 파일 | 재생 시점 | 들리는 대상 | 음량 |
|---|---|---|---|---|
| `BGM_Main` | `music_playgame_loop` (66.68초, 맨 앞뒤 0.35초 페이드, 66.33초마다 다음 바퀴를 시작) | 게임 시작, 홀수 바퀴 제외 짝수 바퀴, 중간 입장 | 각 플레이어 | 1.8 |
| `BGM_Main_B` | `music_playgame_loop` | `BGM_Main`과 번갈아 쓰는 홀수 바퀴(바퀴 사이가 겹쳐 이어짐) | 각 플레이어 | 1.8 |
| `BGM_Low` | `music_playgame_loop` | 골인/챔피언 음악이 나오는 30초 동안 배경음악 대신 | 골인한 사람 | 0.55 |
| `SFX_Start_GO` | `sfx_countdown_go` | 레이스 시작 | 전체 | 1.0 |
| `SFX_Checkpoint` | `sfx_checkpoint` | 체크포인트를 처음 밟을 때 | 밟은 사람 | 1.0 |
| `SFX_Bounce` | `sfx_bounce` | 플리퍼, 기둥, 주먹에 맞아 튕길 때 | 맞은 사람 | 1.0 |
| `SFX_Respawn` | `sfx_respawn` | 죽었다가 다시 살아날 때 | 그 사람 | 1.0 |
| `SFX_Fall` | `sfx_fall` | 죽는 순간(낙사 포함) | 그 사람(화면 기준 재생) | 0.8 |
| `SFX_Wind` | `sfx_wind` | 에어벤트 바람 구역에 들어갈 때 | 그 사람 | 1.0 |
| `SFX_Alarm` | `sfx_alarm` | 마지막 10초, 1초마다 | 아직 골인 못한 사람 | 0.65 |
| `Music_Goal` | `music_goal_in` | 시간 안에 골인(1등 제외) | 골인한 사람 | 2.0 |
| `Music_Champion` | `music_champion` | 1등으로 골인(골인 음악 대신) | 1등인 사람 | 1.8 |
| `Music_TimeOver` | `music_timeover` | 제한 시간 종료 | 골인 못한 사람 | 2.0 |

소리 파일은 `FallGuys_Sample/Audio` 폴더에 있고, 원본 wav는 `FallGuys_Test/sfx/`에 보관되어 있습니다.

## 3. Verse 파일 9개 (장치 7개 + 공통 타입 1개 + 음악 1개)

- `common_types.verse`: 여러 장치가 같이 쓰는 타입(`player_snap`)
- `music_manager.verse`: 배경음악 시작, 반복(A, B 두 Audio Player를 번갈아 써서 바퀴 사이를 겹쳐 이음), 골인 음악 중 줄이기, 정지, 게임 종료 직전 소리 줄이기(Audio Mixer 단계별). `race_manager`가 호출한다.
- `end_camera.verse`: 골인하거나 타임오버가 되면 그 플레이어의 카메라가 캐릭터 가까이 다가가며 아래에서 올려다보는 각도로 캐릭터 둘레를 2바퀴 돈다. 2바퀴 도는 시간은 `race_manager`의 `ResultSeconds`(7초)와 같아서 게임이 끝날 때 딱 맞는다. 플레이어마다 `EndCam` 장치 하나를 배정해 Verse가 `MoveTo`로 옮긴다. 먼저 골인한 플레이어는 2바퀴를 돈 뒤 멈춘 각도로 캐릭터를 따라간다. UI는 그대로다.
- `status_popup.verse`: 추락하면 `ELIMINATED`, 되살아나기 직전 1.5초 동안 `RESPAWN` 이미지를 화면 가운데에 띄운다(죽어 있는 시간은 로그 기준 3.75초).
- 아래 `race_manager` 설명 중 음악 관련 부분은 `music_manager`가 맡는다.


### 3.1 `race_manager.verse` (514줄) — 레이스 전체 진행

| 하는 일 | 핵심 부분 |
|---|---|
| 골인 감지 | `WatchFinishLine`이 0.05초마다 결승 아치 구역(상자)에 들어온 플레이어를 찾아 `RegisterFinish`를 호출 |
| 기록 | `FinishedRank`(순위), `FinishedLeft`(골인 순간 남은 시간), `FinishedSpent`(걸린 시간) |
| 상단 타이머 | `RunTimer` → `AddMissingTimers` → `UpdateTimers`/`SetClock`. `ui_time` 이미지 위에 숫자 글자 이미지 5칸(`Bubble` 폴더)을 얹어 갱신. 골인한 뒤에도 계속 흐름 |
| 체크포인트 | 체크포인트 4개의 `FirstActivationPerAgentEvent`를 받아 플레이어별 개수를 셈 |
| 현재 순위 | `RankOf`: 골인한 사람이 앞 → 체크포인트를 많이 지난 사람 → 코스 앞쪽(Y 큰) 사람 |
| 왼쪽 아래 순위 박스 | `ui_ranking` 이미지 위에 `3RD / 8` 글자 이미지를 얹음. `UpdateInfo`/`SetRank`가 0.2초마다 갱신 |
| 체크포인트 통과 | `ShowCheckpointPopup`이 `ui_checkpoint`를 화면 가운데에 2초 표시 |
| 알람 | 남은 시간이 `AlarmSeconds` 이하로 1초 줄 때마다 `PlayAlarm` |
| 결과 화면 | 골인: `BuildGoalCanvas`(`ui_goal_in` + `1ST PLACE`, `TIME`), 타임오버: `BuildTimeOverCanvas`(`ui_timeover` + 옅은 붉은색), 골인 후 대기 문구는 `ShowResultFor` |
| 게임 종료 | `EndRace`가 결과를 보여주고 End Game Device를 작동 |

주요 설정값:

| 이름 | 기본값 | 의미 |
|---|---|---|
| `TotalSeconds` | 300 | 제한 시간(초) |
| `ResultSeconds` | 7 | 결과 화면 표시 시간 |
| `WarnSeconds` | 60 | 이 이하이면 타이머가 빨간색 |
| `AlarmSeconds` | 10 | 알람 시작 시점 |
| `PlayMusic` | true | 배경음악 사용 여부 |
| `CheckpointTotal` | 4 | 화면의 `n / 4` 분모 |
| `TimerBoxWidth` / `TimerDigitHeight` | 460 / 66 | 상단 타이머 이미지 폭, 숫자 높이 |
| `RankBoxWidth` / `RankNumSize` / `RankSuffixSize` / `RankTotalSize` / `RankTextYRatio` | 300 / 60 / 30 / 34 / 0.65 | 순위 박스와 글자 크기, 숫자 세로 위치 |
| `CheckpointPopupWidth` / `GoalImageWidth` / `ResultImageWidth` / `WaitingTextSize` / `TimeOverTintOpacity` | 760 / 860 / 1000 / 48 / 0.22 | 팝업과 결과 화면 크기, 타임오버 붉은빛 진하기 |
| `HudScale` | 1.0 | 화면 UI 전체 배율(작은 화면에서 줄이기) |
| `FinishX/Y/Z Min/Max` | (아치 구역) | 결승선 인식 상자(cm) |

### 3.2 `flipper_knockback.verse` (336줄) — 플리퍼, 기둥, 주먹 튕김

- 플리퍼 4개, 기둥 6개, 주먹 6개와 플레이어의 거리를 틱마다 검사합니다.
- 회전판 위 기둥 6개는 `PulsePole`이 움직입니다. 회전판(20초에 한 바퀴)과 같은 속도로 돌면서 8초 주기로 중심 쪽으로 모였다가 퍼지고, 중심에서의 거리는 파란 바닥 범위(660~1280cm) 안으로 제한됩니다. 기존 `PM_Turntable_Pole_1~6` 무버는 "시작 시 움직임"을 꺼 두었습니다.
- 닿으면 **바운서 장치를 플레이어 발밑으로 순간이동**시켜 위로 튕기는 방식입니다. 캐릭터를 직접 순간이동시키면 카메라가 리셋되기 때문에 이 방법을 씁니다.
- 틱 시작에 플레이어 위치를 **한 번만** 읽어 모든 장애물이 같이 씁니다(`RefreshSnaps`).
- 주요 설정값: `TickSeconds` 0.03(검사 간격), `ActiveSeconds` 0.35(바운서가 그 자리에 머무는 시간).

### 3.3 `seesaw_controller.verse` (278줄) — 시소와 범퍼 기둥

- 시소 2개를 사인 곡선으로 ±28° 기울입니다(주기 4.2초와 3.4초, 위상 0도와 180도).
- 시소 위 기둥 8개: 안쪽 4개(반지름 1300cm, 주기 8초), 바깥쪽 4개(반지름 2200cm, 주기 13.5초, 반대 방향)가 시소 중심을 돕니다.
- 기둥은 `MoveTo`로 움직이고, 닿으면 바깥쪽과 이동 방향을 섞어서 튕깁니다.

### 3.4 `sfx_manager.verse` (123줄) — 리스폰, 낙사, 체크포인트, 바람 소리

- 플레이어가 "살아 있음 → 쓰러짐"으로 바뀌면 `SFX_Fall`, "쓰러짐 → 살아 있음"으로 바뀌면 `SFX_Respawn`을 재생합니다(0.25초마다 확인).
- 에어벤트 7개의 크기(스케일)로 바람 구역 원기둥을 계산해서, 그 안에 들어간 플레이어에게 바람 소리를 냅니다(0.1초마다, 1.5초 쿨다운).

## 4. 효과음이 소리 나는 구조 (가장 많이 헤맸던 부분)

### 4.1 올바른 방법: 직접 만든 wav + Audio Player + `Play(플레이어)`

1. wav 파일을 Content Browser의 `FallGuys_Sample/Audio`로 끌어다 놓는다.
2. Audio Player 장치를 놓고 `Audio`에 그 파일을 지정한다.
   - `Can Be Heard By`: `Instigator Only`, `Play Location`: `Instigating Player`
   - `Enable Volume Attenuation` / `Enable Spatialization`: 끔
3. Verse에서 `@editable` 변수로 장치를 받아서 `Sfx.Play(Agent)`로 재생한다.

### 4.2 안 됐던 방법들 (참고)

| 시도 | 결과 |
|---|---|
| 라이브러리의 Stinger, Trap 소리를 Audio Player나 라디오에 지정 | 소리 안 남. 라디오는 정해진 82곡(음악, 환경음)만 재생 |
| 라디오로 효과음 대체 | 긴 루프라 짧은 효과음에 맞지 않음 |
| 추락사 소리를 `Instigating Player`(캐릭터 위치)로 재생 | 죽는 순간에는 캐릭터가 없어 안 들림 → `Local Player`(화면 기준)로 해결 |
| 카운트다운 3, 2, 1 소리 | 카운트다운 중에는 Verse가 실행되지 않아 불가 → GO 소리만 구현 |

### 4.3 알아두면 좋은 점

- Audio Player의 `volume`은 1.0을 넘는 값(2.0 등)도 실제로 적용됩니다.
- Verse의 `OnBegin`은 라운드 시작 시점에 실행됩니다.

## 5. 장치 참조 연결하기

Verse 장치의 `@editable` 칸(예: `Music`, `FinishSting`, `Checkpoint1~4`)은 에디터에서 Details 패널의 칸에 레벨의 장치를 드래그하거나 선택해서 연결합니다.
배열 형태(`[]device`)는 한 번에 많은 장치를 다루기 편하지만, 이 프로젝트처럼 자동화 도구로 만들 때는 단일 변수로 나누어 연결했습니다.

## 6. UI 구조 (화면)

| 위치 | 내용 | 코드 |
|---|---|---|
| 위쪽 가운데 | `ui_time` 이미지 + 남은 시간(글자 이미지, 1분 미만이면 빨강) | `AddMissingTimers`, `SetClock` |
| 화면 가운데 | 체크포인트 통과 이미지(2초) | `ShowCheckpointPopup` |
| 왼쪽 아래 | `ui_ranking` 이미지 + `1ST / 4`(순위 숫자는 크게, ST와 인원수는 작게) | `AddMissingTimers`, `SetRank` |
| 화면 가운데 | 골인 화면, 타임오버 화면(붉은빛), 골인 후 `WAITING FOR OTHERS N LEFT` | `BuildGoalCanvas`, `BuildTimeOverCanvas` |
| 화면 가운데 | 추락 `ELIMINATED`, 되살아나기 직전 `RESPAWN` | `status_popup.verse` |

- UEFN UI의 글자(`text_block`)는 글꼴을 고를 수 없어서, 시간, 순위, 결과 글자는 글꼴 이미지(`Bubble` 폴더: 숫자, 콜론, 슬래시, 영문 대문자)를 한 글자씩 끼워 만듭니다. 예전 `Italic` 폴더와 `result_success`, `result_fail`은 지금은 쓰지 않습니다.
- 이미지 안에 이미 들어 있는 글자(`TIME`, `Ranking`, `CHECKPOINT!` 등)는 그대로 두고, 코드가 넣는 숫자와 문구만 글꼴 이미지를 씁니다.
- 화면 크기에 따라 글자가 너무 크면 `HudScale`을 줄입니다.

## 7. 성능에 대해

- 반복 감시(결승선 0.05초, 튕김 0.03초, 시소 0.03초, 바람 0.1초)가 여럿입니다.
- 장애물마다 모든 플레이어의 위치를 따로 읽던 것을, 틱 시작에 한 번만 읽도록 바꿨습니다. 읽는 횟수가 장애물 수만큼 줄어듭니다.
- **실제 서버 부하는 측정하지 못했습니다.** 인원이 많은 테스트에서 프레임이 떨어지는지 확인이 필요합니다.

## 8. 아직 확인하지 못한 것 (테스트 체크리스트)

- [ ] 2명 이상이 동시에 플레이할 때 순위, 체크포인트 표시, 결과 화면이 맞는지
- [ ] 코스 진행 방향이 Y축 증가 방향이라는 가정(`RankOf`의 보조 기준)이 맞는지
- [ ] 중간에 들어온 플레이어가 배경음악을 듣는지
- [ ] 골인하고 기다리는 동안 `FINISHED - N LEFT` 표시가 맞는지
- [ ] 작은 화면(모바일)에서 UI가 잘리지 않는지 (`HudScale` 조절)
- [ ] 주먹, 플리퍼, 시소 기둥 튕김이 정리(성능 개선) 후에도 그대로인지
- [ ] 마지막 10초 알람이 배경음악과 어울리는 음량인지
- [ ] 발행을 한다면 맵 이름, 설명, 썸네일, 최대 인원, 연령 등급 설문 준비

## 9. 수업에 쓰는 순서 제안

1. **레벨 구성**: 스타트, 체크포인트, 결승선 장치 배치 (코드 없이)
2. **Verse 기초**: `creative_device`, `@editable`, 이벤트 구독 → `race_manager`의 골인 감지와 타이머만 떼어서
3. **UI**: `text_block`, `canvas`로 타이머와 순위 띄우기
4. **사운드**: wav 가져오기 → Audio Player → `Play(Agent)`
5. **장애물**: 바운서 순간이동 방식 소개(코드가 길어 시연 위주)
