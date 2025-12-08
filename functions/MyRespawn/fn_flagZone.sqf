/*
    fn_flagZone.sqf
    Spawns a flag at random position within zone and awards points to players in capture zone.
    Flag moves to new random location every _moveInterval seconds.
    
    Call from init.sqf: [] call MyRespawn_fnc_flagZone;
*/

// === CONFIGURATION ===
private _marker = "respawnPoint_1";  // Zone center marker
private _radius = 10;                 // Capture zone radius in meters
private _tickInterval = 2;            // Seconds between point awards
private _pointsPerTick = 1;           // Points awarded per tick
private _moveInterval = 15;           // Seconds between flag relocations (1 minute)

private _zoneCenter = getMarkerPos _marker;
private _zoneRadius = [_marker] call MyRespawn_fnc_getZoneRadius;

// --- Server: spawn flag, manage relocation, run scoring loop ---
if (isServer) then {
    // Global array to track spawned objects for cleanup
    DM_flagObjects = [];
    DM_flagRadius = _radius;
    
    // Function to spawn flag zone at position
    DM_fnc_spawnFlagZone = {
        params ["_centerPos", "_radius"];
        
        // Delete old objects
        {
            if (!isNull _x) then { deleteVehicle _x; };
        } forEach DM_flagObjects;
        DM_flagObjects = [];
        
        // Spawn flagpole
        private _flag = "Flag_NATO_F" createVehicle _centerPos;
        _flag setPosATL _centerPos;
        DM_flag = _flag;
        DM_flagObjects pushBack _flag;
        
        // Spawn sandbag barricades (6 walls at half radius)
        private _barrierCount = 6;
        private _barrierDistance = _radius * 0.5;
        for "_i" from 0 to (_barrierCount - 1) do {
            private _angle = (_i / _barrierCount) * 360;
            private _barrierX = (_centerPos select 0) + (sin _angle) * _barrierDistance;
            private _barrierY = (_centerPos select 1) + (cos _angle) * _barrierDistance;
            private _barrierPos = [_barrierX, _barrierY, 0];
            
            private _barrier = "Land_BagFence_Round_F" createVehicle _barrierPos;
            _barrier setPosATL _barrierPos;
            _barrier setDir (_angle + 180);
            DM_flagObjects pushBack _barrier;
        };
        
        // Spawn road cones around perimeter (12 cones)
        private _coneCount = 12;
        for "_i" from 0 to (_coneCount - 1) do {
            private _angle = (_i / _coneCount) * 360;
            private _coneX = (_centerPos select 0) + (sin _angle) * _radius;
            private _coneY = (_centerPos select 1) + (cos _angle) * _radius;
            private _conePos = [_coneX, _coneY, 0];
            
            private _cone = "RoadCone_F" createVehicle _conePos;
            _cone setPosATL _conePos;
            DM_flagObjects pushBack _cone;
        };
        
        // Update map marker
        "flagZoneMarker" setMarkerPos _centerPos;
        
        // Broadcast updated flag to clients
        publicVariable "DM_flag";
        
        diag_log format ["FlagZone: Spawned at %1", _centerPos];
        _centerPos
    };
    
    // Function to get random position within zone
    DM_fnc_getRandomFlagPos = {
        params ["_zoneCenter", "_zoneRadius"];
        
        private _angle = random 360;
        private _distance = random (_zoneRadius * 0.7);  // Stay within 70% of zone radius
        private _newX = (_zoneCenter select 0) + (sin _angle) * _distance;
        private _newY = (_zoneCenter select 1) + (cos _angle) * _distance;
        
        [_newX, _newY, 0]
    };
    
    // Create map marker (initial)
    createMarker ["flagZoneMarker", _zoneCenter];
    "flagZoneMarker" setMarkerShape "ELLIPSE";
    "flagZoneMarker" setMarkerSize [_radius, _radius];
    "flagZoneMarker" setMarkerColor "ColorYellow";
    "flagZoneMarker" setMarkerBrush "Border";
    "flagZoneMarker" setMarkerAlpha 0.8;
    
    // Initial spawn at random position
    private _initialPos = [_zoneCenter, _zoneRadius] call DM_fnc_getRandomFlagPos;
    [_initialPos, _radius] call DM_fnc_spawnFlagZone;
    
    publicVariable "DM_flagRadius";
    
    // Relocation loop
    [_zoneCenter, _zoneRadius, _radius, _moveInterval] spawn {
        params ["_zoneCenter", "_zoneRadius", "_flagRadius", "_moveInterval"];
        
        private _minMoveDistance = 20;  // Minimum distance from old position
        
        while {true} do {
            sleep _moveInterval;
            
            // Get current flag position
            private _oldPos = if (!isNil "DM_flag" && !isNull DM_flag) then {
                getPosATL DM_flag
            } else {
                _zoneCenter
            };
            
            // Find new position at least _minMoveDistance away from old one
            private _newPos = [0, 0, 0];
            private _attempts = 0;
            private _maxAttempts = 50;
            
            while {_attempts < _maxAttempts} do {
                _newPos = [_zoneCenter, _zoneRadius] call DM_fnc_getRandomFlagPos;
                if (_newPos distance2D _oldPos >= _minMoveDistance) exitWith {};
                _attempts = _attempts + 1;
            };
            
            // Announce relocation
            "Flag zone is moving!" remoteExec ["systemChat", 0];
            
            // Respawn at new location
            [_newPos, _flagRadius] call DM_fnc_spawnFlagZone;
            
            // Play notification sound at new flag position for all players
            [_newPos, "A3\Sounds_F\sfx\UI\notifications\notification_default.wss", 1500, 1, 1, 0] remoteExec ["playSound3D", 0];
            
            diag_log format ["FlagZone: Relocated to %1 (distance from old: %2m)", _newPos, round (_newPos distance2D _oldPos)];
        };
    };
    
    // Scoring loop
    [_tickInterval, _pointsPerTick] spawn {
        params ["_tickInterval", "_pointsPerTick"];
        
        while {true} do {
            sleep _tickInterval;
            
            if (isNil "DM_flag" || isNull DM_flag) then { continue; };
            
            private _flagPos = getPosATL DM_flag;
            private _someoneScored = false;
            
            {
                if (isPlayer _x && alive _x) then {
                    private _dist = _x distance _flagPos;
                    if (_dist <= DM_flagRadius) then {
                        [_x, _pointsPerTick] call DM_fnc_addPoints;
                        _someoneScored = true;
                    };
                };
            } forEach allPlayers;
            
            // Build and show scoreboard hint to all players
            if (_someoneScored && count DM_scores > 0) then {
                // Sort scores descending
                private _sorted = +DM_scores;
                _sorted sort false;  // Sort by first comparable element (we need custom sort)
                _sorted = [_sorted, [], {_x select 2}, "DESCEND"] call BIS_fnc_sortBy;
                
                // Build scoreboard text
                private _text = "=== SCOREBOARD ===\n";
                {
                    _x params ["_uid", "_name", "_score"];
                    _text = _text + format ["%1: %2 pts\n", _name, _score];
                } forEach _sorted;
                
                [_text] remoteExec ["hint", 0];
            };
        };
    };
};

