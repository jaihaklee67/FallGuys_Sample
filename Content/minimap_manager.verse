using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 우측 상단 미니맵에 플레이어마다 서로 다른 색의 작은 동그라미를 띄운다.
# 팀이 없는 자유 대결에서는 본인만 화살표로 보이므로, 지도 표시 장치(Map Indicator)를 플레이어에게 붙여서 따라다니게 한다.
# 장치는 최대 8개이고, 플레이어마다 빈 장치를 하나씩 배정한다. 색과 동그라미 이미지는 장치 설정에서 정한다.
minimap_manager := class(creative_device):

    @editable
    Marker1:map_indicator_device = map_indicator_device{}

    @editable
    Marker2:map_indicator_device = map_indicator_device{}

    @editable
    Marker3:map_indicator_device = map_indicator_device{}

    @editable
    Marker4:map_indicator_device = map_indicator_device{}

    @editable
    Marker5:map_indicator_device = map_indicator_device{}

    @editable
    Marker6:map_indicator_device = map_indicator_device{}

    @editable
    Marker7:map_indicator_device = map_indicator_device{}

    @editable
    Marker8:map_indicator_device = map_indicator_device{}

    # 위치를 갱신하는 간격 (초).
    @editable
    UpdateSeconds:float = 0.15

    var Markers:[]map_indicator_device = array{}
    var Owners:[int]player = map{}

    OnBegin<override>()<suspends>:void =
        set Markers = array{Marker1, Marker2, Marker3, Marker4, Marker5, Marker6, Marker7, Marker8}
        for (M : Markers):
            M.Disable()
        loop:
            Sleep(UpdateSeconds)
            Refresh()

    Refresh():void =
        Players := GetPlayspace().GetPlayers()
        # 나간 플레이어의 장치는 끄고 비운다.
        var Next:[int]player = map{}
        for (I -> Owner : Owners):
            if (Players.Find[Owner]):
                if (set Next[I] = Owner) {}
            else:
                if (M := Markers[I]):
                    M.Disable()
        set Owners = Next
        # 장치가 없는 플레이어에게 빈 장치를 하나 배정한다.
        for (P : Players):
            var Has:logic = false
            for (I -> Owner : Owners, Owner = P):
                set Has = true
            if (Has = false):
                var Free:int = -1
                for (I := 0..Markers.Length - 1):
                    if (Free < 0, not Owners[I]):
                        set Free = I
                if (Free >= 0, M := Markers[Free]):
                    if (set Owners[Free] = P) {}
                    M.Enable()
        # 배정된 장치를 플레이어 위치로 옮긴다.
        for (I -> Owner : Owners):
            if (M := Markers[I], Char := Owner.GetFortCharacter[], Char.IsActive[]):
                if (M.TeleportTo[Char.GetTransform().Translation, MakeRotationFromYawPitchRollDegrees(0.0, 0.0, 0.0)]) {}
