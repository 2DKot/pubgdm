/*
    init.sqf
    Runs at mission start
    
    NOTE: Playable units must be placed in the Eden Editor for multiplayer lobby.
    Place 10 riflemen anywhere, set them as "Playable", and save.
    The onPlayerRespawn.sqf will handle positioning and loadout.
*/

diag_log "pubgdm mission initialized";

// --- Server-side scoring system ---
if (isServer) then {
    // Scores array: [[playerUID, playerName, score], ...]
    DM_scores = [];
    
    // Function to get or create player score entry, returns index
    DM_fnc_getPlayerIndex = {
        params ["_player"];
        private _uid = getPlayerUID _player;
        private _index = DM_scores findIf {(_x select 0) == _uid};
        
        if (_index == -1) then {
            DM_scores pushBack [_uid, name _player, 0];
            _index = count DM_scores - 1;
        };
        _index
    };
    
    // Function to add points to player
    DM_fnc_addPoints = {
        params ["_player", "_points"];
        private _index = [_player] call DM_fnc_getPlayerIndex;
        private _entry = DM_scores select _index;
        _entry set [2, (_entry select 2) + _points];
        DM_scores set [_index, _entry];
        diag_log format ["DM_scores: %1 now has %2 points", _entry select 1, _entry select 2];
    };
};

// Start flag zone system (runs on both server and client)
// Parameters: [marker, radius, tickInterval, pointsPerTick]
["respawnPoint_1", 10, 20, 1] call MyRespawn_fnc_flagZone;

// End mission after timer
[] spawn {
    sleep 120;  // 1 minute for testing
    
    if (isServer) then {
        // Sort scores descending
        private _sorted = +DM_scores;  // copy array
        _sorted sort false;  // This won't work for nested arrays, let's do manual sort
        
        // Manual sort by score (index 2)
        for "_i" from 0 to (count _sorted - 2) do {
            for "_j" from (_i + 1) to (count _sorted - 1) do {
                if ((_sorted select _j select 2) > (_sorted select _i select 2)) then {
                    private _temp = _sorted select _i;
                    _sorted set [_i, _sorted select _j];
                    _sorted set [_j, _temp];
                };
            };
        };
        
        // Build scores text (using <br/> for line breaks - Arma supports HTML-like syntax)
        private _text = "";
        {
            _x params ["_uid", "_name", "_score"];
            _text = _text + format ["%1. %2 - %3 pts<br/>", _forEachIndex + 1, _name, _score];
        } forEach _sorted;
        
        if (_text == "") then {
            _text = "No players scored<br/>";
        };
        
        _text = _text + "<br/>Thanks for playing!";
        
        diag_log format ["Final scores: %1", DM_scores];
        diag_log format ["Debriefing text: %1", _text];
        
        "End1" setDebriefingText ["Final Scores", _text];
    };
    
    "End1" call BIS_fnc_endMission;
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
