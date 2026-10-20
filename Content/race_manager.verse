using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }
using { /jaihaklee@fortnite.com/FallGuys_Sample/UI }
using { /jaihaklee@fortnite.com/FallGuys_Sample/Bubble }
using { /Fortnite.com/Game }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

# 레이스 진행 관리: 골인 순위와 기록을 재고, 골인 순간 폭죽 연출을 하고,
# 모두 골인하거나 제한시간이 끝나면 화면 가운데에 순위와 걸린 시간만 보여주고 게임을 끝낸다.
glyph_def := struct:
    Image:texture
    Aspect:float

# 0 이상 1 이하의 실수 (color_block의 진하기 타입).
opacity_range := type{_X:float where 0.0 <= _X, _X <= 1.0}

timer_widgets := class:
    Canvas:canvas
    TensMin:texture_block
    OneMin:texture_block
    Colon:texture_block
    SecTens:texture_block
    SecOnes:texture_block
    RankTens:texture_block
    RankOnes:texture_block
    SufA:texture_block
    SufB:texture_block
    RankSlash:texture_block
    TotTens:texture_block
    TotOnes:texture_block

# 골인한 플레이어 화면 아래에 뜨는 "남은 사람 수" 안내.
result_wait := class:
    Canvas:canvas
    Tens:texture_block
    Ones:texture_block

