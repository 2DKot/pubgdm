/*
    fn_zoneControl.sqf
    Creates a play zone around a marker. Damages players outside the zone.
    
    Parameters:
        _marker     - center marker name
        _radius     - zone radius in meters
        _damage     - damage per tick (0.05 = 5% health per tick)
        _tickTime   - seconds between damage ticks
        _warnTime   - seconds of warning before damage starts
*/

params [
    ["_marker", "respawnPoint_1"],
    ["_radius", 500],
    ["_damage", 0.05],
    ["_tickTime", 1],
    ["_warnTime", 5]
];

// Only run on each client for their own player
if (!hasInterface) exitWith {};

private _centerPos = getMarkerPos _marker;

// Create visual zone marker (circle on map)
private _zoneMarker = createMarkerLocal ["zoneMarker", _centerPos];
_zoneMarker setMarkerShapeLocal "ELLIPSE";
_zoneMarker setMarkerSizeLocal [_radius, _radius];
_zoneMarker setMarkerColorLocal "ColorBlue";
_zoneMarker setMarkerAlphaLocal 0.3;
_zoneMarker setMarkerBrushLocal "Border";

// Zone border (more visible edge)
private _zoneBorder = createMarkerLocal ["zoneBorder", _centerPos];
_zoneBorder setMarkerShapeLocal "ELLIPSE";
_zoneBorder setMarkerSizeLocal [_radius, _radius];
_zoneBorder setMarkerColorLocal "ColorBlue";
_zoneBorder setMarkerAlphaLocal 0.8;
_zoneBorder setMarkerBrushLocal "SolidBorder";

diag_log format ["ZoneControl: Zone active at %1, radius %2m", _marker, _radius];

// --- 3D Zone Wall Visualization ---
// Number of segments (more = smoother circle, but more performance cost)
private _segments = 48;
private _wallHeight = 100;  // Height of the wall in meters
private _wallColor = [0, 0.6, 1, 0.8];  // Bright blue [R,G,B,A]

// Pre-calculate wall points for performance
private _wallPoints = [];
for "_i" from 0 to _segments do {
    private _angle = (_i / _segments) * 360;
    private _x = (_centerPos select 0) + (_radius * sin _angle);
    private _y = (_centerPos select 1) + (_radius * cos _angle);
    private _z = getTerrainHeightASL [_x, _y];
    _wallPoints pushBack [_x, _y, _z];
};

// Add 3D drawing event handler (runs every frame)
addMissionEventHandler ["Draw3D", {
    (_this select 0) params ["_wallPoints", "_wallHeight", "_wallColor", "_segments"];
    
    // Draw wall segments
    for "_i" from 0 to (_segments - 1) do {
        private _p1 = _wallPoints select _i;
        private _p2 = _wallPoints select (_i + 1);
        
        // Bottom points (at ground level)
        private _bottom1 = [_p1 select 0, _p1 select 1, _p1 select 2];
        private _bottom2 = [_p2 select 0, _p2 select 1, _p2 select 2];
        
        // Top points
        private _top1 = [_p1 select 0, _p1 select 1, (_p1 select 2) + _wallHeight];
        private _top2 = [_p2 select 0, _p2 select 1, (_p2 select 2) + _wallHeight];
        
        // Draw vertical lines (pillars)
        drawLine3D [_bottom1, _top1, _wallColor];
        
        // Draw horizontal lines at different heights
        drawLine3D [_bottom1, _bottom2, _wallColor];
        drawLine3D [_top1, _top2, _wallColor];
        
        // Middle lines for grid effect
        private _mid1 = [_p1 select 0, _p1 select 1, (_p1 select 2) + (_wallHeight * 0.33)];
        private _mid2 = [_p2 select 0, _p2 select 1, (_p2 select 2) + (_wallHeight * 0.33)];
        private _mid3 = [_p1 select 0, _p1 select 1, (_p1 select 2) + (_wallHeight * 0.66)];
        private _mid4 = [_p2 select 0, _p2 select 1, (_p2 select 2) + (_wallHeight * 0.66)];
        drawLine3D [_mid1, _mid2, _wallColor];
        drawLine3D [_mid3, _mid4, _wallColor];
    };
}, [[_wallPoints, _wallHeight, _wallColor, _segments]]];

// Zone check loop
private _outsideTimer = 0;
private _wasOutside = false;

while {true} do {
    sleep _tickTime;
    
    if (!alive player) then {
        _outsideTimer = 0;
        _wasOutside = false;
        continue;
    };
    
    private _playerPos = getPos player;
    private _distance = _playerPos distance2D _centerPos;
    private _isOutside = _distance > _radius;
    
    if (_isOutside) then {
        // Player is outside the zone
        if (!_wasOutside) then {
            // Just left the zone - start warning
            _wasOutside = true;
            _outsideTimer = 0;
            hint "WARNING: You left the play zone!\nReturn immediately or take damage!";
            playSound "FD_Start_F";  // Warning beep
        };
        
        _outsideTimer = _outsideTimer + _tickTime;
        
        if (_outsideTimer > _warnTime) then {
            // Warning time expired - deal damage
            private _currentDamage = damage player;
            player setDamage (_currentDamage + _damage);
            
            // Visual feedback
            private _distOutside = round (_distance - _radius);
            hintSilent format [
                "OUTSIDE ZONE!\n%1m outside boundary\nTaking damage...",
                _distOutside
            ];
            
            // Red screen flash effect
            "dynamicBlur" ppEffectEnable true;
            "dynamicBlur" ppEffectAdjust [2];
            "dynamicBlur" ppEffectCommit 0.1;
            "dynamicBlur" ppEffectAdjust [0];
            "dynamicBlur" ppEffectCommit 0.3;
        } else {
            // Still in warning period
            private _timeLeft = round (_warnTime - _outsideTimer);
            hintSilent format [
                "OUTSIDE ZONE!\nDamage in %1 seconds...\nReturn to the play area!",
                _timeLeft
            ];
        };
    } else {
        // Player is inside the zone
        if (_wasOutside) then {
            // Just returned to zone
            hint "You returned to the play zone.";
            _wasOutside = false;
            _outsideTimer = 0;
        };
    };
};

