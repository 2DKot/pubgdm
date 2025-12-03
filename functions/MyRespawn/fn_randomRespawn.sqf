/*
    fn_randomRespawn.sqf
    Spawns the player from the sky (HALO jump) randomly around a marker.
    
    Parameters:
        _centerRef - marker name (string) or object
        _radius    - spawn radius in meters
*/

params ["_centerRef", "_radius"];

private _player = player;

// HALO jump height (meters above ground)
private _haloHeight = 700;

// --- Get center position (2D) ---
private _centerPos2D = if (_centerRef isEqualType "") then {
    getMarkerPos _centerRef  // Returns [x, y, 0]
} else {
    getPos _centerRef        // Returns [x, y, z]
};

// Extract X and Y only
private _centerX = _centerPos2D select 0;
private _centerY = _centerPos2D select 1;

// --- Generate random offset inside radius ---
private _angle = random 360;
private _distance = random _radius;

private _targetX = _centerX + (_distance * sin _angle);
private _targetY = _centerY + (_distance * cos _angle);

// --- Get terrain height at target position ---
private _groundHeight = getTerrainHeightASL [_targetX, _targetY];

// Spawn position high in the sky
private _spawnPos = [_targetX, _targetY, _groundHeight + _haloHeight];

// --- Move player to spawn position ---
_player setPosASL _spawnPos;

// --- Logging ---
diag_log format [
    "RandomRespawn: Player %1 spawning at [%2, %3] - ground: %4m, spawn height: %5m",
    name _player,
    round _targetX,
    round _targetY,
    round _groundHeight,
    round (_groundHeight + _haloHeight)
];

// Add parachute if player doesn't have one
if (backpack _player != "B_Parachute") then {
    _player addBackpack "B_Parachute";
};
