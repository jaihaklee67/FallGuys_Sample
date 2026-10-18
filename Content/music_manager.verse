using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# 배경음악 담당 장치. 레이스 매니저(race_manager)가 시작, 중단, 골인 음악 중 줄이기를 요청한다.
# - 배경음악 Audio Player는 반복 재생의 두 번째 바퀴부터 소리가 작아지는 문제가 있어서, 곡이 끝나는 시점마다 Verse가 처음부터 다시 틀어준다.
# - 골인 음악이 나오는 동안에는 원래 배경음악을 멈추고 작은 소리 버전(MusicLow)을 틀었다가, 끝나면 되돌린다.
music_manager := class(creative_device):

    # 배경음악 A(Audio Player, Instigator Only). 처음과 짝수 바퀘에서 쓴다.
    @editable
    Music:audio_player_device = audio_player_device{}

    # 배경음악 B(A와 같은 설정, 같은 곡). 홀수 바퀘에서 쓴다. 곡이 끝날 때 A와 B가 섬어 이어진다.
    @editable
    MusicB:audio_player_device = audio_player_device{}

    # 골인 음악이 나오는 동안 틀어줄 작은 소리의 같은 곡.
    @editable
    MusicLow:audio_player_device = audio_player_device{}

    # 다음 바퀘를 시작하는 간격(초) = 곡 길이 - 겹치는 시간. 현재 곡 66.68초, 겹침 0.35초라 66.33이다.
    # 곡 파일 맨 앞·뒤 0.35초에 서서히 커지고 작아지는 효과가 들어 있어, 앞 바퀘 끝과 다음 바퀘 시작이 겹치며 이어진다.
    @editable
    MusicLoopSeconds:float = 66.33

    # 골인/챔피언 음악 길이(초, 현재 곡 30.04초). 이 시간 동안 배경음악을 줄인다.
    @editable
    DuckSeconds:float = 30.0

    # 게임이 끝나기 직전에 소리를 단계로 줄이는 Audio Mixer 장치 4개. 음악 그룹(Music)과 효과음 그룹(SFX)을 모두 줄이고,
    # Soft는 약 65%, Deep은 약 30% 수준으로 낮춘다. 실제 버스와 음량은 장치 설정에서 정한다.
    @editable
    MixMusicSoft:audio_mixer_device = audio_mixer_device{}

    @editable
    MixMusicDeep:audio_mixer_device = audio_mixer_device{}

    @editable
    MixSfxSoft:audio_mixer_device = audio_mixer_device{}

    @editable
    MixSfxDeep:audio_mixer_device = audio_mixer_device{}

    # 소리를 줄이는 전체 시간(초). 절반은 Soft, 나머지 절반은 Deep 수준으로 들린다.
    @editable
    FadeSeconds:float = 1.2

    var Running:logic = false
    var Ducked:[player]logic = map{}
    # 이 플레이어가 지금 듣는 바퀘가 B인지 (없으면 A).
    var DeckB:[player]logic = map{}

    # 처음부터 틀 때는 항상 A에서 시작한다.
    PlayFresh(Player:player):void =
        MusicB.Stop(Player)
        Music.Play(Player)
        if (set DeckB[Player] = false) {}

    # 다음 바퀘: 지금 쓰지 않는 쪽에서 곡을 처음부터 시작한다. 앞 바퀘는 끝부분이 서서히 작아지며 새 바퀘와 겹친다.
    PlayNext(Player:player):void =
        OnB:logic = if (B := DeckB[Player], B = true) then true else false
        if (OnB = true):
            Music.Play(Player)
            if (set DeckB[Player] = false) {}
        else:
            MusicB.Play(Player)
            if (set DeckB[Player] = true) {}

    # 모든 플레이어에게 배경음악을 틀고 반복 타이머를 시작한다.
    Start<public>():void =
        set Running = true
        for (Player : GetPlayspace().GetPlayers()):
            PlayFresh(Player)
        spawn{RunLoop()}

    # 다시 틀지 않도록 막기만 한다(이미 나오는 소리는 그대로 둔다).
    Halt<public>():void =
        set Running = false

    # 모든 배경음악을 멈춘다.
    Stop<public>():void =
        set Running = false
        Music.Stop()
        MusicB.Stop()
        MusicLow.Stop()

    # 게임이 끝나기 직전에 부르면, FadeSeconds 동안 소리를 두 단계(Soft → Deep)로 줄인다. 호출한 고정시간 뒤에 게임을 끝내면 뜽 끊기는 느낌이 줄어든다.
    FadeOut<public>()<suspends>:void =
        MixMusicSoft.ActivateMix()
        MixSfxSoft.ActivateMix()
        Sleep(FadeSeconds / 2.0)
        MixMusicDeep.ActivateMix()
        MixSfxDeep.ActivateMix()
        Sleep(FadeSeconds / 2.0)

    # 줄였던 소리를 원래대로 되돌린다. 새 라운드가 시작할 때 부른다.
    ResetFade<public>():void =
        MixMusicSoft.DeactivateMix()
        MixMusicDeep.DeactivateMix()
        MixSfxSoft.DeactivateMix()
        MixSfxDeep.DeactivateMix()

    # 중간에 들어온 플레이어에게 틀어준다.
    PlayFor<public>(Player:player):void =
        if (Running = true):
            PlayFresh(Player)

    # 한 플레이어의 배경음악만 멈춘다(타임오버 음악이 겹치지 않게).
    StopFor<public>(Player:player):void =
        Music.Stop(Player)
        MusicB.Stop(Player)
        MusicLow.Stop(Player)

    # 골인 음악이 나오는 동안 이 플레이어의 배경음악을 작은 소리로 바꿨다가 되돌린다.
    DuckFor<public>(Player:player)<suspends>:void =
        if (Running = true):
            if (set Ducked[Player] = true) {}
            Music.Stop(Player)
            MusicB.Stop(Player)
            MusicLow.Play(Player)
            Sleep(DuckSeconds)
            MusicLow.Stop(Player)
            if (set Ducked[Player] = false) {}
            if (Running = true):
                PlayFresh(Player)

    RunLoop()<suspends>:void =
        loop:
            Sleep(MusicLoopSeconds)
            if (Running = false):
                break
            for (Player : GetPlayspace().GetPlayers()):
                IsDucked := if (D := Ducked[Player]) then D else false
                if (IsDucked = false):
                    PlayNext(Player)
