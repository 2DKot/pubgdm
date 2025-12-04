/*
    init.sqf
    Runs at mission start
    
    NOTE: Playable units must be placed in the Eden Editor for multiplayer lobby.
    Place 10 riflemen anywhere, set them as "Playable", and save.
    The onPlayerRespawn.sqf will handle positioning and loadout.
*/

diag_log "pubgdm mission initialized";

// --- Deathmatch scoring system ---
// Since all units are BLUFOR, kills count as friendly fire (-1 point)
// We add +2 points per kill: +1 to counter penalty, +1 for the actual kill = net +1
addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];
    
    // Use instigator if available (for vehicle kills), otherwise use killer
    private _actualKiller = if (!isNull _instigator) then {_instigator} else {_killer};
    
    // Check if killer is a player and not suicide
    if (isPlayer _actualKiller && !isNull _actualKiller && _killed != _actualKiller) then {
        // Only execute on the machine where the killer is local
        if (local _actualKiller) then {
            _actualKiller addPlayerScores [2, 0, 0, 0, 0];
            diag_log format ["Deathmatch: %1 killed %2 - added +2 score", name _actualKiller, name _killed];
        };
    };
}];

diag_log "Deathmatch scoring system initialized";

// Start zone control system
// Parameters: [marker, radius, damage per tick, tick interval, warning seconds]
["respawnPoint_1", 85, 0.05, 1, 5] spawn MyRespawn_fnc_zoneControl;

// Start air drop system (periodic drops)
[] spawn {
    private _marker = "respawnPoint_1";
    private _radius = 85;  // Same as zone radius
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
