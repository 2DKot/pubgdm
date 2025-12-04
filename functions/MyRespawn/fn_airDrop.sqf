/*
    fn_airDrop.sqf
    Spawns a supply crate with random loot that parachutes down within the zone.
    
    Parameters:
        _marker     - center marker name
        _radius     - drop radius (should match zone radius)
*/

params [
    ["_marker", "respawnPoint_1"],
    ["_radius", 85]
];

// Only run on server
if (!isServer) exitWith {};

private _centerPos = getMarkerPos _marker;

// --- Generate random drop position within radius ---
private _angle = random 360;
private _distance = random _radius;
private _dropX = (_centerPos select 0) + (_distance * sin _angle);
private _dropY = (_centerPos select 1) + (_distance * cos _angle);
private _groundZ = getTerrainHeightASL [_dropX, _dropY];

// Drop height
private _dropHeight = 100;
private _dropPos = [_dropX, _dropY, _groundZ + _dropHeight];

// --- Announce the drop ---
["Supply drop incoming!"] remoteExec ["hint", 0];
playSound3D ["A3\Sounds_F\sfx\alarm_independent.wss", objNull, false, _dropPos, 5, 1, 1000];

// --- Create the supply crate ---
private _crate = createVehicle ["B_CargoNet_01_ammo_F", _dropPos, [], 0, "CAN_COLLIDE"];
_crate setPosASL _dropPos;

// --- Attach parachute ---
private _parachute = createVehicle ["B_Parachute_02_F", _dropPos, [], 0, "FLY"];
_parachute setPosASL _dropPos;
_crate attachTo [_parachute, [0, 0, -1.5]];

// --- Clear default cargo and add random loot ---
clearWeaponCargoGlobal _crate;
clearMagazineCargoGlobal _crate;
clearItemCargoGlobal _crate;
clearBackpackCargoGlobal _crate;

// Loot pools
private _weaponPool = [
    // Weapons with magazines [weapon, magazine, magCount]
    ["arifle_MX_F", "30Rnd_65x39_caseless_mag", 4],
    ["arifle_MX_Black_F", "30Rnd_65x39_caseless_mag", 4],
    ["arifle_Katiba_F", "30Rnd_65x39_caseless_green", 4],
    ["arifle_MXM_F", "30Rnd_65x39_caseless_mag", 4],
    ["srifle_EBR_F", "20Rnd_762x51_Mag", 5],
    ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 2],
    ["SMG_01_F", "30Rnd_45ACP_Mag_SMG_01", 5]
];

private _scopePool = [
    "optic_Arco",
    "optic_Hamr",
    "optic_MRCO",
    "optic_SOS",
    "optic_DMS",
    "optic_Holosight"
];

private _itemPool = [
    "FirstAidKit",
    "Medikit"
];

// Vest pool by armor level
private _vestPool = [
    // Level 1 - Light armor
    "V_BandollierB_khk",
    "V_BandollierB_rgr",
    "V_Chestrig_khk",
    
    // Level 2 - Medium armor
    "V_PlateCarrier1_rgr",
    "V_PlateCarrier1_blk",
    "V_TacVest_khk",
    
    // Level 3 - Heavy armor
    "V_PlateCarrier2_rgr",
    "V_PlateCarrier2_blk",
    "V_PlateCarrierGL_rgr"
];

// Add 2-3 random weapons with ammo
private _numWeapons = 2 + floor random 2;
for "_i" from 1 to _numWeapons do {
    private _weapon = selectRandom _weaponPool;
    _crate addWeaponCargoGlobal [_weapon select 0, 1];
    _crate addMagazineCargoGlobal [_weapon select 1, _weapon select 2];
};

// Add 1-2 random scopes
private _numScopes = 1 + floor random 2;
for "_i" from 1 to _numScopes do {
    _crate addItemCargoGlobal [selectRandom _scopePool, 1];
};

// Add 2-4 random items
private _numItems = 2 + floor random 3;
for "_i" from 1 to _numItems do {
    _crate addItemCargoGlobal [selectRandom _itemPool, 1];
};

// Add some extra ammo variety
_crate addMagazineCargoGlobal ["30Rnd_65x39_caseless_mag", 3];
_crate addMagazineCargoGlobal ["30Rnd_556x45_Stanag", 3];
_crate addMagazineCargoGlobal ["20Rnd_762x51_Mag", 2];

// 70% chance to add a random vest
if (random 1 < 1) then {
    private _vest = selectRandom _vestPool;
    _crate addItemCargoGlobal [_vest, 1];
};

// --- Create map marker for drop location ---
private _markerName = format ["airdrop_%1", floor time];
private _dropMarker = createMarker [_markerName, [_dropX, _dropY]];
_dropMarker setMarkerType "mil_box";
_dropMarker setMarkerColor "ColorOrange";
_dropMarker setMarkerText "Supply Drop";

// --- Monitor landing and add smoke ---
[_crate, _parachute, _markerName, [_dropX, _dropY]] spawn {
    params ["_crate", "_parachute", "_markerName", "_pos2D"];
    
    // Wait for crate to land (check if near ground or parachute gone)
    waitUntil {
        sleep 0.5;
        (isNull _parachute) || 
        ((getPosATL _crate) select 2 < 2) || 
        (!alive _crate)
    };
    
    if (alive _crate) then {
        // Detach from parachute if still attached
        detach _crate;
        
        // Get final position
        private _finalPos = getPos _crate;
        
        // Create smoke signal (green smoke)
        private _smoke = createVehicle ["SmokeShellGreen", _finalPos, [], 0, "CAN_COLLIDE"];
        
        // Announce landing
        ["Supply drop has landed!"] remoteExec ["hint", 0];
        
        diag_log format ["AirDrop: Crate landed at %1", _finalPos];
        
        // Remove marker after 3 minutes
        sleep 180;
        deleteMarker _markerName;
    };
};

diag_log format ["AirDrop: Spawned at %1, dropping to [%2, %3]", _dropPos, _dropX, _dropY];

