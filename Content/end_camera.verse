using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 카메라 위치와 보는 방향.
end_camera_pose := struct:
    Pos:vector3
    Rot:rotation

# 골인했거나 시간이 끝난 플레이어의 카메라가, 따라다니던 시점에서 캐릭터 가까이 다가가며 아래에서 위를 올려다보는 각도로 캐릭터 주변을 돈다.
# 화면 UI는 그대로이고 카메라 시점만 움직인다.
# 플레이어마다 고정 위치 카메라(Fixed Point Camera) 장치를 하나씩 배정해서, Verse가 장치를 캐릭터 둘레로 옮긴다. 장치는 최대 16개다.
# 회전 시간은 호출할 때 정한다. race_manager가 결과 화면 시간(ResultSeconds)을 넘겨서, 게임이 끝날 때 딱 Turns바퀴를 돌게 한다.
end_camera := class(creative_device):

    @editable
    Cam1:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam2:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam3:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam4:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam5:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam6:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam7:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam8:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam9:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam10:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam11:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam12:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam13:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam14:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam15:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    @editable
    Cam16:gameplay_camera_fixed_point_device = gameplay_camera_fixed_point_device{}

    # 도는 바퀴 수.
    @editable
    Turns:float = 2.0

    # 카메라와 캐릭터 사이 거리(cm). 처음에는 StartRadiusCm에서 시작해 ApproachSeconds 동안 EndRadiusCm까지 가까워진다.
    @editable
    StartRadiusCm:float = 500.0

    @editable
    EndRadiusCm:float = 240.0

    @editable
    ApproachSeconds:float = 2.0

    # 카메라가 캐릭터 중심보다 낮은 높이(cm)와, 카메라가 바라보는 점이 캐릭터 중심보다 높은 높이(cm). 클수록 더 많이 올려다본다.
    @editable
    CameraBelowCm:float = 60.0

    @editable
    LookAtAboveCm:float = 40.0

    # 카메라를 옮기는 간격(초)과, 그 간격보다 길게 잡는 이동 시간(초). 이동 시간이 길수록 부드럽게 이어진다.
    @editable
    StepSeconds:float = 0.05

    @editable
    LookaheadSeconds:float = 0.12

    var Cams:[]gameplay_camera_fixed_point_device = array{}
    var Slots:[player]int = map{}
    var Generation:int = 0

    OnBegin<override>()<suspends>:void =
        set Cams = array{Cam1, Cam2, Cam3, Cam4, Cam5, Cam6, Cam7, Cam8, Cam9, Cam10, Cam11, Cam12, Cam13, Cam14, Cam15, Cam16}
    # 플레이어의 카메라 회전을 시작한다. 이미 돌고 있으면 무시한다. Seconds 동안 Turns바퀴를 돌고, 그 뒤에는 멈춘 각도로 캐릭터를 따라간다.
    Start<public>(Player:player, Seconds:float):void =
        if (not Slots[Player]):
            var Free:int = -1
            for (I := 0..Cams.Length - 1):
                var Taken:logic = false
                for (Who -> Used : Slots, Used = I):
                    set Taken = true
                if (Taken = false, Free < 0):
                    set Free = I
            if (Free >= 0):
                if (set Slots[Player] = Free) {}
                spawn{RunOrbit(Player, Free, Max(0.1, Seconds), Generation)}

    # 모든 플레이어의 카메라를 원래대로 되돌린다. 새 라운드가 시작할 때 부른다.
    StopAll<public>():void =
        set Generation += 1
        for (Who -> I : Slots):
            if (Cam := Cams[I]):
                Cam.RemoveFrom(Who)
        set Slots = map{}

    CameraPose(Center:vector3, Angle:float, Radius:float):end_camera_pose =
        Pos := vector3{X := Center.X + Radius * Cos(Angle), Y := Center.Y + Radius * Sin(Angle), Z := Center.Z - CameraBelowCm}
        DX := Center.X - Pos.X
        DY := Center.Y - Pos.Y
        DZ := (Center.Z + LookAtAboveCm) - Pos.Z
        Yaw := ArcTan(DY, DX) * 180.0 / PiFloat
        Pitch := ArcTan(DZ, Sqrt(DX * DX + DY * DY)) * 180.0 / PiFloat
        return end_camera_pose{Pos := Pos, Rot := MakeRotationFromYawPitchRollDegrees(Yaw, Pitch, 0.0)}

    RunOrbit(Player:player, Index:int, Seconds:float, MyGeneration:int)<suspends>:void =
        if (Cam := Cams[Index]):
            var Center:vector3 = vector3{X := 0.0, Y := 0.0, Z := 0.0}
            var Angle0:float = 0.0
            # 캐릭터가 살아 있을 때까지 기다렸다가, 캐릭터 뒤쪽(지금 따라다니는 카메라가 있는 쪽)에서 시작한다.
            loop:
                if (Generation <> MyGeneration):
                    return
                if (Char := Player.GetFortCharacter[], Char.IsActive[]):
                    set Center = Char.GetTransform().Translation
                    Fwd := Char.GetTransform().Rotation.RotateVector(vector3{X := 1.0, Y := 0.0, Z := 0.0})
                    set Angle0 = ArcTan(Fwd.Y, Fwd.X) + PiFloat
                    break
                Sleep(0.1)
            First := CameraPose(Center, Angle0, StartRadiusCm)
            if (Cam.TeleportTo[First.Pos, First.Rot]) {}
            Cam.AddTo(Player)
            Begin := GetSimulationElapsedTime()
            loop:
                if (Generation <> MyGeneration):
                    break
                if (Char := Player.GetFortCharacter[], Char.IsActive[]):
                    set Center = Char.GetTransform().Translation
                T := GetSimulationElapsedTime() - Begin + LookaheadSeconds
                Frac := Min(1.0, T / Seconds)
                Approach := Min(1.0, T / Max(0.1, ApproachSeconds))
                Smooth := Approach * Approach * (3.0 - 2.0 * Approach)
                Radius := StartRadiusCm + (EndRadiusCm - StartRadiusCm) * Smooth
                Angle := Angle0 + Turns * 2.0 * PiFloat * Frac
                Pose := CameraPose(Center, Angle, Radius)
                spawn{MoveCam(Cam, Pose.Pos, Pose.Rot)}
                Sleep(StepSeconds)

    MoveCam(Cam:gameplay_camera_fixed_point_device, Pos:vector3, Rot:rotation)<suspends>:void =
        Cam.MoveTo(Pos, Rot, LookaheadSeconds)
