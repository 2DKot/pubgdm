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
_player unassignItem "NVGoggles";

removeAllWeapons _player;
removeAllItems _player;
removeAllMagazines _player;
removeVest _player;
removeHeadgear _player;
removeUniform _player;

private _uniformPool = [
    // Base game civilian uniforms
    "U_C_Poloshirt_blue",
    "U_C_Poloshirt_burgundy",
    "U_C_Poloshirt_stripped",
    "U_C_Poloshirt_salmon",
    "U_C_Poor_1",
    "U_C_Poor_2",
    "U_C_WorkerCoveralls",
    "U_C_Journalist",
    "U_C_Scientist",
    "U_Rangemaster",
    // Base game guerrilla uniforms
    "U_OG_Guerilla1_1",
    "U_OG_Guerilla2_1",
    "U_OG_Guerilla2_2",
    "U_OG_Guerilla2_3",
    "U_OG_Guerilla3_1",
    "U_OG_leader"
];

private _uniform = selectRandom _uniformPool;
_player forceAddUniform _uniform;

_player addVest "V_BandollierB_oli";

// Add magazines first (so weapon loads automatically)
for "_i" from 1 to _magCount do {
    _player addMagazine _magazine;
};

_player addMagazines ["HandGrenade", 3];
_player addMagazines ["SmokeShell", 2];
_player addItem "FirstAidKit";
_player addItem "FirstAidKit";

// Add the weapon
_player addWeapon _weapon;

// --- Random scope ---
// "" = no scope (iron sights), gives ~30% chance of no optic
private _scopePool = [    
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

// 30% chance to add a scope
private _scope = "";
if (random 1 < 0.3) then {
    _scope = selectRandom _scopePool;
    if (_scope != "") then {
        _player addPrimaryWeaponItem _scope;
    };
};

// Logging
private _scopeName = if (_scope == "") then { "iron sights" } else { _scope };
diag_log format ["RandomLoadout: Gave %1 weapon %2 with %3x %4, scope: %5", name _player, _weapon, _magCount, _magazine, _scopeName];