// --- Client: 3D visualization (rings follow DM_flag position) ---
if (hasInterface) then {
    [] spawn {
        waitUntil {!isNil "DM_flag" && !isNil "DM_flagRadius"};
        
        addMissionEventHandler ["Draw3D", {
            if (isNil "DM_flag" || isNull DM_flag) exitWith {};
            
            private _flagPos = getPosATL DM_flag;
            private _radius = DM_flagRadius;
            private _segments = 32;
            
            // Ring heights and colors
            private _rings = [
                [0.3, [1, 0.5, 0, 0.9]],
                [1.2, [1, 0.8, 0, 0.7]],
                [2.5, [1, 1, 0.3, 0.5]]
            ];
            
            {
                _x params ["_height", "_color"];
                
                for "_i" from 0 to (_segments - 1) do {
                    private _angle1 = (_i / _segments) * 360;
                    private _angle2 = ((_i + 1) / _segments) * 360;
                    
                    private _x1 = (_flagPos select 0) + (sin _angle1) * _radius;
                    private _y1 = (_flagPos select 1) + (cos _angle1) * _radius;
                    private _z1 = getTerrainHeightASL [_x1, _y1] + _height;
                    
                    private _x2 = (_flagPos select 0) + (sin _angle2) * _radius;
                    private _y2 = (_flagPos select 1) + (cos _angle2) * _radius;
                    private _z2 = getTerrainHeightASL [_x2, _y2] + _height;
                    
                    drawLine3D [[_x1, _y1, _z1], [_x2, _y2, _z2], _color];
                };
            } forEach _rings;
            
            // 3D icon above flag with distance
            private _flagWorldPos = _flagPos vectorAdd [0, 0, 5];
            private _dist = player distance _flagPos;
            private _distText = format ["%1m", round _dist];
            
            drawIcon3D [
                "\A3\ui_f\data\map\markers\handdrawn\objective_CA.paa",
                [1, 0.8, 0, 1],
                _flagWorldPos,
                1.5, 1.5, 0,
                _distText,
                2, 0.04,
                "PuristaMedium",
                "center",
                true
            ];
        }];
        
        diag_log "FlagZone: 3D visualization started";
    };
};
