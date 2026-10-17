using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# 배경음악 담당 장치. 레이스 매니저(race_manager)가 시작, 중단, 골인 음악 중 줄이기를 요청한다.
# - 배경음악 Audio Player는 반복 재생의 두 번째 바퀴부터 소리가 작아지는 문제가 있어서, 곡이 끝나는 시점마다 Verse가 처음부터 다시 틀어준다.
# - 골인 음악이 나오는 동안에는 원래 배경음악을 멈추고 작은 소리 버전(MusicLow)을 틀었다가, 끝나면 되돌린다.
music_manager := class(creative_device):

    # 배경음악(Audio Player, Instigator Only).
    @editable
    Music:audio_player_device = audio_player_device{}

    # 골인 음악이 나오는 동안 틀어줄 작은 소리의 같은 곡.
    @editable
    MusicLow:audio_player_device = audio_player_device{}

    # 배경음악 곡 길이(초, 현재 곡 60.03초). 이 간격마다 처음부터 다시 틀어준다.
    @editable
    MusicLoopSeconds:float = 59.95

    # 골인/챔피언 음악 길이(초, 현재 곡 30.04초). 이 시간 동안 배경음악을 줄인다.
    @editable
    DuckSeconds:float = 30.0

    var Running:logic = false
    var Ducked:[player]logic = map{}

    # 모든 플레이어에게 배경음악을 틀고 반복 타이머를 시작한다.
    Start<public>():void =
        set Running = true
        for (Player : GetPlayspace().GetPlayers()):
            Music.Play(Player)
        spawn{RunLoop()}

    # 다시 틀지 않도록 막기만 한다(이미 나오는 소리는 그대로 둔다).
    Halt<public>():void =
        set Running = false

    # 모든 배경음악을 멈춘다.
    Stop<public>():void =
        set Running = false
        Music.Stop()
        MusicLow.Stop()

    # 중간에 들어온 플레이어에게 틀어준다.
    PlayFor<public>(Player:player):void =
        if (Running = true):
            Music.Play(Player)

    # 한 플레이어의 배경음악만 멈춘다(타임오버 음악이 겹치지 않게).
    StopFor<public>(Player:player):void =
        Music.Stop(Player)
        MusicLow.Stop(Player)

    # 골인 음악이 나오는 동안 이 플레이어의 배경음악을 작은 소리로 바꿨다가 되돌린다.
    DuckFor<public>(Player:player)<suspends>:void =
        if (Running = true):
            if (set Ducked[Player] = true) {}
            Music.Stop(Player)
            MusicLow.Play(Player)
            Sleep(DuckSeconds)
            MusicLow.Stop(Player)
            if (set Ducked[Player] = false) {}
            if (Running = true):
                Music.Play(Player)

    RunLoop()<suspends>:void =
        loop:
            Sleep(MusicLoopSeconds)
            if (Running = false):
                break
            for (Player : GetPlayspace().GetPlayers()):
                IsDucked := if (D := Ducked[Player]) then D else false
                if (IsDucked = false):
                    Music.Play(Player)
