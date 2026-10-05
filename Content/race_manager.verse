using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }
using { /jaihaklee@fortnite.com/FallGuys_Sample/UI }
using { /jaihaklee@fortnite.com/FallGuys_Sample/Italic }
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

timer_widgets := class:
    Canvas:canvas
    Text:text_block
    Info:text_block
    RankNum:text_block
    RankSuffix:text_block
    RankTotal:text_block

# 골인한 플레이어 화면 아래에 뜨는 "남은 사람 수" 안내.
result_wait := class:
    Canvas:canvas
    Text:text_block

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

    # 배경음악(Audio Player, 반복 재생). 게임이 시작되면 모든 플레이어에게 틀고, 중간에 들어온 플레이어에게도 틀며, 결과 화면 뒤 게임이 끝날 때 멈춘다.
    @editable
    Music:audio_player_device = audio_player_device{}

    # 배경음악 곡 길이(초). 장치의 반복 재생 두 번째 바퀴부터 소리가 작아져서, 곡이 끝날 때마다 Verse가 처음부터 다시 틀어준다.
    @editable
    MusicLoopSeconds:float = 30.9

    # 배경음악을 틀지 여부. 효과음만 따로 확인할 때 false로 둔다.
    @editable
    PlayMusic:logic = true

    # 골인한 플레이어에게만 들리는 결승 효과음(Audio Player, Instigator Only).
    @editable
    FinishSting:audio_player_device = audio_player_device{}

    # 제한시간 안에 골인하지 못한 플레이어에게만 들리는 타임오버 효과음.
    @editable
    TimeOverSfx:audio_player_device = audio_player_device{}

    # 남은 시간이 10초 이하일 때 1초마다 울리는 알람. 아직 골인하지 않은 플레이어에게만 들린다.
    @editable
    AlarmSfx:audio_player_device = audio_player_device{}

    @editable
    AlarmSeconds:int = 10

    # 결승 피날레 음악이 나오는 동안 틀어줄 작은 소리의 배경음악(BGM_Low). 피날레가 끝나면 원래 배경음악으로 되돌린다.
    @editable
    MusicLow:audio_player_device = audio_player_device{}

    # 결승 피날레 음악 길이(초). 이 시간 동안 배경음악을 줄인다.
    @editable
    FinishMusicSeconds:float = 9.0

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

    @editable
    TimerTextSize:float = 96.0

    # 왼쪽 아래 순위 숫자 위의 "Ranking" 글자와 숫자 옆 ST/ND/RD/TH 글자 크기(같은 크기).
    @editable
    RankLabelSize:float = 30.0

    # 화면 UI 전체 크기 배율. 작은 화면(모바일 등)에서 글자가 너무 크거나 구석에서 잘리면 0.7 정도로 줄인다. 1.0이 기본.
    @editable
    HudScale:float = 1.0

    # 골인한 뒤 결과 화면 아래에 뜨는 "남은 사람 수" 글자 크기.
    @editable
    WaitingTextSize:float = 48.0

    # 타이머 아래 순위, 체크포인트 글자 크기.
    @editable
    InfoTextSize:float = 40.0

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
    var FinishedLeft:[agent]int = map{}
    var FinishedSpent:[agent]int = map{}
    var LastFinisher:?agent = false
    var GameEnded:logic = false
    var ResultCanvases:[player]canvas = map{}
    var ResultWaits:[player]result_wait = map{}
    var Ducked:[player]logic = map{}
    var CheckpointCount:[player]int = map{}
    var CheckpointTime:[player]float = map{}

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
            for (Player : GetPlayspace().GetPlayers()):
                Music.Play(Player)
            spawn{RunMusic()}
        if (Manager := Self.GetSimulationEntity[].GetFortRoundManager[]):
            Manager.SubscribeRoundStarted(OnRoundStart)
            Print("race_manager: subscribed to round start")
        else:
            Print("race_manager: no round manager, starting now")
            OnRoundStart()

    # 라운드가 시작하면 기록을 초기화하고 제한시간이 지나면 결과를 보여준다.
    OnRoundStart()<suspends>:void =
        set RaceStart = GetSimulationElapsedTime()
        for (Player : GetPlayspace().GetPlayers()):
            StartSfx.Play(Player)
        set CheckpointCount = map{}
        set CheckpointTime = map{}
        set FinishedRank = map{}
        set FinishedLeft = map{}
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
            if (set FinishedRank[Agent] = Rank, set FinishedLeft[Agent] = Left, set FinishedSpent[Agent] = Spent):
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
            CheckAllFinished()

    # 골인한 플레이어에게만 축하 효과음을 잠깐 틀어준다.
    PlaySting(Agent:agent)<suspends>:void =
        FinishSting.Play(Agent)
        # 피날레와 배경음악이 겹치지 않도록, 피날레가 나오는 동안 배경음악을 작은 소리 버전으로 바꾸고 끝나면 되돌린다.
        if (Player := player[Agent], PlayMusic?):
            if (set Ducked[Player] = true) {}
            Music.Stop(Player)
            MusicLow.Play(Player)
            Sleep(FinishMusicSeconds)
            MusicLow.Stop(Player)
            if (set Ducked[Player] = false) {}
            if (GameEnded = false):
                Music.Play(Player)

    # 곡이 끝나는 시점마다 모든 플레이어에게 처음부터 다시 틀어준다(레이스가 끝나면 멈춘다).
    RunMusic()<suspends>:void =
        loop:
            Sleep(MusicLoopSeconds)
            if (GameEnded = true):
                break
            for (Player : GetPlayspace().GetPlayers()):
                IsDucked := if (D := Ducked[Player]) then D else false
                if (IsDucked = false):
                    Music.Play(Player)

    OnPlayerRemoved(Player:player):void =
        CheckAllFinished()

    # 중간에 들어온 플레이어도 배경음악을 듣게 한다.
    OnPlayerAdded(Player:player):void =
        if (PlayMusic?, GameEnded = false):
            Music.Play(Player)

    OnCheckpoint(Agent:agent):void =
        if (Player := player[Agent], RaceStart >= 0.0):
            Count := if (C := CheckpointCount[Player]) then C + 1 else 1
            if (set CheckpointCount[Player] = Count, set CheckpointTime[Player] = GetSimulationElapsedTime()):
                Print("race_manager: checkpoint {Count}/{CheckpointTotal}")
            UpdateInfo()

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
            Sleep(ResultSeconds)
            if (AnyPlayer := GetPlayspace().GetPlayers()[0]):
                EndGame.Activate(AnyPlayer)
            Sleep(5.0)
            Music.Stop()
            MusicLow.Stop()
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

    AddMissingTimers(Left:int):void =
        for (Player : GetPlayspace().GetPlayers()):
            if (not TimerWidgets[Player], PlayerUi := GetPlayerUI[Player]):
                Text := text_block{
                    DefaultText := Msg(FormatClock(Left)),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := TimerTextSize * HudScale,
                    DefaultJustification := text_justification.Center,
                    DefaultShadowOffset := option{vector2{X := 3.0, Y := 3.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                Slot := canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0}},
                    Offsets := margin{Top := 24.0 * HudScale},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 0.0},
                    Widget := Text}
                Info := text_block{
                    DefaultText := Msg(""),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := InfoTextSize * HudScale,
                    DefaultJustification := text_justification.Center,
                    DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                InfoSlot := canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.0}, Maximum := vector2{X := 0.5, Y := 0.0}},
                    Offsets := margin{Top := (24.0 + TimerTextSize * 1.25) * HudScale},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 0.0},
                    Widget := Info}
                RankNum := text_block{
                    DefaultText := Msg(""),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := TimerTextSize * HudScale,
                    DefaultShadowOffset := option{vector2{X := 3.0, Y := 3.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                RankSuffix := text_block{
                    DefaultText := Msg(""),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := RankLabelSize * HudScale,
                    DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                RankTotal := text_block{
                    DefaultText := Msg(""),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := TimerTextSize * HudScale,
                    DefaultShadowOffset := option{vector2{X := 3.0, Y := 3.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                RankRow := stack_box{
                    Orientation := orientation.Horizontal,
                    Slots := array{
                        stack_box_slot{Widget := RankNum, VerticalAlignment := vertical_alignment.Bottom},
                        stack_box_slot{Widget := RankSuffix, VerticalAlignment := vertical_alignment.Bottom, Padding := margin{Left := 4.0 * HudScale, Bottom := 6.0 * HudScale}},
                        stack_box_slot{Widget := RankTotal, VerticalAlignment := vertical_alignment.Bottom}}}
                RankLabel := text_block{
                    DefaultText := Msg("Ranking"),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := RankLabelSize * HudScale,
                    DefaultShadowOffset := option{vector2{X := 2.0, Y := 2.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                RankBox := stack_box{
                    Orientation := orientation.Vertical,
                    Slots := array{
                        stack_box_slot{Widget := RankLabel, HorizontalAlignment := horizontal_alignment.Left, Padding := margin{Left := 6.0 * HudScale}},
                        stack_box_slot{Widget := RankRow, HorizontalAlignment := horizontal_alignment.Left}}}
                RankSlot := canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 1.0}, Maximum := vector2{X := 0.0, Y := 1.0}},
                    Offsets := margin{Left := 40.0 * HudScale, Top := -40.0 * HudScale},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.0, Y := 1.0},
                    Widget := RankBox}
                Canvas := canvas{Slots := array{Slot, InfoSlot, RankSlot}}
                PlayerUi.AddWidget(Canvas)
                if (set TimerWidgets[Player] = timer_widgets{Canvas := Canvas, Text := Text, Info := Info, RankNum := RankNum, RankSuffix := RankSuffix, RankTotal := RankTotal}) {}

    # 모든 플레이어에게 현재 남은 시간을 계속 보여준다(골인한 사람의 기록은 결과 화면에 따로 표시).
    UpdateTimers(Left:int):void =
        for (Player -> W : TimerWidgets):
            Shown := Left
            Color := if (Shown <= Floor[WarnSeconds]) then NamedColors.Red else NamedColors.White
            W.Text.SetText(Msg(FormatClock(Shown)))
            W.Text.SetTextColor(Color)

    # 타이머 아래 한 줄은 체크포인트 진행(막 밟았으면 2초간 금색), 왼쪽 아래 구석은 현재 순위 "1/4" (타이머와 같은 크기).
    UpdateInfo():void =
        Now := GetSimulationElapsedTime()
        Total := GetPlayspace().GetPlayers().Length
        Waiting := Total - FinishedRank.Length
        for (Player -> W : TimerWidgets):
            Count := if (C := CheckpointCount[Player]) then C else 0
            Fresh := if (T := CheckpointTime[Player], Now - T < 2.0) then true else false
            Line := if (FinishedRank[Player]) then "FINISHED - {Waiting} LEFT" else "CHECKPOINT {Count} / {CheckpointTotal}"
            W.Info.SetText(Msg(Line))
            Place := RankOf(Player)
            W.RankNum.SetText(Msg("{Place}"))
            W.RankSuffix.SetText(Msg(OrdinalSuffix(Place)))
            W.RankTotal.SetText(Msg(" / {Total}"))
            W.Info.SetTextColor(if (Fresh = true) then NamedColors.Gold else NamedColors.White)
        for (Player -> Wait : ResultWaits):
            Wait.Text.SetText(Msg("WAITING FOR OTHERS - {Waiting} LEFT"))

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
        for (Player : GetPlayspace().GetPlayers()):
            if (not FinishedRank[Player]):
                TimeOverSfx.Play(Player)
            ShowResultFor(Player)

    # 해당 플레이어의 결과 화면을 한 번만 띄운다. 골인한 사람이면 아래에 남은 인원 안내도 같이 띄운다.
    ShowResultFor(Player:player):void =
        if (not ResultCanvases[Player], PlayerUi := GetPlayerUI[Player]):
            Canvas := BuildResultCanvas(Player)
            PlayerUi.AddWidget(Canvas)
            if (set ResultCanvases[Player] = Canvas) {}
            if (FinishedRank[Player], GameEnded = false):
                Text := text_block{
                    DefaultText := Msg(""),
                    DefaultTextColor := NamedColors.White,
                    DefaultTextSize := WaitingTextSize * HudScale,
                    DefaultJustification := text_justification.Center,
                    DefaultShadowOffset := option{vector2{X := 3.0, Y := 3.0}},
                    DefaultShadowColor := NamedColors.Black,
                    DefaultShadowOpacity := 1.0}
                Slot := canvas_slot{
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}},
                    Offsets := margin{Top := -70.0 * HudScale},
                    SizeToContent := true,
                    Alignment := vector2{X := 0.5, Y := 1.0},
                    ZOrder := 3,
                    Widget := Text}
                WaitCanvas := canvas{Slots := array{Slot}}
                PlayerUi.AddWidget(WaitCanvas)
                if (set ResultWaits[Player] = result_wait{Canvas := WaitCanvas, Text := Text}) {}
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

    # 결과 화면: 골인한 사람은 순위와 기록, 완주하지 못한 사람은 TIME OVER!만 보여준다.
    BuildResultCanvas(Player:player):canvas =
        if (Rank := FinishedRank[Player], Spent := FinishedSpent[Player]):
            BigColor := if (Rank = 1) then MakeColorFromHex("FFD84A") else NamedColors.White
            return BuildNeonCanvas("{Ordinal(Rank)} PLACE", "TIME  {FormatClock(Spent)}", BigColor, result_success)
        BuildNeonCanvas("TIME OVER!", "", NamedColors.White, result_fail)

    # 이태릭 글자 이미지 표: 문자 -> (텍스처, 가로/세로 비율). 글자 잉크 경계에 맞게 잘라낸 이미지라서 오른쪽이 잘리지 않는다.
    GlyphTable():[char]glyph_def =
        map{
            '0' => glyph_def{Image := g_0, Aspect := 0.3812}, '1' => glyph_def{Image := g_1, Aspect := 0.3062},
            '2' => glyph_def{Image := g_2, Aspect := 0.3812}, '3' => glyph_def{Image := g_3, Aspect := 0.3812},
            '4' => glyph_def{Image := g_4, Aspect := 0.3938}, '5' => glyph_def{Image := g_5, Aspect := 0.3875},
            '6' => glyph_def{Image := g_6, Aspect := 0.375}, '7' => glyph_def{Image := g_7, Aspect := 0.375},
            '8' => glyph_def{Image := g_8, Aspect := 0.3812}, '9' => glyph_def{Image := g_9, Aspect := 0.375},
            ':' => glyph_def{Image := g_colon, Aspect := 0.2188}, '.' => glyph_def{Image := g_dot, Aspect := 0.1688}, '!' => glyph_def{Image := g_excl, Aspect := 0.2438},
            'S' => glyph_def{Image := g_S, Aspect := 0.45}, 'T' => glyph_def{Image := g_T, Aspect := 0.4312},
            'N' => glyph_def{Image := g_N, Aspect := 0.5188}, 'D' => glyph_def{Image := g_D, Aspect := 0.4938},
            'R' => glyph_def{Image := g_R, Aspect := 0.5}, 'H' => glyph_def{Image := g_H, Aspect := 0.5188},
            'P' => glyph_def{Image := g_P, Aspect := 0.4812}, 'L' => glyph_def{Image := g_L, Aspect := 0.4},
            'A' => glyph_def{Image := g_A, Aspect := 0.4938}, 'C' => glyph_def{Image := g_C, Aspect := 0.475},
            'E' => glyph_def{Image := g_E, Aspect := 0.4938}, 'I' => glyph_def{Image := g_I, Aspect := 0.2562},
            'M' => glyph_def{Image := g_M, Aspect := 0.575}, 'O' => glyph_def{Image := g_O, Aspect := 0.5062},
            'V' => glyph_def{Image := g_V, Aspect := 0.4938}}

    # 문자열을 이태릭 글자 이미지 한 줄로 조립한다. 글자 사이는 높이의 0.05배, 공백은 0.28배만큼 띄운다. Height는 이미지 높이(대문자 높이는 약 45%).
    BuildGlyphRow(Text:string, Height:float, Tint:color):stack_box =
        Table := GlyphTable()
        var Slots:[]stack_box_slot = array{}
        var Gap:float = 0.0
        for (C : Text):
            if (G := Table[C]):
                Tex := texture_block{DefaultImage := G.Image, DefaultTint := Tint, DefaultDesiredSize := vector2{X := G.Aspect * Height, Y := Height}}
                set Slots += array{stack_box_slot{Widget := Tex, Padding := margin{Left := Gap}}}
                set Gap = Height * 0.12
            else:
                set Gap += Height * 0.22
        stack_box{Orientation := orientation.Horizontal, Slots := Slots}

    # 배경 이미지(전체 화면) + 가운데 이태릭 글자. Sub가 비어 있으면 큰 글자만 가운데에 둔다.
    BuildNeonCanvas(Big:string, Sub:string, BigColor:color, BackdropImage:texture):canvas =
        Point := anchors{Minimum := vector2{X := 0.5, Y := 0.5}, Maximum := vector2{X := 0.5, Y := 0.5}}
        FullScreen := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 1.0}}
        Pivot := vector2{X := 0.5, Y := 0.5}
        HasSub:logic = if (Sub <> "") then true else false
        BigHeight := (if (HasSub?) then 190.0 else 230.0) * HudScale
        BigY := (if (HasSub?) then -20.0 else 0.0) * HudScale
        Backdrop := texture_block{DefaultImage := BackdropImage}
        BigRow := BuildGlyphRow(Big, BigHeight, BigColor)
        var Slots:[]canvas_slot = array{
            canvas_slot{Anchors := FullScreen, Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 0.0}, Alignment := vector2{X := 0.0, Y := 0.0}, SizeToContent := false, ZOrder := 0, Widget := Backdrop},
            canvas_slot{Anchors := Point, Offsets := margin{Left := 0.0, Top := BigY}, Alignment := Pivot, SizeToContent := true, ZOrder := 2, Widget := BigRow}}
        if (HasSub?):
            SubRow := BuildGlyphRow(Sub, 85.0 * HudScale, NamedColors.White)
            set Slots += array{canvas_slot{Anchors := Point, Offsets := margin{Left := 0.0, Top := 56.0 * HudScale}, Alignment := Pivot, SizeToContent := true, ZOrder := 2, Widget := SubRow}}
        canvas{Slots := Slots}
