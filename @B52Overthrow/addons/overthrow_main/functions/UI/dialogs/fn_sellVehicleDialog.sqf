private _town = player call OT_fnc_nearestTown;
private _standing = player getVariable format['rep%1', _town];
private _items = nearestObjects [player, ["Car"], 30];
private _vehicleClasses = OT_vehicles apply { _x select 0 };

createDialog "OT_dialog_sell_vehicle";
lbClear 1500;

_numitems = 0;
profileNamespace setVariable ["OT_SellingVehicles", _items];
{
	_owner = server getVariable "name" + (_x call OT_fnc_getOwner);
	if !(isNil "_owner") then 
	{
		_type = typeOf _x;
		_index = _vehicleClasses find _type;
				
		if (_index >= 0) then {
			_name = "";
			_pic = "";
			_price = 0;

			if !(_type == "Set_HMG") then {
				_price = [_town, _type, _standing] call OT_fnc_getPrice;
			};

			if("fuel depot" in (server getVariable "OT_NATOabandoned")) then {
				_price = round(_price * 0.5);
			};
			
			call {
				if(_type == "Set_HMG") exitWith {
					_p = (cost getVariable "I_HMG_01_high_weapon_F") select 0;
					_p = _p + ((cost getVariable "I_HMG_01_support_high_F") select 0);
					private _quad = ((cost getVariable "C_Quadbike_01_F") select 0) + 60;
					_p = _p + _quad;
					_p = _p + 150; //Convenience cost
					_price = _p;
					_name = "Quad Bike w/ HMG Backpacks";
					_pic = "C_Quadbike_01_F" call OT_fnc_vehicleGetPic;
				};
				if(_type in OT_allExplosives) exitWith {
					_pic = _type call OT_fnc_magazineGetPic;
					_name = _type call OT_fnc_magazineGetName;
				};
				if(_type in OT_allDetonators) exitWith {
					_pic = _type call OT_fnc_weaponGetPic;
					_name = _type call OT_fnc_weaponGetName;
				};
				_pic = _type call OT_fnc_vehicleGetPic;
				_name = _type call OT_fnc_vehicleGetName;
			};
			// Price Fix
			_price = _price * 0.5;
			
			_idx = lbAdd [1500, format["%1", _name]];
			lbSetPicture [1500, _idx, _pic];
			lbSetData [1500, _idx, _idx];
			lbSetValue [1500, _idx, _price];
			
			_numitems = _numitems + 1;
		};
	};
} foreach(_items);

