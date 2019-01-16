_idx = lbCurSel 1500;
//_index = parseNumber (lbData [1500, _idx]); // THIS RETURNS A STRING AND NEEDS TO BE FIXED SOMEHOW
_price = lbValue [1500, _idx];

if(_price == -1) exitWith {};

_town = (getPos player) call OT_fnc_nearestTown;
_standing = player getVariable format['rep%1',_town];
_influence = player getvariable "influence";
_money = player getVariable "money";
_type = typeOf _object;
_vehiclesToSell = profileNamespace getVariable "OT_SellingVehicles";
_vehToSell = _vehiclesToSell select _idx;
_owner = server getVariable "name" + (_vehToSell call OT_fnc_getOwner);

if (isNil "_owner") exitWith
{
	"Cannot sell a vehicle you don't own!" call OT_fnc_notifyMinor;
};

player setVariable ["money", _money + _price, true];
deleteVehicle _vehToSell;
playSound "3DEN_notificationDefault";
closeDialog 0;
call {
	format["You sold a %1 for $%2", (typeOf _vehiclesToSell select _idx) call OT_fnc_vehicleGetName, _price] call OT_fnc_notifyMinor;
};