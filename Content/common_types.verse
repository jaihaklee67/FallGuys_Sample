using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# 여러 장치가 같이 쓰는 타입을 모아 둔 파일.

# 한 틱 동안 모든 장애물이 같이 쓰는 플레이어 위치 한 칸. 장애물마다 위치를 다시 읽지 않도록 틱 시작에 한 번만 만든다.
player_snap := struct:
    Player:player
    Pos:vector3
