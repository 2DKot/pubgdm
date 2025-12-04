/*
    fn_getZoneRadius.sqf
    Returns the zone radius from the marker size (a-axis of ellipse).
    All functions in this module should use this to ensure consistent radius.
    
    Parameters:
        _marker - (optional) marker name, defaults to "respawnPoint_1"
    
    Returns:
        Number - the radius in meters
*/

params [["_marker", "respawnPoint_1"]];

private _size = getMarkerSize _marker;
private _radius = _size select 0;  // a-axis of ellipse

_radius

