/*
    init.sqf
    Runs at mission start
    
    NOTE: Playable units must be placed in the Eden Editor for multiplayer lobby.
    Place 10 riflemen anywhere, set them as "Playable", and save.
    The onPlayerRespawn.sqf will handle positioning and loadout.
*/

diag_log "pubgdm mission initialized";

// Start zone control system
// Parameters: [marker, radius, damage per tick, tick interval, warning seconds]
["respawnPoint_1", 85, 0.05, 1, 5] spawn MyRespawn_fnc_zoneControl;
