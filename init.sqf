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
        /*
            SCORING TIMING EXPLANATION:
            - EntityKilled fires BEFORE game processes the kill
            - We add +2 to counter friendly-fire penalty (game does +1 kill, -2 FF = -1 net)
            - Our +2 combined with game's -1 = +1 per kill (correct!)
            
            However, when we read getPlayerScores immediately after adding +2,
            the game hasn't applied its -1 yet. So we see score +1 higher than reality.
            
            That's why we use ">" instead of ">=" in the win condition:
            - Real 10 kills → getPlayerScores shows 11 → "11 > 10" triggers win ✓
        */
        
        // Fix scoreboard: add +2 to counter friendly-fire penalty (game does +1 -2 = -1)
        if (local _actualKiller) then {
            _actualKiller addPlayerScores [2, 0, 0, 0, 0];
        };
        
        // Check win condition (server only)
        if (isServer && !DM_gameEnded) then {
            private _scores = getPlayerScores _actualKiller;
            private _infantryKills = _scores select 0;
            
            diag_log format ["Deathmatch: %1 killed %2 - kills: %3/%4", name _actualKiller, name _killed, _infantryKills, DM_killsToWin];
            
            // Use ">" not ">=" because getPlayerScores returns +1 higher due to timing (see comment above)
            if (_infantryKills > DM_killsToWin) then {
                // Set flag to prevent multiple triggers
                DM_gameEnded = true;
                publicVariable "DM_gameEnded";
                
                // Announce winner to all players
                private _winnerName = name _actualKiller;
                private _msg = format ["%1 WINS with %2 kills!", _winnerName, _infantryKills - 1];
                [_msg] remoteExec ["hint", 0];
                
                diag_log format ["Deathmatch: %1 won with %2 kills!", _winnerName, _infantryKills - 1];
                
                // End mission immediately
                "END1" call BIS_fnc_endMission;
            };
        };
    };
}];

diag_log format ["Deathmatch scoring system initialized - first to %1 kills wins!", DM_killsToWin];

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