race_manager := class(creative_device):

    # 결승선 트리거 (아치 바로 뒤).
    @editable
    FinishTrigger:trigger_device = trigger_device{}

    # 게임을 끝내는 End Game 디바이스.
    @editable
    EndGame:end_game_device = end_game_device{}

    # 승자 판정용 점수 디바이스. 점수는 화면에 보여주지 않는다.
    @editable
    Score:score_manager_device = score_manager_device{}

    # 배경음악 담당 장치. 게임 시작, 중간 입장, 골인 음악 중 줄이기, 종료 때 정지를 맡긴다.
    @editable
    MusicManager:music_manager = music_manager{}

    # 골인하거나 시간이 끝난 플레이어의 카메라가 캐릭터 주변을 도는 연출을 맡는 장치.
    @editable
    EndCamera:end_camera = end_camera{}

    # 배경음악을 틀지 여부. 효과음만 따로 확인할 때 false로 둔다.
    @editable
    PlayMusic:logic = true

    # 시간 안에 골인한 플레이어에게만 들리는 골인 음악(Audio Player, Instigator Only).
    @editable
    GoalMusic:audio_player_device = audio_player_device{}

    # 제한시간 안에 골인하지 못한 플레이어에게만 들리는 타임오버 음악.
    @editable
    TimeOverMusic:audio_player_device = audio_player_device{}

    # 남은 시간이 10초 이하일 때 1초마다 울리는 알람. 아직 골인하지 않은 플레이어에게만 들린다.
    @editable
    AlarmSfx:audio_player_device = audio_player_device{}

    @editable
    AlarmSeconds:int = 10

    # 1등으로 골인한 플레이어에게만 들리는 챔피언 음악(Audio Player, Instigator Only). 1등은 골인 음악 대신 이 곡을 듣는다.
    @editable
    ChampionMusic:audio_player_device = audio_player_device{}

    # 게임 시작(카운트다운이 끝나는 순간)에 모든 플레이어에게 울리는 GO 효과음.
    @editable
    StartSfx:audio_player_device = audio_player_device{}

    # 체크포인트 4개: 처음 밟을 때마다 화면 아래 진행 표시의 CHECKPOINT 숫자를 올린다.
    @editable
    Checkpoint1:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint2:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint3:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint4:player_checkpoint_device = player_checkpoint_device{}

    # 코스에 있는 체크포인트 개수 (진행 표시의 "2 / 4" 에서 분모).
    @editable
    CheckpointTotal:int = 4

    # 순위별 승자 판정 점수. 1등부터 차례대로.
    @editable
    PointsByRank:[]int = array{100, 80, 65, 50, 40, 30, 20, 10}

    @editable
    LastPlacePoints:int = 5

    # 라운드 제한시간 (초). 상단 카운트다운과 결과 시간 계산에 모두 쓴다.
    @editable
    TotalSeconds:float = 300.0

    # 결과 화면을 보여주는 시간 (초). 그 다음 게임이 끝난다.
    @editable
    ResultSeconds:float = 7.0

    # 남은 시간이 이 값(초) 이하가 되면 상단 카운트다운 글자가 빨간색이 된다.
    @editable
    WarnSeconds:float = 60.0

    # 상단 타이머 이미지(ui_time)의 가로 크기와 그 안의 시간 글자 이미지 높이.
    @editable
    TimerBoxWidth:float = 460.0

    @editable
    TimerDigitHeight:float = 66.0

    # 왼쪽 아래 순위 이미지(ui_ranking)의 가로 크기, 그 안의 순위 숫자 크기, 숫자 옆 ST/ND/RD/TH 글자 크기.
    @editable
    RankBoxWidth:float = 300.0

    @editable
    RankNumSize:float = 60.0

    @editable
    RankSuffixSize:float = 30.0

    # 전체 인원수 숫자(슬래시 뒤)의 크기. 순위 숫자보다 작게 보여준다. 슬래시는 이 크기의 1.2배.
    @editable
    RankTotalSize:float = 34.0

    # 순위 숫자의 세로 위치: ui_ranking 이미지 맨 위에서 숫자 중심까지의 비율(0=맨 위, 1=맨 아래). 클수록 숫자가 아래로 내려간다.
    @editable
    RankTextYRatio:float = 0.65

    # 체크포인트를 처음 밟을 때 뜨는 이미지(ui_checkpoint)의 가로 크기와 표시 시간(초).
    @editable
    CheckpointPopupWidth:float = 760.0

    @editable
    CheckpointPopupSeconds:float = 2.0

    # 골인 화면(ui_goal_in)과 타임오버 화면(ui_timeover) 이미지의 가로 크기.
    @editable
    ResultImageWidth:float = 1000.0

    # 화면 UI 전체 크기 배율. 작은 화면(모바일 등)에서 글자가 너무 크거나 구석에서 잘리면 0.7 정도로 줄인다. 1.0이 기본.
    @editable
    HudScale:float = 1.0

    # 골인한 뒤 결과 화면 아래에 뜨는 "WAITING FOR OTHERS  N LEFT" 글자 이미지 높이.
    @editable
    WaitingTextSize:float = 48.0

    # 골인 화면(ui_goal_in) 이미지의 가로 크기. 타임오버 화면은 ResultImageWidth를 쓴다.
    @editable
    GoalImageWidth:float = 860.0

    # 타임오버 화면에서 게임 화면 전체에 깔리는 붉은색의 진하기 (0=없음, 1=완전히 붉은색).
    @editable
    TimeOverTintOpacity:float = 0.22

    # 결승선 인식 상자 (cm). 최종 아치의 왼쪽 기둥에서 오른쪽 기둥 바깥까지 전체 폭(X -625~1999), 아치 앞뒤(Y), 바닥부터 아치 위까지(Z)이다.
    @editable
    FinishXMin:float = -625.0

    @editable
    FinishXMax:float = 1999.0

    @editable
    FinishYMin:float = 78400.0

    @editable
    FinishYMax:float = 79500.0

    @editable
    FinishZMin:float = 8450.0

    @editable
    FinishZMax:float = 9736.0

    var RaceStart:float = -1.0
    var TimerWidgets:[player]timer_widgets = map{}
    var FinishedRank:[agent]int = map{}
    var FinishedSpent:[agent]int = map{}
    var LastFinisher:?agent = false
    var GameEnded:logic = false
    var ResultCanvases:[player]canvas = map{}
    var ResultWaits:[player]result_wait = map{}
    var CheckpointCount:[player]int = map{}
    var CheckpointShowing:[player]logic = map{}

    Msg<localizes>(Text:string):message = "{Text}"

    OnBegin<override>()<suspends>:void =
        # 0 = 무제한. 한 명이 통과해도 다른 플레이어가 계속 골인할 수 있어야 한다.
        FinishTrigger.SetMaxTriggerCount(0)
        FinishTrigger.TriggeredEvent.Subscribe(OnFinish)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
        Checkpoint1.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint2.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint3.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint4.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        spawn{WatchFinishLine()}
        if (PlayMusic?):
            MusicManager.Start()
        MusicManager.ResetFade()
        if (Manager := Self.GetSimulationEntity[].GetFortRoundManager[]):
            Manager.SubscribeRoundStarted(OnRoundStart)
            Print("race_manager: subscribed to round start")
        else:
            Print("race_manager: no round manager, starting now")
            OnRoundStart()


    # 라운드가 시작하면 기록을 초기화하고 제한시간이 지나면 결과를 보여준다.
    OnRoundStart()<suspends>:void =
        # 이전 라운드 끝에 줄였던 소리를 원래대로 되돌린다.
        MusicManager.ResetFade()
        EndCamera.StopAll()
        set RaceStart = GetSimulationElapsedTime()
        for (Player : GetPlayspace().GetPlayers()):
            StartSfx.Play(Player)
        set CheckpointCount = map{}
        set FinishedRank = map{}
        set FinishedSpent = map{}
        set LastFinisher = false
        set GameEnded = false
        RunTimer()

    OnFinish(MaybeAgent:?agent):void =
        if (Agent := MaybeAgent?):
            RegisterFinish(Agent)

    # 아치 통로 구역(상자)을 지나는 플레이어를 직접 감지한다. 트리거 디바이스의 감지 범위가 좋아서 놓치는 것을 막기 위해 0.05초마다 위치를 확인한다.
    WatchFinishLine()<suspends>:void =
        loop:
            Sleep(0.05)
            if (GameEnded = false, RaceStart >= 0.0):
                for (Player : GetPlayspace().GetPlayers()):
                    if (not FinishedRank[Player], Char := Player.GetFortCharacter[]):
                        P := Char.GetTransform().Translation
                        if (P.X > FinishXMin, P.X < FinishXMax, P.Y > FinishYMin, P.Y < FinishYMax, P.Z > FinishZMin, P.Z < FinishZMax):
                            RegisterFinish(Player)

    RegisterFinish(Agent:agent):void =
        if (GameEnded = false, RaceStart >= 0.0, not FinishedRank[Agent]):
            Elapsed := GetSimulationElapsedTime() - RaceStart
            # 화면 위 카운트다운과 같은 계산: 남은 시간을 올림해서 초 단위로 기록한다.
            Left := if (R := Ceil[TotalSeconds - Elapsed], R > 0) then R else 0
            Rank := FinishedRank.Length + 1
            # 결과 화면에 보여줄 걸린 시간: 출발부터 결승선까지 지난 시간(초, 내림).
            Spent := if (S := Floor[Elapsed]) then S else 0
            if (set FinishedRank[Agent] = Rank, set FinishedSpent[Agent] = Spent):
                Print("race_manager: finished rank {Rank}, elapsed {Elapsed} sec, result shows {FormatClock(Spent)}, top clock frozen at {FormatClock(Left)}")
            set LastFinisher = option{Agent}
            Points := if (P := PointsByRank[Rank - 1]) then P else LastPlacePoints
            Score.SetScoreAward(Points)
            Score.Activate(Agent)
            spawn{PlaySting(Agent)}
            UpdateTimers(Left)
            UpdateInfo()
            # 골인한 플레이어에게는 결과 화면을 바로 보여준다(다른 사람이 끝날 때까지 남은 인원도 같이 표시).
            if (Player := player[Agent]):
                ShowResultFor(Player)
                EndCamera.Start(Player, ResultSeconds)
            CheckAllFinished()

    # 골인한 플레이어에게만 골인 음악을 틀어준다. 1등은 챔피언 음악, 나머지는 골인 음악이고(겹치지 않게 하나만),
    # 그동안 그 플레이어의 배경음악은 작은 소리로 바뀌었다가 끝나면 되돌아온다.
    PlaySting(Agent:agent)<suspends>:void =
        if (Rank := FinishedRank[Agent], Rank = 1):
            ChampionMusic.Play(Agent)
        else:
            GoalMusic.Play(Agent)
        if (Player := player[Agent]):
            MusicManager.DuckFor(Player)

    OnPlayerRemoved(Player:player):void =
        CheckAllFinished()

    # 중간에 들어온 플레이어도 배경음악을 듣게 한다.
    OnPlayerAdded(Player:player):void =
        if (PlayMusic?, GameEnded = false):
            MusicManager.PlayFor(Player)

    OnCheckpoint(Agent:agent):void =
        if (Player := player[Agent], RaceStart >= 0.0):
            Count := if (C := CheckpointCount[Player]) then C + 1 else 1
            if (set CheckpointCount[Player] = Count):
                Print("race_manager: checkpoint {Count}/{CheckpointTotal}")
            UpdateInfo()
            if (GameEnded = false):
                spawn{ShowCheckpointPopup(Player)}

    # 체크포인트를 처음 밟았을 때 화면 위쪽에 안내 이미지를 잠깐 보여준다.
    ShowCheckpointPopup(Player:player)<suspends>:void =
        Showing:logic = if (S := CheckpointShowing[Player], S = true) then true else false
        if (Showing = false, PlayerUi := GetPlayerUI[Player]):
            Width := CheckpointPopupWidth * HudScale
            Popup := canvas{Slots := array{canvas_slot{
                Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}},
                Offsets := margin{},
                Alignment := vector2{X := 0.5, Y := 0.5},
                SizeToContent := true,
                Widget := texture_block{DefaultImage := ui_checkpoint, DefaultDesiredSize := vector2{X := Width, Y := Width / 1.9324}}}}}
            PlayerUi.AddWidget(Popup)
            if (set CheckpointShowing[Player] = true) {}
            Sleep(CheckpointPopupSeconds)
            if (PlayerUi2 := GetPlayerUI[Player]):
                PlayerUi2.RemoveWidget(Popup)
            if (set CheckpointShowing[Player] = false) {}

    # 아직 골인하지 못한 플레이어에게만 알람을 울린다.
    PlayAlarm():void =
        for (Player : GetPlayspace().GetPlayers()):
            if (not FinishedRank[Player]):
                AlarmSfx.Play(Player)

    # 현재 순위: 골인한 사람이 앞, 그다음은 체크포인트를 많이 지난 사람, 같으면 코스 앞쪽(Y가 큰) 사람이 앞이다.
    RankOf(Player:player):int =
        if (Done := FinishedRank[Player]):
            return Done
        MyCount := if (C := CheckpointCount[Player]) then C else 0
        MyY := if (Char := Player.GetFortCharacter[]) then Char.GetTransform().Translation.Y else -100000.0
        var Ahead:int = FinishedRank.Length
        for (Other : GetPlayspace().GetPlayers()):
            if (Other <> Player, not FinishedRank[Other]):
                OtherCount := if (C := CheckpointCount[Other]) then C else 0
                OtherY := if (Char := Other.GetFortCharacter[]) then Char.GetTransform().Translation.Y else -100000.0
                if (OtherCount > MyCount or (OtherCount = MyCount and OtherY > MyY)):
                    set Ahead += 1
        return Ahead + 1

    # 남아 있는 플레이어가 전부 골인했으면 레이스를 끝낸다.
    CheckAllFinished():void =
        if (GameEnded = false, FinishedRank.Length > 0):
            var Remaining:int = 0
            for (Player : GetPlayspace().GetPlayers()):
                if (not FinishedRank[Player]):
                    set Remaining += 1
            if (Remaining = 0):
                spawn{EndRace()}

    EndRace()<suspends>:void =
        if (GameEnded = false):
            set GameEnded = true
            Print("race_manager: race over, showing results")
            ShowResults()
            # 아직 골인하지 못한 플레이어(타임오버)도 카메라가 캐릭터 주변을 돌기 시작한다. 이미 돌고 있는 플레이어는 그대로 둔다.
            for (Player : GetPlayspace().GetPlayers()):
                EndCamera.Start(Player, ResultSeconds)
            # 결과 화면 시간(ResultSeconds) 안에서, 게임을 끝내기 직전 FadeSeconds 동안 소리를 단계로 줄인다. 총 시간은 바뀔지 않는다.
            Sleep(Max(0.0, ResultSeconds - MusicManager.FadeSeconds))
            MusicManager.FadeOut()
            if (AnyPlayer := GetPlayspace().GetPlayers()[0]):
                EndGame.Activate(AnyPlayer)
            Sleep(5.0)
            MusicManager.Stop()
            HideResults()

    # 화면 위 중앙 카운트다운. 라운드 시작부터 제한시간까지 돌리고, 0이 되면 레이스를 끝낸다.
    RunTimer()<suspends>:void =
        defer:
            HideTimers()
        var LastShown:int = -1
        loop:
            Remaining := TotalSeconds - (GetSimulationElapsedTime() - RaceStart)
            Left := if (R := Ceil[Remaining], R > 0) then R else 0
            AddMissingTimers(Left)
            UpdateInfo()
            if (Left <> LastShown):
                set LastShown = Left
                UpdateTimers(Left)
                if (Left > 0, Left <= AlarmSeconds):
                    PlayAlarm()
            if (Left = 0):
                break
            Sleep(0.2)
        EndRace()

    # 플레이어마다 상단 타이머(ui_time 이미지 + 시간 글자), 체크포인트 진행 줄, 왼쪽 아래 순위 박스(ui_ranking 이미지 + 순위 글자)를 만든다.
    # 글자는 이미지 위에 얹는다. 이미지 안의 글자 칸 중심 위치는 이미지 크기에 대한 비율로 잡는다.
    AddMissingTimers(Left:int):void =
        for (Player : GetPlayspace().GetPlayers()):
            if (not TimerWidgets[Player], PlayerUi := GetPlayerUI[Player]):
                TopCenter := anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0}}
                BottomLeft := anchors{Minimum := vector2{X := 0.0, Y := 1.0}, Maximum := vector2{X := 0.0, Y := 1.0}}
                # 상단 타이머: ui_time(가로:세로 = 2:1)의 어두운 칸 중심은 가로 66%, 세로 57.5% 지점.
                TimerW := TimerBoxWidth * HudScale
                TimerH := TimerW / 2.0
                TimerTop := 16.0 * HudScale
                TimerBg := texture_block{DefaultImage := ui_time, DefaultDesiredSize := vector2{X := TimerW, Y := TimerH}}
                BgSlot := canvas_slot{
                    Anchors := TopCenter,
                    Offsets := margin{Top := TimerTop},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 0.0},
                    ZOrder := 0,
                    Widget := TimerBg}
                # 시간은 귀여운 글자 이미지 5칸 한 줄로 만들고, 이미지 안의 어두운 칸 중심에 둔다.
                DigitH := TimerDigitHeight * HudScale
                TensMin := MakeGlyph('0', DigitH, NamedColors.White)
                OneMin := MakeGlyph('0', DigitH, NamedColors.White)
                Colon := MakeGlyph(':', DigitH, NamedColors.White)
                SecTens := MakeGlyph('0', DigitH, NamedColors.White)
                SecOnes := MakeGlyph('0', DigitH, NamedColors.White)
                ClockRow := stack_box{
                    Orientation := orientation.Horizontal,
                    Slots := array{
                        stack_box_slot{Widget := TensMin},
                        stack_box_slot{Widget := OneMin, Padding := margin{Left := 0.0 - DigitH * 0.06}},
                        stack_box_slot{Widget := Colon, Padding := margin{Left := 0.0 - DigitH * 0.06}},
                        stack_box_slot{Widget := SecTens, Padding := margin{Left := 0.0 - DigitH * 0.06}},
                        stack_box_slot{Widget := SecOnes, Padding := margin{Left := 0.0 - DigitH * 0.06}}}}
                Slot := canvas_slot{
                    Anchors := TopCenter,
                    Offsets := margin{Left := 0.16 * TimerW, Top := TimerTop + 0.575 * TimerH},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 0.5},
                    ZOrder := 1,
                    Widget := ClockRow}
                # 왼쪽 아래 순위 박스: ui_ranking(가로:세로 = 1.2625:1)의 분홍 칸 중심은 가로 53%, 세로는 RankTextYRatio(기본 65%) 지점.
                RankW := RankBoxWidth * HudScale
                RankH := RankW / 1.2625
                RankMargin := 24.0 * HudScale
                RankBg := texture_block{DefaultImage := ui_ranking, DefaultDesiredSize := vector2{X := RankW, Y := RankH}}
                RankBgSlot := canvas_slot{
                    Anchors := BottomLeft,
                    Offsets := margin{Left := RankMargin, Top := 0.0 - RankMargin},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.0, Y := 1.0},
                    ZOrder := 0,
                    Widget := RankBg}
                # 순위 글자(예: 3RD / 8)도 글자 이미지로 만든다. 한 자리씩 따로 바꿀 수 있게 칸을 나눠 둔다.
                NumH := RankNumSize * HudScale
                SufH0 := RankSuffixSize * HudScale
                TotH := RankTotalSize * HudScale
                SlashH := TotH * 1.2
                Overlap := 0.0 - NumH * 0.04
                RankTens := MakeGlyph('0', NumH, NamedColors.White)
                RankOnes := MakeGlyph('1', NumH, NamedColors.White)
                SufA := MakeGlyph('S', SufH0, NamedColors.White)
                SufB := MakeGlyph('T', SufH0, NamedColors.White)
                RankSlash := MakeGlyph('/', SlashH, NamedColors.White)
                TotTens := MakeGlyph('0', TotH, NamedColors.White)
                TotOnes := MakeGlyph('8', TotH, NamedColors.White)
                RankRow := stack_box{
                    Orientation := orientation.Horizontal,
                    Slots := array{
                        stack_box_slot{Widget := RankTens, VerticalAlignment := vertical_alignment.Bottom},
                        stack_box_slot{Widget := RankOnes, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := Overlap}},
                        stack_box_slot{Widget := SufA, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 2.0 * HudScale}},
                        stack_box_slot{Widget := SufB, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 0.0 - SufH0 * 0.04}},
                        stack_box_slot{Widget := RankSlash, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 6.0 * HudScale}},
                        stack_box_slot{Widget := TotTens, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 6.0 * HudScale}},
                        stack_box_slot{Widget := TotOnes, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 0.0 - TotH * 0.04}}}}
                RankSlot := canvas_slot{
                    Anchors := BottomLeft,
                    Offsets := margin{Left := RankMargin + 0.53 * RankW, Top := 0.0 - RankMargin - (1.0 - RankTextYRatio) * RankH},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 0.5},
                    ZOrder := 1,
                    Widget := RankRow}
                Canvas := canvas{Slots := array{BgSlot, Slot, RankBgSlot, RankSlot}}
                # HUD는 결과 화면(타임오버 붉은빛 포함)보다 위에 뜨도록 높은 ZOrder를 준다.
                PlayerUi.AddWidget(Canvas, player_ui_slot{ZOrder := 10})
                Widgets := timer_widgets{Canvas := Canvas, TensMin := TensMin, OneMin := OneMin, Colon := Colon, SecTens := SecTens, SecOnes := SecOnes, RankTens := RankTens, RankOnes := RankOnes, SufA := SufA, SufB := SufB, RankSlash := RankSlash, TotTens := TotTens, TotOnes := TotOnes}
                SetClock(Widgets, Left)
                if (set TimerWidgets[Player] = Widgets) {}

    # 모든 플레이어에게 현재 남은 시간을 계속 보여준다(골인한 사람의 기록은 결과 화면에 따로 표시).
    UpdateTimers(Left:int):void =
        for (Player -> W : TimerWidgets):
            SetClock(W, Left)

    # 타이머 글자 이미지 5칸(분 십의 자리, 분, 콜론, 초 십의 자리, 초)의 숫자와 색을 바꾼다. 분이 10 미만이면 맨 앞 칸은 숨긴다.
    SetClock(W:timer_widgets, Left:int):void =
        Color := if (Left <= Floor[WarnSeconds]) then NamedColors.Red else NamedColors.White
        if (M := Quotient[Left, 60], S := Mod[Left, 60], M1 := Quotient[M, 10], M0 := Mod[M, 10], S1 := Quotient[S, 10], S0 := Mod[S, 10]):
            W.TensMin.SetImage(DigitImage(M1))
            W.OneMin.SetImage(DigitImage(M0))
            W.SecTens.SetImage(DigitImage(S1))
            W.SecOnes.SetImage(DigitImage(S0))
            if (M1 > 0):
                W.TensMin.SetVisibility(widget_visibility.Visible)
            else:
                W.TensMin.SetVisibility(widget_visibility.Collapsed)
        for (Block : array{W.TensMin, W.OneMin, W.Colon, W.SecTens, W.SecOnes}):
            Block.SetTint(Color)

    # 순위 박스의 글자 이미지 칸을 갱신한다: "3RD / 8". 십의 자리가 0이면 그 칸은 숨긴다. 접미어 글자는 숫자보다 작게 보여준다.
    SetRank(W:timer_widgets, Place:int, Total:int):void =
        SufH := RankSuffixSize * HudScale
        if (P1 := Quotient[Place, 10], P0 := Mod[Place, 10], T1 := Quotient[Total, 10], T0 := Mod[Total, 10]):
            W.RankOnes.SetImage(DigitImage(P0))
            W.RankTens.SetImage(DigitImage(P1))
            W.TotOnes.SetImage(DigitImage(T0))
            W.TotTens.SetImage(DigitImage(T1))
            if (P1 > 0):
                W.RankTens.SetVisibility(widget_visibility.Visible)
            else:
                W.RankTens.SetVisibility(widget_visibility.Collapsed)
            if (T1 > 0):
                W.TotTens.SetVisibility(widget_visibility.Visible)
            else:
                W.TotTens.SetVisibility(widget_visibility.Collapsed)
        Suffix := OrdinalSuffix(Place)
        if (A := Suffix[0], B := Suffix[1]):
            SetGlyph(W.SufA, A, SufH)
            SetGlyph(W.SufB, B, SufH)

    # 왼쪽 아래 순위 박스는 현재 순위 "1ST / 4", 골인 후 대기 문구는 남은 인원 숫자를 갱신한다.
    UpdateInfo():void =
        Total := GetPlayspace().GetPlayers().Length
        Waiting := Total - FinishedRank.Length
        for (Player -> W : TimerWidgets):
            SetRank(W, RankOf(Player), Total)
        for (Player -> Wait : ResultWaits):
            if (T1 := Quotient[Waiting, 10], T0 := Mod[Waiting, 10]):
                Wait.Ones.SetImage(DigitImage(T0))
                Wait.Tens.SetImage(DigitImage(T1))
                if (T1 > 0):
                    Wait.Tens.SetVisibility(widget_visibility.Visible)
                else:
                    Wait.Tens.SetVisibility(widget_visibility.Collapsed)

    HideTimers():void =
        for (Player -> W : TimerWidgets):
            if (PlayerUi := GetPlayerUI[Player]):
                PlayerUi.RemoveWidget(W.Canvas)
        set TimerWidgets = map{}

    # "2:41" 형식.
    FormatClock(Left:int):string =
        if (M := Quotient[Left, 60], S := Mod[Left, 60]):
            Pad := if (S < 10) then "0" else ""
            return "{M}:{Pad}{S}"
        "0:00"

    # 게임이 끝나면 아직 결과 화면이 없는 플레이어(제한시간 안에 골인하지 못한 사람)에게 TIME OVER 화면을 보여준다.
    ShowResults():void =
        HideWaiting()
        MusicManager.Halt()
        for (Player : GetPlayspace().GetPlayers()):
            if (not FinishedRank[Player]):
                # 타임오버 음악이 배경음악과 겹치지 않도록 배경음악을 멈추고 튼다.
                MusicManager.StopFor(Player)
                TimeOverMusic.Play(Player)
            ShowResultFor(Player)

    # 해당 플레이어의 결과 화면을 한 번만 띄운다. 골인한 사람이면 아래에 남은 인원 안내도 같이 띄운다.
    ShowResultFor(Player:player):void =
        if (not ResultCanvases[Player], PlayerUi := GetPlayerUI[Player]):
            Canvas := BuildResultCanvas(Player)
            PlayerUi.AddWidget(Canvas)
            if (set ResultCanvases[Player] = Canvas) {}
            if (FinishedRank[Player], GameEnded = false):
                # 대기 문구도 글자 이미지로: "WAITING FOR OTHERS"(흰색) + 남은 인원 숫자(금색) + "LEFT"(금색). 숫자만 따로 바뀐다.
                H := WaitingTextSize * HudScale
                Gold := MakeColorFromHex("FFD84A")
                Label := BuildGlyphRow("WAITING FOR OTHERS", H, NamedColors.White)
                CountTens := MakeGlyph('0', H, Gold)
                CountOnes := MakeGlyph('0', H, Gold)
                LeftRow := BuildGlyphRow("LEFT", H, Gold)
                WaitRow := stack_box{
                    Orientation := orientation.Horizontal,
                    Slots := array{
                        stack_box_slot{Widget := Label},
                        stack_box_slot{Widget := CountTens, Padding := margin{Left := H * 0.45}},
                        stack_box_slot{Widget := CountOnes, Padding := margin{Left := 0.0 - H * 0.04}},
                        stack_box_slot{Widget := LeftRow, Padding := margin{Left := H * 0.28}}}}
                Slot := canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}},
                    Offsets := margin{Top := -58.0 * HudScale},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 1.0},
                    ZOrder := 3,
                    Widget := WaitRow}
                WaitCanvas := canvas{Slots := array{Slot}}
                PlayerUi.AddWidget(WaitCanvas)
                if (set ResultWaits[Player] = result_wait{Canvas := WaitCanvas, Tens := CountTens, Ones := CountOnes}) {}
                UpdateInfo()

    HideWaiting():void =
        for (Player -> Wait : ResultWaits):
            if (PlayerUi := GetPlayerUI[Player]):
                PlayerUi.RemoveWidget(Wait.Canvas)
        set ResultWaits = map{}

    HideResults():void =
        HideWaiting()
        for (Player -> Canvas : ResultCanvases):
            if (PlayerUi := GetPlayerUI[Player]):
                PlayerUi.RemoveWidget(Canvas)
        set ResultCanvases = map{}

    # 1 -> "1ST", 2 -> "2ND", 3 -> "3RD", 11 -> "11TH"
    OrdinalSuffix(Rank:int):string =
        if (Teen := Mod[Rank, 100], Teen >= 11, Teen <= 13):
            return "TH"
        if (Last := Mod[Rank, 10], Last = 1):
            return "ST"
        if (Last := Mod[Rank, 10], Last = 2):
            return "ND"
        if (Last := Mod[Rank, 10], Last = 3):
            return "RD"
        "TH"

    Ordinal(Rank:int):string =
        if (Teen := Mod[Rank, 100], Teen >= 11, Teen <= 13):
            return "{Rank}TH"
        if (Last := Mod[Rank, 10], Last = 1):
            return "{Rank}ST"
        if (Last := Mod[Rank, 10], Last = 2):
            return "{Rank}ND"
        if (Last := Mod[Rank, 10], Last = 3):
            return "{Rank}RD"
        "{Rank}TH"

    # 결과 화면: 골인한 사람은 골인 이미지와 순위·기록, 완주하지 못한 사람은 타임오버 이미지만 보여준다.
    BuildResultCanvas(Player:player):canvas =
        if (Rank := FinishedRank[Player], Spent := FinishedSpent[Player]):
            return BuildGoalCanvas(Rank, Spent)
        BuildTimeOverCanvas()

    # 우리가 쓰는 글꼴 이미지 표(둥근 통통한 흰색 글자 + 엇은 어두운 테두리): 문자 -> (텍스처, 가로/세로 비율).
    # 숫자 0~9는 모두 같은 가로 비율이라 시간이 바뀔어도 자리가 흔들리지 않는다. 모든 글자의 세로 기준선이 같다. (수정: Content/글꼴 이미지 Bubble 폴더)
    GlyphTable()<transacts>:[char]glyph_def =
        map{
            '0' => glyph_def{Image := b_0, Aspect := 0.7656}, '1' => glyph_def{Image := b_1, Aspect := 0.7656},
            '2' => glyph_def{Image := b_2, Aspect := 0.7656}, '3' => glyph_def{Image := b_3, Aspect := 0.7656},
            '4' => glyph_def{Image := b_4, Aspect := 0.7656}, '5' => glyph_def{Image := b_5, Aspect := 0.7656},
            '6' => glyph_def{Image := b_6, Aspect := 0.7656}, '7' => glyph_def{Image := b_7, Aspect := 0.7656},
            '8' => glyph_def{Image := b_8, Aspect := 0.7656}, '9' => glyph_def{Image := b_9, Aspect := 0.7656},
            ':' => glyph_def{Image := b_colon, Aspect := 0.3490}, '/' => glyph_def{Image := b_slash, Aspect := 0.5052},
            'A' => glyph_def{Image := b_A, Aspect := 0.7917}, 'B' => glyph_def{Image := b_B, Aspect := 0.7240},
            'C' => glyph_def{Image := b_C, Aspect := 0.7240}, 'D' => glyph_def{Image := b_D, Aspect := 0.7240},
            'E' => glyph_def{Image := b_E, Aspect := 0.6979}, 'F' => glyph_def{Image := b_F, Aspect := 0.6719},
            'G' => glyph_def{Image := b_G, Aspect := 0.7813}, 'H' => glyph_def{Image := b_H, Aspect := 0.7240},
            'I' => glyph_def{Image := b_I, Aspect := 0.3073}, 'J' => glyph_def{Image := b_J, Aspect := 0.6458},
            'K' => glyph_def{Image := b_K, Aspect := 0.7135}, 'L' => glyph_def{Image := b_L, Aspect := 0.6667},
            'M' => glyph_def{Image := b_M, Aspect := 0.8906}, 'N' => glyph_def{Image := b_N, Aspect := 0.7396},
            'O' => glyph_def{Image := b_O, Aspect := 0.7813}, 'P' => glyph_def{Image := b_P, Aspect := 0.7083},
            'Q' => glyph_def{Image := b_Q, Aspect := 0.7813}, 'R' => glyph_def{Image := b_R, Aspect := 0.7188},
            'S' => glyph_def{Image := b_S, Aspect := 0.7240}, 'T' => glyph_def{Image := b_T, Aspect := 0.7760},
            'U' => glyph_def{Image := b_U, Aspect := 0.7188}, 'V' => glyph_def{Image := b_V, Aspect := 0.7813},
            'W' => glyph_def{Image := b_W, Aspect := 1.0156}, 'X' => glyph_def{Image := b_X, Aspect := 0.7604},
            'Y' => glyph_def{Image := b_Y, Aspect := 0.7760}, 'Z' => glyph_def{Image := b_Z, Aspect := 0.6927}}

    # 글자 하나를 이미지로 만든다. Height는 글자 이미지 높이(여백 포함, 대문자 높이는 약 84%).
    MakeGlyph(C:char, Height:float, Tint:color):texture_block =
        if (G := GlyphTable()[C]):
            return texture_block{DefaultImage := G.Image, DefaultTint := Tint, DefaultDesiredSize := vector2{X := G.Aspect * Height, Y := Height}}
        texture_block{DefaultImage := b_0, DefaultTint := Tint, DefaultDesiredSize := vector2{X := 0.7656 * Height, Y := Height}}

    # 0~9를 글자 이미지로 바꾼다.
    DigitImage(N:int):texture =
        Digits := array{b_0, b_1, b_2, b_3, b_4, b_5, b_6, b_7, b_8, b_9}
        if (D := Digits[N]):
            return D
        b_0

    # 글자 하나의 텍스처와 높이에 맞춘 가로 크기를 블록에 적용한다(순위 접미어 ST/ND/RD/TH 처럼 글자가 바뀔 때).
    SetGlyph(Block:texture_block, C:char, Height:float):void =
        if (G := GlyphTable()[C]):
            Block.SetImage(G.Image)
            Block.SetDesiredSize(vector2{X := G.Aspect * Height, Y := Height})

    # 문자열을 글자 이미지 한 줄로 조립한다. 글자 사이는 높이의 0.03배만큼 띄우고, 공백은 높이의 0.28배만큼 띄운다.
    BuildGlyphRow(Text:string, Height:float, Tint:color):stack_box =
        Table := GlyphTable()
        var Slots:[]stack_box_slot = array{}
        var Gap:float = 0.0
        for (C : Text):
            if (G := Table[C]):
                Tex := texture_block{DefaultImage := G.Image, DefaultTint := Tint, DefaultDesiredSize := vector2{X := G.Aspect * Height, Y := Height}}
                # 콜론(:)은 글자 폭이 좋아서 숫자와 겹쳐 보이기 쉽다. 앞뒤로 조금 더 벌린다.
                Extra := if (C = ':') then Height * 0.06 else 0.0
                set Slots += array{stack_box_slot{Widget := Tex, Padding := margin{Left := Gap + Extra}}}
                set Gap = Height * 0.03 + Extra
            else:
                set Gap += Height * 0.28
        stack_box{Orientation := orientation.Horizontal, Slots := Slots}


    # 타임오버 화면: 게임 화면 전체에 옛은 붉은색을 깔고, 가운데에 ui_timeover 이미지를 놓는다.
    # 위쪽 타이머와 왼쪽 아래 순위 박스(HUD)는 이 화면보다 위에 뜨므로 붉은빛이 입히지 않는다.
    BuildTimeOverCanvas():canvas =
        Center := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
        FullScreen := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
        Width := ResultImageWidth * HudScale
        Image := texture_block{DefaultImage := ui_timeover, DefaultDesiredSize := vector2{X := Width, Y := Width / 1.7778}}
        ImageSlot := canvas_slot{Anchors := Center, Offsets := margin{Top := -20.0 * HudScale}, Alignment := vector2{X := 0.5, Y := 0.5}, SizeToContent := true, ZOrder := 1, Widget := Image}
        var Slots:[]canvas_slot = array{ImageSlot}
        # 진하기는 0~1 범위의 값만 쓸 수 있어 범위를 확인한다. 범위 밖이면 붉은빛 없이 이미지만 보여준다.
        if (Opacity := opacity_range[TimeOverTintOpacity]):
            Tint := color_block{DefaultColor := MakeColorFromHex("FF2A3A"), DefaultOpacity := Opacity}
            set Slots = array{canvas_slot{Anchors := FullScreen, Offsets := margin{}, Alignment := vector2{X := 0.0, Y := 0.0}, SizeToContent := false, ZOrder := 0, Widget := Tint}, ImageSlot}
        canvas{Slots := Slots}

    # 골인 화면: ui_goal_in 이미지 아래에 순위(예: 1ST PLACE)와 기록(예: TIME 4:52)을 글자 이미지로 보여준다.
    # 이미지는 화면 가운데보다 조금 아래에 두어 위쪽 타이머를 가리지 않는다. 그 아래 대기 문구는 ShowResultFor가 따로 띄운다.
    BuildGoalCanvas(Rank:int, Spent:int):canvas =
        Point := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
        Pivot := vector2{X := 0.5, Y := 0.5}
        Width := GoalImageWidth * HudScale
        Image := texture_block{DefaultImage := ui_goal_in, DefaultDesiredSize := vector2{X := Width, Y := Width / 1.8112}}
        BigColor := if (Rank = 1) then MakeColorFromHex("FFD84A") else NamedColors.White
        BigRow := BuildGlyphRow("{Ordinal(Rank)} PLACE", 84.0 * HudScale, BigColor)
        SubRow := BuildGlyphRow("TIME  {FormatClock(Spent)}", 50.0 * HudScale, NamedColors.White)
        canvas{Slots := array{
            canvas_slot{Anchors := Point, Offsets := margin{Top := 5.0 * HudScale}, Alignment := Pivot, SizeToContent := true, ZOrder := 0, Widget := Image},
            canvas_slot{Anchors := Point, Offsets := margin{Top := 300.0 * HudScale}, Alignment := Pivot, SizeToContent := true, ZOrder := 2, Widget := BigRow},
            canvas_slot{Anchors := Point, Offsets := margin{Top := 380.0 * HudScale}, Alignment := Pivot, SizeToContent := true, ZOrder := 2, Widget := SubRow}}}
