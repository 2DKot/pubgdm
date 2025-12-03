/*
    Automatically called when the player respawns.
    Calls the random HALO spawn and random loadout functions.
*/

private _markerName = "respawnPoint_1"; // name of your marker
private _radius = 200;                  // max spawn radius

// [_markerName, _radius] call MyRespawn_fnc_randomRespawn;
call MyRespawn_fnc_randomLoadout;
