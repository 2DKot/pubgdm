/*
    fn_flagZone.sqf
    Spawns a flag at marker center and awards points to players in the capture zone.
    
    Parameters:
        _marker      - Marker name for flag position (string)
        _radius      - Capture zone radius in meters (number, default 20)
        _tickInterval- Seconds between point awards (number, default 20)
        _pointsPerTick - Points awarded per tick (number, default 1)
    
    Call from init.sqf (server only for scoring, client for visuals)
*/

params [
    ["_marker", "respawnPoint_1"],
    ["_radius", 20],
    ["_tickInterval", 20],
    ["_pointsPerTick", 1]
];

private _flagPos = getMarkerPos _marker;

// --- Server: spawn flag, cones, create marker, run scoring loop ---
if (isServer) then {
    // Spawn flagpole at center
    private _flag = "Flag_NATO_F" createVehicle _flagPos;
    _flag setPosATL _flagPos;
    DM_flag = _flag;
    DM_flagRadius = _radius;
    
    // Spawn road cones around the perimeter (12 cones, every 30 degrees)
    private _coneCount = 12;
    for "_i" from 0 to (_coneCount - 1) do {
        private _angle = (_i / _coneCount) * 360;
        private _coneX = (_flagPos select 0) + (sin _angle) * _radius;
        private _coneY = (_flagPos select 1) + (cos _angle) * _radius;
        private _conePos = [_coneX, _coneY, 0];
        
        private _cone = "RoadCone_F" createVehicle _conePos;
        _cone setPosATL _conePos;
    };
    
    diag_log format ["FlagZone: Spawned %1 road cones around perimeter", _coneCount];
    
    // Create map marker for flag zone
    private _markerName = "flagZoneMarker";
    createMarker [_markerName, _flagPos];
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerSize [_radius, _radius];
    _markerName setMarkerColor "ColorYellow";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha 0.8;
    
    diag_log format ["FlagZone: Flag spawned at %1, capture radius %2m", _flagPos, _radius];
    
    // Broadcast to clients for 3D drawing
    publicVariable "DM_flag";
    publicVariable "DM_flagRadius";
    
    // Scoring loop: award points to players in zone
    [_tickInterval, _pointsPerTick] spawn {
        params ["_tickInterval", "_pointsPerTick"];
        
        while {true} do {
            sleep _tickInterval;
            
            private _flagPos = getPosATL DM_flag;
            {
                if (isPlayer _x && alive _x) then {
                    private _dist = _x distance _flagPos;
                    if (_dist <= DM_flagRadius) then {
                        [_x, _pointsPerTick] call DM_fnc_addPoints;
                        
                        private _msg = format ["%1 +%2 pt (flag zone)", name _x, _pointsPerTick];
                        [_msg] remoteExec ["hint", 0];
                    };
                };
            } forEach allPlayers;
        };
    };
};

// --- Client: 3D visualization (multiple rings) ---
if (hasInterface) then {
    [] spawn {
        // Wait for flag data from server
        waitUntil {!isNil "DM_flag" && !isNil "DM_flagRadius"};
        
        // Draw multiple 3D rings around flag zone
        addMissionEventHandler ["Draw3D", {
            if (isNil "DM_flag") exitWith {};
            
            private _flagPos = getPosATL DM_flag;
            private _radius = DM_flagRadius;
            private _segments = 32;
            
            // Ring heights and colors (bottom to top)
            private _rings = [
                [0.3, [1, 0.5, 0, 0.9]],    // Orange, near ground
                [1.2, [1, 0.8, 0, 0.7]],    // Yellow, mid
                [2.5, [1, 1, 0.3, 0.5]]     // Light yellow, top (more transparent)
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
        }];
        
        diag_log "FlagZone: 3D visualization started (3 rings)";
    };
};

