/*
    init.sqf
    Runs at mission start
    
    NOTE: Playable units must be placed in the Eden Editor for multiplayer lobby.
    Place 10 riflemen anywhere, set them as "Playable", and save.
    The onPlayerRespawn.sqf will handle positioning and loadout.
*/

diag_log "pubgdm mission initialized";

// End mission after timer
[] spawn {
    sleep (60*20);  // seconds
    "END1" call BIS_fnc_endMission;
};

// Get zone radius from marker
private _marker = "respawnPoint_1";
private _radius = [_marker] call MyRespawn_fnc_getZoneRadius;

diag_log format ["Zone radius from marker: %1m", _radius];

// Start zone control system
// Parameters: [marker, radius, damage per tick, tick interval, warning seconds]
[_marker, _radius, 0.05, 1, 5] spawn MyRespawn_fnc_zoneControl;

// Start air drop system (periodic drops)
[_marker, _radius] spawn {
    params ["_marker", "_radius"];
    private _dropInterval = 180;  // Seconds between drops (3 minutes)
    private _initialDelay = 5;    // First drop after 5 seconds (for testing)
    
    sleep _initialDelay;
    
    while {true} do {
        // Spawn air drop
        [_marker, _radius] call MyRespawn_fnc_airDrop;
        
        // Wait for next drop
        sleep _dropInterval;
    };
};
