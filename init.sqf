/*
    init.sqf
    Runs at mission start
    
    NOTE: Playable units must be placed in the Eden Editor for multiplayer lobby.
    Place 10 riflemen anywhere, set them as "Playable", and save.
    The onPlayerRespawn.sqf will handle positioning and loadout.
*/

diag_log "pubgdm mission initialized";

// --- Deathmatch scoring system ---
// Using getPlayerScores to track actual kills: [infantry, soft vehicles, armor, air, deaths, total]
DM_killsToWin = 10;  // Kills needed to win
DM_gameEnded = false;  // Flag to prevent multiple win triggers

addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];
    
    // Don't process if game already ended
    if (DM_gameEnded) exitWith {};
    
    // Use instigator if available (for vehicle kills), otherwise use killer
    private _actualKiller = if (!isNull _instigator) then {_instigator} else {_killer};
    
    // Check if killer is a player and not suicide
    if (isPlayer _actualKiller && !isNull _actualKiller && _killed != _actualKiller) then {
        // Fix scoreboard display (counter friendly-fire penalty: +2 to offset game's +1-2=-1)
        if (local _actualKiller) then {
            _actualKiller addPlayerScores [2, 0, 0, 0, 0];
        };
        
        // Check win condition (server only) - count kills manually since timing is tricky
        if (isServer && !DM_gameEnded) then {
            // Get actual kill count using getPlayerScores
            // [infantry kills, soft vehicle kills, armor kills, air kills, deaths, total]
            private _scores = getPlayerScores _actualKiller;
            private _infantryKills = _scores select 0;
            
            diag_log format ["Deathmatch: %1 killed %2 - kills: %3/%4", name _actualKiller, name _killed, _infantryKills, DM_killsToWin];
            
            if (_infantryKills > DM_killsToWin) then {
                // Set flag to prevent multiple triggers
                DM_gameEnded = true;
                publicVariable "DM_gameEnded";
                
                // Announce winner to all players
                private _winnerName = name _actualKiller;
                private _msg = format ["%1 WINS with %2 kills!", _winnerName, _infantryKills];
                [_msg] remoteExec ["hint", 0];
                
                diag_log format ["Deathmatch: %1 won with %2 kills!", _winnerName, _infantryKills];
                
                // End mission immediately
                "END1" call BIS_fnc_endMission;
            };
        };
    };
}];

diag_log format ["Deathmatch scoring system initialized - first to %1 kills wins!", DM_killsToWin];

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
