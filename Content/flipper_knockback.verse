using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 플리퍼 하나의 회전 방향 추적용 상태.
flipper_state := class():
    Flipper:creative_prop
    var PrevAxis:vector3
    var Sign:float = 1.0

# 기둥 하나의 이동 방향 추적용 상태.
pole_state := class():
    Pole:creative_prop
    var PrevPos:vector3
    var DirX:float = 0.0
    var DirY:float = 1.0

# 주먹을 움직이는 프롭 무버가 플레이어를 칠 때 알려주는 연결 객체.
fist_binding := class():
    Owner:flipper_knockback
    Mover:prop_mover_device

    OnHit(Agent:agent):void =
        Owner.FistHit(Agent, Mover)

# 핀볼 플리퍼와 기둥이 플레이어에 닿았을 때, 장애물이 움직이는 방향으로 튕겨낸다.
# - 플리퍼: 피벗 쪽 큰 원 ~ 반대쪽 작은 원을 잇는 실제 윤곽, 회전 중심 기준 접선 방향.
# - 기둥: 원기둥 반지름, 프롤의 실제 이동 방향(회전 바닥 중심을 도는 접선 방향).
# 캐릭터를 순간이동시키면 카메라가 리셋되어 클로즈업되므로, 대신 바운서 장치를 플레이어 위치로
# 옮겨 튕길 방향으로 기울인 뒤 잠깐 터뜨리고 원래 위치로 되돌린다. (캐릭터는 이동하지 않고 물리로 날아감)
flipper_knockback := class(creative_device):

    # 플리퍼 프롭들 (PinballFlipper 4개). 순서는 상관없다.
    @editable
    Flippers:[]creative_prop = array{}

    # 기둥 프롭들 (Bumper Pole 6개). 순서는 상관없다.
    @editable
    Poles:[]creative_prop = array{}

    # 튀길 때 튀긴 플레이어에게만 들리는 효과음(Audio Player, Instigator Only).
    @editable
    BounceSfx:audio_player_device = audio_player_device{}

    # 주먹 프롭들 (FG01 Puncher Glove 6개). 프롭의 로컬 +Y 방향이 주먹이 뻗는 방향(왼쪽 벽이 +X, 오른쪽 벽이 -X)이고, 그 끝면(빗금 무늬 면)에 닿으면 튕겨낸다.
    @editable
    Fist1:creative_prop = creative_prop{}

    @editable
    Fist2:creative_prop = creative_prop{}

    @editable
    Fist3:creative_prop = creative_prop{}

    @editable
    Fist4:creative_prop = creative_prop{}

    @editable
    Fist5:creative_prop = creative_prop{}

    @editable
    Fist6:creative_prop = creative_prop{}

    # 주먹을 움직이는 프롭 무버(PM_Fist_1~6). 무버가 플레이어를 치면 무버의 정면 방향(왼쪽 +X, 오른쪽 -X)으로 튀겨낸다.
    @editable
    Mover1:prop_mover_device = prop_mover_device{}

    @editable
    Mover2:prop_mover_device = prop_mover_device{}

    @editable
    Mover3:prop_mover_device = prop_mover_device{}

    @editable
    Mover4:prop_mover_device = prop_mover_device{}

    @editable
    Mover5:prop_mover_device = prop_mover_device{}

    @editable
    Mover6:prop_mover_device = prop_mover_device{}

    # 튕김용 바운서 풀 (BNC_KB_1~4). 세기는 바운서의 Bounce Launch Value로 정한다.
    @editable
    Bouncers:[]bouncer_device = array{}

    # 튕겨내는 각도: 수평에서 위로 들리는 각도 (도).
    @editable
    LaunchElevationDeg:float = 25.0

    # 바운서를 플레이어 위치에 두는 시간 (초).
    @editable
    ActiveSeconds:float = 0.35

    # 바운서를 플레이어 발밑 기준 얼마나 아래에 둔지 (cm).
    @editable
    BelowPlayerCm:float = 60.0

    # 같은 플레이어가 연속으로 튕기는 것을 막는 대기 시간 (초).
    @editable
    Cooldown:float = 0.8

    # 캐릭터 몸통 반지름 (cm). 윤곽 표면에서 이 거리 안이면 닿은 것으로 본다.
    @editable
    PlayerRadiusCm:float = 40.0

    # 닿음 판정 여유 (cm). 더 "밀착"하게 하려면 줄인다.
    @editable
    ContactMarginCm:float = 5.0

    # 플레이어 위치를 검사하는 간격 (초).
    @editable
    TickSeconds:float = 0.03

    # 플리퍼 윤곽: 피벗에서 큰 원 중심까지 앞쪽 거리, 큰 원 반지름, 작은 원 중심까지 길이, 작은 원 반지름 (cm).
    @editable
    BigCircleOffsetCm:float = 17.0

    @editable
    BigCircleRadiusCm:float = 300.0

    @editable
    TipLengthCm:float = 1200.0

    @editable
    TipCircleRadiusCm:float = 108.0

    # 플리퍼 높이 기준으로 검사할 세로 범위 (cm).
    @editable
    ZBelowCm:float = 250.0

    @editable
    ZAboveCm:float = 300.0

    # 기둥 반지름 (cm)과, 기둥 기준점 높이로 검사할 세로 범위 (cm).
    @editable
    PoleRadiusCm:float = 103.0

    @editable
    PoleZBelowCm:float = 150.0

    @editable
    PoleZAboveCm:float = 500.0

    # 기둥이 회전판 중심으로 모였다가 퍼지는 움직임. 회전판 중심(cm), 회전판이 한 바퀴 도는 시간(PM_Turntable_Base와 같은 20초),
    # 모였다가 퍼지는 한 주기(초), 기둥 중심이 움직이는 범위(중심에서의 거리, cm), 움직임 갱신 간격과 미리 가는 시간(초).
    # 범위는 파란 바닥 안쪽만 쓰도록 정했다: 가운데 빨간 원(반지름 약 515) 바깥 + 기둥 반지름 103 + 여유 = 660,
    # 파란 바닥 바깥 가장자리(반지름 약 1410) 안쪽 − 기둥 반지름 − 여유 = 1280.
    @editable
    TurntableCenter:vector3 = vector3{X := 444.0, Y := 7996.0, Z := 0.0}

    @editable
    TurntableSeconds:float = 20.0

    @editable
    PulseSeconds:float = 8.0

    @editable
    PoleMinRadiusCm:float = 660.0

    @editable
    PoleMaxRadiusCm:float = 1280.0

    @editable
    PoleStepSeconds:float = 0.1

    @editable
    PoleLookaheadSeconds:float = 0.15

    # 주먹 프롭 기준점(손목 쪽 끝)에서 끝면까지의 길이, 면의 좌우 반폭, 기준점 높이 기준 아래/위 범위 (cm).
    @editable
    FistTipLengthCm:float = 1959.0

    @editable
    FistHalfWidthCm:float = 560.0

    @editable
    FistZBelowCm:float = 560.0

    @editable
    FistZAboveCm:float = 560.0

    # 끝면 앞으로 이 깊이(cm) 안쪽까지만 닿은 것으로 본다.
    @editable
    FistFaceDepthCm:float = 300.0

    var LastHitTime:[agent]float = map{}
    var Snaps:[]player_snap = array{}
    var NextBouncer:int = 0
    var ParkTransforms:[]transform = array{}

    OnBegin<override>()<suspends>:void =
        for (B : Bouncers):
            set ParkTransforms += array{B.GetTransform()}
        var FlipperStates:[]flipper_state = array{}
        for (F : Flippers):
            set FlipperStates += array{flipper_state{Flipper := F, PrevAxis := F.GetTransform().Rotation.RotateVector(vector3{X := 0.0, Y := 1.0, Z := 0.0})}}
        var PoleStates:[]pole_state = array{}
        for (Pole : Poles):
            set PoleStates += array{pole_state{Pole := Pole, PrevPos := Pole.GetTransform().Translation}}
        Fists := array{Fist1, Fist2, Fist3, Fist4, Fist5, Fist6}
        for (M : array{Mover1, Mover2, Mover3, Mover4, Mover5, Mover6}):
            Binding := fist_binding{Owner := Self, Mover := M}
            M.AgentHitEvent.Subscribe(Binding.OnHit)
        Print("flipper_knockback: flippers={FlipperStates.Length} poles={PoleStates.Length} fists={Fists.Length} bouncers={Bouncers.Length}")
        for (Pole : Poles):
            spawn{PulsePole(Pole)}
        loop:
            Sleep(TickSeconds)
            RefreshSnaps()
            for (S : FlipperStates):
                CheckFlipper(S)
            for (S : PoleStates):
                CheckPole(S)
            for (F : Fists):
                CheckFist(F)

    # 기둥 하나를 회전판과 같은 속도로 돌리면서, 회전판 중심으로 모였다가 다시 퍼지게 한다.
    # 시작 위치의 각도를 기준으로 하고, 시소와 같은 방식(앞으로 갈 자리를 MoveTo)으로 움직인다.
    # 중심에서의 거리는 파란 바닥 범위(PoleMinRadiusCm ~ PoleMaxRadiusCm) 안에서만 오가고, 시작할 때 튀지 않도록 현재 거리에서 이어서 시작한다.
    PulsePole(Pole:creative_prop)<suspends>:void =
        Start := Pole.GetTransform()
        DX := Start.Translation.X - TurntableCenter.X
        DY := Start.Translation.Y - TurntableCenter.Y
        NearCm := PoleMinRadiusCm
        FarCm := Max(PoleMaxRadiusCm, PoleMinRadiusCm + 1.0)
        Spread0 := Max(0.0, Min(1.0, (Sqrt(DX * DX + DY * DY) - NearCm) / (FarCm - NearCm)))
        Phase0 := ArcCos(2.0 * Spread0 - 1.0)
        Angle0 := ArcTan(DY, DX)
        T0 := GetSimulationElapsedTime()
        loop:
            T := GetSimulationElapsedTime() - T0 + PoleLookaheadSeconds
            Angle := Angle0 + 2.0 * PiFloat * T / TurntableSeconds
            Spread := 0.5 + 0.5 * Cos(2.0 * PiFloat * T / PulseSeconds + Phase0)
            R := NearCm + (FarCm - NearCm) * Spread
            Pos := vector3{X := TurntableCenter.X + R * Cos(Angle), Y := TurntableCenter.Y + R * Sin(Angle), Z := Start.Translation.Z}
            spawn{MovePole(Pole, Pos, Start.Rotation)}
            Sleep(PoleStepSeconds)

    MovePole(Pole:creative_prop, Pos:vector3, Rot:rotation)<suspends>:void =
        Pole.MoveTo(Pos, Rot, PoleLookaheadSeconds)

    # 살아 있는 플레이어의 현재 위치를 한 번에 읽어 둔다.
    RefreshSnaps():void =
        var List:[]player_snap = array{}
        for (Player : GetPlayspace().GetPlayers()):
            if (Char := Player.GetFortCharacter[]):
                set List += array{player_snap{Player := Player, Pos := Char.GetTransform().Translation}}
        set Snaps = List

    # 프롭 무버가 플레이어를 쳐서 알려왔을 때: 무버 디바이스의 +X 축(이동 방향)으로 튀겨낸다.
    FistHit<public>(Agent:agent, Mover:prop_mover_device):void =
        Fwd := Mover.GetTransform().Rotation.RotateVector(vector3{X := 1.0, Y := 0.0, Z := 0.0})
        HLen := Sqrt(Fwd.X * Fwd.X + Fwd.Y * Fwd.Y)
        if (HLen > 0.01):
            TryKnockback(Agent, Fwd.X / HLen, Fwd.Y / HLen)

    # 주먹: 프롭의 +Y 축이 뾸는 방향. 끝면 앞 사각 영역에 플레이어가 들어오면 그 방향으로 튀겨낸다.
    CheckFist(F:creative_prop):void =
        T := F.GetTransform()
        Fwd := T.Rotation.RotateVector(vector3{X := 0.0, Y := 1.0, Z := 0.0})
        HLen := Sqrt(Fwd.X * Fwd.X + Fwd.Y * Fwd.Y)
        if (HLen > 0.01):
            DirX := Fwd.X / HLen
            DirY := Fwd.Y / HLen
            SideX := 0.0 - DirY
            SideY := DirX
            Loc := T.Translation
            for (Snap : Snaps):
                Player := Snap.Player
                P := Snap.Pos
                DX := P.X - Loc.X
                DY := P.Y - Loc.Y
                Along := DX * DirX + DY * DirY
                Perp := DX * SideX + DY * SideY
                Reach := PlayerRadiusCm + ContactMarginCm
                if (Along > FistTipLengthCm - FistFaceDepthCm, Along < FistTipLengthCm + Reach, Perp > 0.0 - FistHalfWidthCm - PlayerRadiusCm, Perp < FistHalfWidthCm + PlayerRadiusCm, P.Z > Loc.Z - FistZBelowCm, P.Z < Loc.Z + FistZAboveCm):
                    TryKnockback(Player, DirX, DirY)

    CheckFlipper(S:flipper_state):void =
        T := S.Flipper.GetTransform()
        Axis := T.Rotation.RotateVector(vector3{X := 0.0, Y := 1.0, Z := 0.0})
        Cross := S.PrevAxis.X * Axis.Y - S.PrevAxis.Y * Axis.X
        if (Cross > 0.00001):
            set S.Sign = 1.0
        else if (Cross < -0.00001):
            set S.Sign = -1.0
        set S.PrevAxis = Axis
        Pivot := T.Translation
        CX := Pivot.X + Axis.X * BigCircleOffsetCm
        CY := Pivot.Y + Axis.Y * BigCircleOffsetCm
        SideX := 0.0 - Axis.Y
        SideY := Axis.X
        for (Snap : Snaps):
            Player := Snap.Player
            P := Snap.Pos
            DX := P.X - CX
            DY := P.Y - CY
            Along := DX * Axis.X + DY * Axis.Y
            Perp := DX * SideX + DY * SideY
            Frac := Max(0.0, Min(1.0, Along / TipLengthCm))
            Radius := BigCircleRadiusCm + (TipCircleRadiusCm - BigCircleRadiusCm) * Frac
            ExAlong := Along - Frac * TipLengthCm
            Dist := Sqrt(ExAlong * ExAlong + Perp * Perp) - Radius
            if (P.Z > Pivot.Z - ZBelowCm, P.Z < Pivot.Z + ZAboveCm, Dist <= PlayerRadiusCm + ContactMarginCm):
                RX := P.X - Pivot.X
                RY := P.Y - Pivot.Y
                TX := 0.0 - S.Sign * RY
                TY := S.Sign * RX
                Len := Sqrt(TX * TX + TY * TY)
                if (Len > 0.01):
                    TryKnockback(Player, TX / Len, TY / Len)

    CheckPole(S:pole_state):void =
        T := S.Pole.GetTransform()
        Pos := T.Translation
        MX := Pos.X - S.PrevPos.X
        MY := Pos.Y - S.PrevPos.Y
        MLen := Sqrt(MX * MX + MY * MY)
        if (MLen > 0.5):
            set S.DirX = MX / MLen
            set S.DirY = MY / MLen
        set S.PrevPos = Pos
        for (Snap : Snaps):
            Player := Snap.Player
            P := Snap.Pos
            DX := P.X - Pos.X
            DY := P.Y - Pos.Y
            Dist := Sqrt(DX * DX + DY * DY) - PoleRadiusCm
            if (P.Z > Pos.Z - PoleZBelowCm, P.Z < Pos.Z + PoleZAboveCm, Dist <= PlayerRadiusCm + ContactMarginCm):
                NLen := Sqrt(DX * DX + DY * DY)
                if (NLen > 0.01):
                    NX := DX / NLen
                    NY := DY / NLen
                    # 기둥이 움직이는 방향이 기둥 안쪽(플레이어 기준 기둥 쪽)을 향하면 기둥 뒤에서 닿은 경우이므로,
                    # 안쪽 성분을 빼고 바깥쪽 방향을 섞어 기둥에 막히지 않게 튕긴다. 360도 모든 방향에서 동작.
                    Facing := S.DirX * NX + S.DirY * NY
                    var OutX:float = S.DirX
                    var OutY:float = S.DirY
                    if (Facing < 0.0):
                        set OutX = (S.DirX - Facing * NX) * 0.5 + NX
                        set OutY = (S.DirY - Facing * NY) * 0.5 + NY
                        OLen := Sqrt(OutX * OutX + OutY * OutY)
                        if (OLen > 0.01):
                            set OutX = OutX / OLen
                            set OutY = OutY / OLen
                    TryKnockback(Player, OutX, OutY)

    # 효과음은 Audio Player(Instigator Only)로 맞은 플레이어에게만 들려준다.
    PlaySfxAt(Sfx:audio_player_device, Agent:agent):void =
        Sfx.Play(Agent)

    TryKnockback(Agent:agent, DirX:float, DirY:float):void =
        Now := GetSimulationElapsedTime()
        if (Last := LastHitTime[Agent], Now - Last < Cooldown):
            return
        if (set LastHitTime[Agent] = Now):
            spawn{RunKnockback(Agent, DirX, DirY)}

    RunKnockback(Agent:agent, DirX:float, DirY:float)<suspends>:void =
        if (Bouncers.Length > 0, Index := Mod[NextBouncer, Bouncers.Length], Bouncer := Bouncers[Index], Park := ParkTransforms[Index], Char := Agent.GetFortCharacter[]):
            set NextBouncer += 1
            P := Char.GetTransform().Translation
            Elev := LaunchElevationDeg * PiFloat / 180.0
            Ux := DirX * Cos(Elev)
            Uy := DirY * Cos(Elev)
            Uz := Sin(Elev)
            # 바운서의 위 방향(0,0,1)을 튕길 방향 U로 돌리는 회전. 회전 부호는 결과를 확인해서 바로잡는다.
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
                    Print("flipper_knockback: bounced")
