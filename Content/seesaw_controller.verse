using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 시소 위에 올려서 시소와 함께 기울어지며 움직이는 범퍼 기둥 하나. 고정형이거나 시소 중심을 도는 공전형이다.
seesaw_hazard := class():
    Prop:creative_prop
    # 0 = 첫 번째 시소, 1 = 두 번째 시소
    Seesaw:int
    # true면 시소 중심을 공전한다.
    Orbit:logic
    # 고정형: 시소 폭 방향(왼쪽 -, 오른쪽 +), 길이 방향 위치 (cm). 시소 중심 기준.
    LocalU:float
    LocalV:float
    # 공전형: 시작 각도 (도), 중심에서 거리 (cm), 한 바퀴 도는 시간 (초), 방향 (+1 = 한 방향, -1 = 반대 방향).
    PhaseDeg:float
    Radius:float
    Period:float
    Dir:float
    var PrevX:float = 0.0
    var PrevY:float = 0.0
    var HasPrev:logic = false

# 시소 바닥을 중심축(Scaffold Hori 4s / 4s4, X=680, 높이 8594)을 기준으로 좌우로 흔드는 컨트롤러.
# Floors[0] = FG01 Window Narrow 2s A (첫 번째 시소 바닥), Floors[1] = FG01 Window Narrow 2s A2 (두 번째 시소 바닥)
# 시소 위 장애물: 첫 번째 시소는 고정 범퍼 기둥 2개, 두 번째 시소는 중심을 도는 기둥 2개. 닿으면 튕겨낸다.
seesaw_controller := class(creative_device):

    @editable
    Floors:[]creative_prop = array{}

    # 수평 기준으로 한쪽으로 기우는 최대 각도 (도).
    @editable
    MaxTiltDegrees:float = 28.0

    # 한 번 왕복하는 데 걸리는 시간 (초). 0번 = 첫 번째 시소, 1번 = 두 번째 시소.
    @editable
    PeriodSeconds:[]float = array{4.2, 3.4}

    # 시소별 시작 위상 (도). 0번은 0도, 1번은 180도로 두 시소가 정반대 박자로 움직인다.
    @editable
    PhaseDegrees:[]float = array{0.0, 180.0}

    # 새 목표를 내리는 간격 (초).
    @editable
    StepSeconds:float = 0.05

    # 목표 자세를 얼마나 앞(초)에서 잡을지. 새 이동이 이전 이동을 끊고 이어가므로 멈춤 없이 부드럽게 이어진다.
    @editable
    LookaheadSeconds:float = 0.25

    # 시소 위 기둥 4개 (Bumper Pole). Pole1, Pole2 = 첫 번째 시소(고정), Pole3, Pole4 = 두 번째 시소(공전).
    @editable
    Pole1:creative_prop = creative_prop{}

    @editable
    Pole2:creative_prop = creative_prop{}

    @editable
    Pole3:creative_prop = creative_prop{}

    @editable
    Pole4:creative_prop = creative_prop{}

    # 바깥쪽 공전 기둥 4개. Pole5, Pole6 = 첫 번째 시소, Pole7, Pole8 = 두 번째 시소.
    @editable
    Pole5:creative_prop = creative_prop{}

    @editable
    Pole6:creative_prop = creative_prop{}

    @editable
    Pole7:creative_prop = creative_prop{}

    @editable
    Pole8:creative_prop = creative_prop{}

    # 튕김용 바운서 2개. 평소에는 멀리 숨겨두고, 기둥에 닿은 플레이어 밑으로 잠깐 옮겨온다.
    @editable
    BouncerA:bouncer_device = bouncer_device{}

    # 튀길 때 튀긴 플레이어에게만 들리는 효과음(Audio Player, Instigator Only).
    @editable
    BounceSfx:audio_player_device = audio_player_device{}

    @editable
    BouncerB:bouncer_device = bouncer_device{}

    # 안쪽 공전 기둥 한 쌍: 시소 중심을 한 바퀴 도는 시간 (초), 중심에서 기둥까지 거리 (cm).
    @editable
    OrbitPeriodSeconds:float = 8.0

    @editable
    OrbitRadiusCm:float = 1300.0

    # 바깥쪽 공전 기둥 한 쌍 (안쪽과 반대 방향, 시작 각도를 90도 어긋나게 해서 시간차를 둔다). 시소 폭 절반(2560) 안에 들어와야 한다.
    # 안쪽과 비슷한 속도로 돌도록 반지름이 크면 시간도 더 길게 잡는다.
    @editable
    OuterOrbitPeriodSeconds:float = 13.5

    @editable
    OuterOrbitRadiusCm:float = 2200.0

    # 튕겨내는 각도(수평 위로 들리는 각도, 도), 바운서 유지 시간(초), 바운서를 플레이어 발밑 얼마나 아래에 둘지(cm), 연속 튕김 방지 시간(초).
    @editable
    LaunchElevationDeg:float = 25.0

    @editable
    ActiveSeconds:float = 0.35

    @editable
    BelowPlayerCm:float = 60.0

    @editable
    Cooldown:float = 0.8

    # 기둥 반지름, 길이(기준점에서 위쪽 끝까지), 캐릭터 반지름, 여유 (cm).
    @editable
    PoleRadiusCm:float = 103.0

    @editable
    PoleHeightCm:float = 495.0

    @editable
    PlayerRadiusCm:float = 40.0

    @editable
    ContactMarginCm:float = 5.0

    # 축에서 바닥 기준점까지의 거리 (cm). 바닥 액터 기준점이 왼쪽 끝에 있어서 2560.
    ArmCm:float = 2560.0
    AxisX:float = 680.0
    AxisZ:float = 8594.0
    # 시소 바닥 길이의 절반(액터 기준점이 한쪽 끝에 있다), 바닥 윗면이 축에서 위로 떠 있는 높이 (cm).
    SlabHalfLengthCm:float = 3413.5
    SurfaceOffsetCm:float = 130.0

    var Hazards:[]seesaw_hazard = array{}
    var Snaps:[]player_snap = array{}
    var BouncerList:[]bouncer_device = array{}
    var ParkTransforms:[]transform = array{}
    var NextBouncer:int = 0
    var LastHitTime:[agent]float = map{}

    OnBegin<override>()<suspends>:void =
        Print("seesaw_controller: floors={Floors.Length}")
        set Hazards = array{
            seesaw_hazard{Prop := Pole1, Seesaw := 0, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 0.0, Radius := OrbitRadiusCm, Period := OrbitPeriodSeconds, Dir := 1.0},
            seesaw_hazard{Prop := Pole2, Seesaw := 0, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 180.0, Radius := OrbitRadiusCm, Period := OrbitPeriodSeconds, Dir := 1.0},
            seesaw_hazard{Prop := Pole3, Seesaw := 1, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 0.0, Radius := OrbitRadiusCm, Period := OrbitPeriodSeconds, Dir := 1.0},
            seesaw_hazard{Prop := Pole4, Seesaw := 1, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 180.0, Radius := OrbitRadiusCm, Period := OrbitPeriodSeconds, Dir := 1.0},
            seesaw_hazard{Prop := Pole5, Seesaw := 0, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 90.0, Radius := OuterOrbitRadiusCm, Period := OuterOrbitPeriodSeconds, Dir := -1.0},
            seesaw_hazard{Prop := Pole6, Seesaw := 0, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 270.0, Radius := OuterOrbitRadiusCm, Period := OuterOrbitPeriodSeconds, Dir := -1.0},
            seesaw_hazard{Prop := Pole7, Seesaw := 1, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 90.0, Radius := OuterOrbitRadiusCm, Period := OuterOrbitPeriodSeconds, Dir := -1.0},
            seesaw_hazard{Prop := Pole8, Seesaw := 1, Orbit := true, LocalU := 0.0, LocalV := 0.0, PhaseDeg := 270.0, Radius := OuterOrbitRadiusCm, Period := OuterOrbitPeriodSeconds, Dir := -1.0}}
        set BouncerList = array{BouncerA, BouncerB}
        for (B : BouncerList):
            set ParkTransforms += array{B.GetTransform()}
        for (Index -> Slab : Floors):
            spawn{RunSeesaw(Slab, Index)}
        spawn{WatchHazards()}

    RunSeesaw(Slab:creative_prop, Index:int)<suspends>:void =
        Y := Slab.GetTransform().Translation.Y
        Yc := Y - SlabHalfLengthCm
        Period := if (P := PeriodSeconds[Index]) then P else 6.0
        Phase := (if (Ph := PhaseDegrees[Index]) then Ph else 0.0) * PiFloat / 180.0
        Start := GetSimulationElapsedTime()
        loop:
            T := GetSimulationElapsedTime() - Start + LookaheadSeconds
            D := MaxTiltDegrees * Cos(2.0 * PiFloat * T / Period + Phase)
            Rad := D * PiFloat / 180.0
            Pos := vector3{X := AxisX - ArmCm * Cos(Rad), Y := Y, Z := AxisZ - ArmCm * Sin(Rad)}
            Rot := MakeRotationFromYawPitchRollDegrees(-90.0, 0.0, 90.0 - D)
            spawn{MoveSlab(Slab, Pos, Rot)}
            for (Hz : Hazards, Hz.Seesaw = Index):
                spawn{MoveHazard(Hz, D, Rad, T, Yc)}
            Sleep(StepSeconds)

    MoveSlab(Slab:creative_prop, Pos:vector3, Rot:rotation)<suspends>:void =
        Slab.MoveTo(Pos, Rot, LookaheadSeconds)

    # 기둥을 시소 윗면 위의 자기 자리로 옮긴다. 시소와 같은 기울기로 기울여 윗면에 수직으로 서 있게 한다.
    MoveHazard(Hz:seesaw_hazard, D:float, Rad:float, T:float, Yc:float)<suspends>:void =
        var LU:float = Hz.LocalU
        var LV:float = Hz.LocalV
        if (Hz.Orbit?):
            Ang := Hz.Dir * 2.0 * PiFloat * T / Hz.Period + Hz.PhaseDeg * PiFloat / 180.0
            set LU = Hz.Radius * Cos(Ang)
            set LV = Hz.Radius * Sin(Ang)
        Pos := vector3{X := AxisX + LU * Cos(Rad) - SurfaceOffsetCm * Sin(Rad), Y := Yc + LV, Z := AxisZ + LU * Sin(Rad) + SurfaceOffsetCm * Cos(Rad)}
        Rot := MakeRotationFromYawPitchRollDegrees(0.0, D, 0.0)
        Hz.Prop.MoveTo(Pos, Rot, LookaheadSeconds)

    # 기둥에 플레이어가 닿았는지 계속 확인한다.
    WatchHazards()<suspends>:void =
        loop:
            Sleep(0.03)
            RefreshSnaps()
            for (Hz : Hazards):
                CheckHazard(Hz)

    # 살아 있는 플레이어의 현재 위치를 한 번에 읽어 둔다(기둥 8개가 같이 쓴다).
    RefreshSnaps():void =
        var List:[]player_snap = array{}
        for (Player : GetPlayspace().GetPlayers()):
            if (Char := Player.GetFortCharacter[]):
                set List += array{player_snap{Player := Player, Pos := Char.GetTransform().Translation}}
        set Snaps = List

    CheckHazard(Hz:seesaw_hazard):void =
        T := Hz.Prop.GetTransform()
        Base := T.Translation
        Axis := T.Rotation.RotateVector(vector3{X := 0.0, Y := 0.0, Z := 1.0})
        MX := Base.X - Hz.PrevX
        MY := Base.Y - Hz.PrevY
        MLen := if (Hz.HasPrev?) then Sqrt(MX * MX + MY * MY) else 0.0
        set Hz.PrevX = Base.X
        set Hz.PrevY = Base.Y
        set Hz.HasPrev = true
        for (Snap : Snaps):
            Player := Snap.Player
            P := Snap.Pos
            DX := P.X - Base.X
            DY := P.Y - Base.Y
            DZ := P.Z - Base.Z
            Along := DX * Axis.X + DY * Axis.Y + DZ * Axis.Z
            PX := DX - Along * Axis.X
            PY := DY - Along * Axis.Y
            PZ := DZ - Along * Axis.Z
            Perp := Sqrt(PX * PX + PY * PY + PZ * PZ)
            if (Along > -80.0, Along < PoleHeightCm + 60.0, Perp <= PoleRadiusCm + PlayerRadiusCm + ContactMarginCm):
                HLen := Sqrt(DX * DX + DY * DY)
                if (HLen > 0.01):
                    # 기본은 기둥에서 멀어지는 방향. 기둥이 빠르게 움직이고 있으면 움직이는 방향을 섞어서 휩쓸려 날아가게 한다.
                    var OutX:float = DX / HLen
                    var OutY:float = DY / HLen
                    if (MLen > 3.0):
                        set OutX = OutX + 0.8 * MX / MLen
                        set OutY = OutY + 0.8 * MY / MLen
                    OLen := Sqrt(OutX * OutX + OutY * OutY)
                    if (OLen > 0.01):
                        TryKnockback(Player, OutX / OLen, OutY / OLen)

    # 효과음은 Audio Player(Instigator Only)로 맞은 플레이어에게만 들려준다.
    PlaySfxAt(Sfx:audio_player_device, Agent:agent):void =
        Sfx.Play(Agent)

    TryKnockback(Agent:agent, DirX:float, DirY:float):void =
        Now := GetSimulationElapsedTime()
        if (Last := LastHitTime[Agent], Now - Last < Cooldown):
            return
        if (set LastHitTime[Agent] = Now):
            spawn{RunKnockback(Agent, DirX, DirY)}

    # flipper_knockback과 같은 방식: 바운서를 플레이어 위치로 옮겨 튕길 방향으로 기울인 뒤 잠깐 터뜨리고 되돌린다.
    RunKnockback(Agent:agent, DirX:float, DirY:float)<suspends>:void =
        if (BouncerList.Length > 0, Index := Mod[NextBouncer, BouncerList.Length], Bouncer := BouncerList[Index], Park := ParkTransforms[Index], Char := Agent.GetFortCharacter[]):
            set NextBouncer += 1
            P := Char.GetTransform().Translation
            Elev := LaunchElevationDeg * PiFloat / 180.0
            Ux := DirX * Cos(Elev)
            Uy := DirY * Cos(Elev)
            Uz := Sin(Elev)
            Horiz := Sqrt(Ux * Ux + Uy * Uy)
            Axis := vector3{X := 0.0 - Uy / Horiz, Y := Ux / Horiz, Z := 0.0}
            Angle := ArcCos(Uz)
            var Rot:rotation = MakeRotation(Axis, Angle)
            Up := Rot.RotateVector(vector3{X := 0.0, Y := 0.0, Z := 1.0})
            if (Up.X * Ux + Up.Y * Uy + Up.Z * Uz < 0.99):
                set Rot = MakeRotation(Axis, 0.0 - Angle)
            Pos := vector3{X := P.X, Y := P.Y, Z := P.Z - BelowPlayerCm}
            if (Bouncer.TeleportTo[Pos, Rot]):
                PlaySfxAt(BounceSfx, Agent)
                Sleep(ActiveSeconds)
                if (Bouncer.TeleportTo[Park.Translation, Park.Rotation]):
                    Print("seesaw_controller: bounced")
