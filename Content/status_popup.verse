using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }
using { /jaihaklee@fortnite.com/FallGuys_Sample/UI }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

# 추락해서 탈락했을 때 화면 정중앙에 "ELIMINATED! 추락했어요!" 이미지를 띄우고,
# 다시 살아나기 직전 일정 시간만 "RESPAWN 잠시 후 다시 시작합니다!" 이미지로 바꾸고, 다시 살아나면 지운다.
# 살아 있는지는 sfx_manager와 같은 방법(0.25초마다 캐릭터 확인)으로 판단한다. 연결할 장치는 없다.
status_popup := class(creative_device):

    # 팝업 이미지의 가로 크기(race_manager의 ResultImageWidth와 같은 값이면 타임오버 화면과 같은 크기)와,
    # 화면 위에서 얼마나 내려오는지(0=맨 위, 0.5=정중앙, 1=맨 아래).
    @editable
    PopupWidth:float = 1000.0

    @editable
    PopupHeightRatio:float = 0.5

    # 추락해서 죽은 뒤 다시 살아나기까지 걸리는 시간(초). 이 게임의 로그에서 매번 3.73~3.75초였다.
    @editable
    ExpectedDeadSeconds:float = 3.75

    # 다시 살아나기 직전 이 시간(초) 동안만 "RESPAWN" 이미지를 보여준다. 그 전까지는 "ELIMINATED" 이미지를 보여준다.
    @editable
    RespawnShowSeconds:float = 1.5

    # 화면 UI 전체 크기 배율. race_manager의 HudScale과 같은 값으로 맞춘다.
    @editable
    HudScale:float = 1.0

    var WasAlive:[player]logic = map{}
    var DeadSince:[player]float = map{}
    var Popups:[player]canvas = map{}
    var ShowingRespawn:[player]logic = map{}

    OnBegin<override>()<suspends>:void =
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        loop:
            Sleep(0.25)
            Watch()

    OnPlayerRemoved(Player:player):void =
        HidePopup(Player)

    Watch():void =
        Now := GetSimulationElapsedTime()
        for (Player : GetPlayspace().GetPlayers()):
            Alive:logic = if (Char := Player.GetFortCharacter[], Char.IsActive[]) then true else false
            Was:logic = if (W := WasAlive[Player], W = false) then false else true
            if (Was = true, Alive = false):
                if (set DeadSince[Player] = Now) {}
                ShowPopup(Player, ui_eliminated)
                if (set ShowingRespawn[Player] = false) {}
            if (Alive = false, Was = false):
                Switched:logic = if (S := ShowingRespawn[Player], S = true) then true else false
                Since := if (D := DeadSince[Player]) then D else Now
                if (Switched = false, Now - Since >= ExpectedDeadSeconds - RespawnShowSeconds):
                    ShowPopup(Player, ui_respawn)
                    if (set ShowingRespawn[Player] = true) {}
            if (Alive = true):
                HidePopup(Player)
            if (set WasAlive[Player] = Alive) {}

    # 이미 떠 있는 팝업이 있으면 지우고 새 이미지를 띄운다. 두 이미지 모두 가로:세로 = 2:1.
    ShowPopup(Player:player, Image:texture):void =
        HidePopup(Player)
        if (PlayerUi := GetPlayerUI[Player]):
            Width := PopupWidth * HudScale
            Popup := canvas{Slots := array{canvas_slot{
                Anchors := anchors{Minimum := vector2{X := 0.5, Y := PopupHeightRatio}, Maximum := vector2{X := 0.5, Y := PopupHeightRatio}},
                Offsets := margin{},
                Alignment := vector2{X := 0.5, Y := 0.5},
                SizeToContent := true,
                Widget := texture_block{DefaultImage := Image, DefaultDesiredSize := vector2{X := Width, Y := Width / 2.0}}}}}
            PlayerUi.AddWidget(Popup)
            if (set Popups[Player] = Popup) {}

    HidePopup(Player:player):void =
        if (Popup := Popups[Player], PlayerUi := GetPlayerUI[Player]):
            PlayerUi.RemoveWidget(Popup)
            var Next:[player]canvas = map{}
            for (Other -> C : Popups, Other <> Player):
                if (set Next[Other] = C) {}
            set Popups = Next
