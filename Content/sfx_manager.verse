using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 추락사, 리스폰, 체크포인트, 에어벤트 바람 효과음을 맡는 매니저.
# 직접 가져온 wav를 Audio Player(Instigator Only)에 넣고 Verse에서 해당 플레이어에게만 Play(Agent) 한다.
sfx_manager := class(creative_device):

    @editable
    FallSfx:audio_player_device = audio_player_device{}

    @editable
    RespawnSfx:audio_player_device = audio_player_device{}

    @editable
    WindSfx:audio_player_device = audio_player_device{}

    @editable
    CheckpointSfx:audio_player_device = audio_player_device{}

    # 체크포인트 4개: 플레이어가 처음 밟을 때 효과음을 낸다.
    @editable
    Checkpoint1:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint2:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint3:player_checkpoint_device = player_checkpoint_device{}

    @editable
    Checkpoint4:player_checkpoint_device = player_checkpoint_device{}

    # 에어벤트 7개 (AV_Tower_1~7).
    @editable
    AirVent1:air_vent_device = air_vent_device{}

    @editable
    AirVent2:air_vent_device = air_vent_device{}

    @editable
    AirVent3:air_vent_device = air_vent_device{}

    @editable
    AirVent4:air_vent_device = air_vent_device{}

    @editable
    AirVent5:air_vent_device = air_vent_device{}

    @editable
    AirVent6:air_vent_device = air_vent_device{}

    @editable
    AirVent7:air_vent_device = air_vent_device{}

    # 같은 플레이어에게 바람 소리를 다시 내기까지 대기 시간 (초).
    @editable
    WindCooldown:float = 1.5

    # 에어벤트 배율 1당 바람 높이(미터 설정 3m = 300cm)와 반지름 (cm).
    @editable
    GustCmPerScale:float = 300.0

    @editable
    RadiusCmPerScale:float = 190.0

    var Vents:[]air_vent_device = array{}
    var WasAlive:[player]logic = map{}
    var LastWind:[player]float = map{}

    OnBegin<override>()<suspends>:void =
        set Vents = array{AirVent1, AirVent2, AirVent3, AirVent4, AirVent5, AirVent6, AirVent7}
                Checkpoint1.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint2.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint3.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        Checkpoint4.FirstActivationPerAgentEvent.Subscribe(OnCheckpoint)
        spawn{WatchRespawn()}
        spawn{WatchWind()}

    OnCheckpoint(Agent:agent):void =
        Print("sfx_manager: checkpoint sound")
        CheckpointSfx.Play(Agent)

    WatchRespawn()<suspends>:void =
        loop:
            Sleep(0.25)
            for (Player : GetPlayspace().GetPlayers()):
                Alive:logic = if (Char := Player.GetFortCharacter[], Char.IsActive[]) then true else false
                if (Was := WasAlive[Player], Was = true, Alive = false):
                    Print("sfx_manager: death sound")
                    FallSfx.Play(Player)
                if (Was := WasAlive[Player], Was = false, Alive = true):
                    Print("sfx_manager: respawn sound")
                    RespawnSfx.Play(Player)
                if (set WasAlive[Player] = Alive) {}

    WatchWind()<suspends>:void =
        loop:
            Sleep(0.1)
            Now := GetSimulationElapsedTime()
            # 플레이어 위치는 틱마다 한 번만 읽어서 에어벤트 7개가 같이 쓴다.
            var Snaps:[]player_snap = array{}
            for (Player : GetPlayspace().GetPlayers()):
                if (Char := Player.GetFortCharacter[], Char.IsActive[]):
                    set Snaps += array{player_snap{Player := Player, Pos := Char.GetTransform().Translation}}
            for (V : Vents):
                T := V.GetTransform()
                Pos := T.Translation
                S := T.Scale.Z
                R := RadiusCmPerScale * S
                H := GustCmPerScale * S
                for (Snap : Snaps):
                    Player := Snap.Player
                    P := Snap.Pos
                    DX := P.X - Pos.X
                    DY := P.Y - Pos.Y
                    if (Sqrt(DX * DX + DY * DY) < R, P.Z > Pos.Z - 50.0, P.Z < Pos.Z + H + 100.0):
                        Ready:logic = if (Last := LastWind[Player], Now - Last < WindCooldown) then false else true
                        if (Ready = true):
                            if (set LastWind[Player] = Now) {}
                            Print("sfx_manager: wind sound")
                            WindSfx.Play(Player)
