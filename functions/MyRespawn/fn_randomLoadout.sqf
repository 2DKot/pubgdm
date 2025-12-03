/*
    fn_randomLoadout.sqf
    Gives the player a random weapon with appropriate ammo and a sidearm.
*/

private _player = player;

// --- Random weapon loadout ---
// Format: [weapon classname, magazine classname, magazine count]
private _weaponPool = [
    // Assault Rifles (base game)
    ["arifle_MX_F", "30Rnd_65x39_caseless_mag", 5],
    ["arifle_MX_Black_F", "30Rnd_65x39_caseless_mag", 5],
    ["arifle_MXC_F", "30Rnd_65x39_caseless_mag", 5],
    ["arifle_Katiba_F", "30Rnd_65x39_caseless_green", 5],
    ["arifle_Katiba_C_F", "30Rnd_65x39_caseless_green", 5],
    ["arifle_TRG21_F", "30Rnd_556x45_Stanag", 5],
    ["arifle_TRG20_F", "30Rnd_556x45_Stanag", 5],
    ["arifle_Mk20_F", "30Rnd_556x45_Stanag", 5],
    
    // SMGs (base game)
    ["SMG_01_F", "30Rnd_45ACP_Mag_SMG_01", 6],
    ["SMG_02_F", "30Rnd_9x21_Mag_SMG_02", 6],
    
    // Marksman Rifles (base game)
    ["arifle_MXM_F", "30Rnd_65x39_caseless_mag", 4],
    ["arifle_MXM_Black_F", "30Rnd_65x39_caseless_mag", 4],
    ["srifle_EBR_F", "20Rnd_762x51_Mag", 4],
    ["srifle_DMR_01_F", "10Rnd_762x54_Mag", 5],
    
    // LMG (base game)
    ["LMG_Mk200_F", "200Rnd_65x39_cased_Box", 2],
    ["LMG_Zafir_F", "150Rnd_762x54_Box", 2]
];

// Select random weapon
private _selected = selectRandom _weaponPool;
_selected params ["_weapon", "_magazine", "_magCount"];

// Clear current weapons
removeAllWeapons _player;

// Add magazines first (so weapon loads automatically)
for "_i" from 1 to _magCount do {
    _player addMagazine _magazine;
};

// Add the weapon
_player addWeapon _weapon;

// --- Random scope ---
// "" = no scope (iron sights), gives ~30% chance of no optic
private _scopePool = [
    "",  // no scope
    "",  // no scope (extra weight for iron sights)
    
    // Red dots (base game)
    "optic_Aco",
    "optic_ACO_grn",
    "optic_Holosight",
    "optic_Holosight_smg",
    
    // Collimators (base game)
    "optic_Yorris",
    "optic_MRD",
    
    // ACOG / Medium range (base game)
    "optic_Arco",
    "optic_Hamr",
    "optic_MRCO",
    
    // Sniper scopes (base game)
    "optic_SOS",
    "optic_DMS"
];

private _scope = selectRandom _scopePool;
if (_scope != "") then {
    _player addPrimaryWeaponItem _scope;
};

// Add a pistol as sidearm
_player addMagazines ["16Rnd_9x21_Mag", 2];
_player addWeapon "hgun_P07_F";

// Logging
private _scopeName = if (_scope == "") then { "iron sights" } else { _scope };
diag_log format ["RandomLoadout: Gave %1 weapon %2 with %3x %4, scope: %5", name _player, _weapon, _magCount, _magazine, _scopeName];

