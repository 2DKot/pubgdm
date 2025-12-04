/*
    Automatically called when the player respawns.
    Calls the random HALO spawn and random loadout functions.
*/

private _markerName = "respawnPoint_1";
private _radius = [_markerName] call MyRespawn_fnc_getZoneRadius;

[_markerName, _radius] call MyRespawn_fnc_randomRespawn;
call MyRespawn_fnc_randomLoadout;
