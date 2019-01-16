private ["_town","_house","_housepos","_pos","_pop","_houses","_mrk","_furniture"];
waitUntil {!isNull player};
waitUntil {player == player};

[] spawn {
	while {true} do {
		sleep 3;
		{
			if(local _x and count (units _x) == 0) then {
				deleteGroup _x;
			};
		}foreach(allGroups);
	};
};

if (!hasInterface) exitWith {};
if(isNil "bigboss" and typeof player == "I_G_officer_F") then {bigboss = player;publicVariable "bigboss";};
if(count ([] call CBA_fnc_players) == 1 and isNil "bigboss") then {bigboss = player;publicVariable "bigboss";};

if(isNil {server getVariable "generals"}) then {server setVariable ["generals",[getplayeruid player]]};

removeAllWeapons player;
removeAllAssignedItems player;
removeGoggles player;
removeBackpack player;
removeHeadgear player;
removeVest player;


player linkItem "ItemMap";

if(isMultiplayer and (!isServer)) then {
	//TFAR Support, thanks to Dedmen for the help
	[] call OT_fnc_initTFAR;
	call compile preprocessFileLineNumbers "initVar.sqf";
	call OT_fnc_initVar;
}else{
	OT_varInitDone = true;
};

_start = OT_startCameraPos;
_introcam = "camera" camCreate _start;
_introcam camSetTarget OT_startCameraTarget;
_introcam cameraEffect ["internal", "BACK"];
_introcam camSetFocus [15, 1];
_introcam camsetfov 1.1;
_introcam camCommit 0;
waitUntil {camCommitted _introcam};
showCinemaBorder false;
introcam = _introcam;


if(player == bigboss and (server getVariable ["StartupType",""] == "")) then {
    waitUntil {!(isnull (findDisplay 46)) and OT_varInitDone};
    sleep 1;
    _nul = createDialog "OT_dialog_start";
}else{
	"Loading" call OT_fnc_notifyStart;
};
waitUntil {sleep 1;!isNil "OT_NATOInitDone"};

private _aplayers = server getVariable ["OT_allplayers",[]];
if ((_aplayers find (getplayeruid player)) == -1) then {
	_aplayers pushback (getplayeruid player);
	server setVariable ["OT_allplayers",_aplayers,true];
};
if(!isMultiplayer) then {
	private _generals = server getVariable ["generals",[]];
	if ((_generals find (getplayeruid player)) == -1) then {
		_generals pushback (getplayeruid player);
		server setVariable ["generals",_generals,true];
	};
};
server setVariable [format["name%1",getplayeruid player],name player,true];
server setVariable [format["uid%1",name player],getplayeruid player,true];
spawner setVariable [format["%1",getplayeruid player],player,true];

player forceAddUniform (OT_clothes_locals call BIS_fnc_selectRandom);
_startup = server getVariable "StartupType";
_newplayer = true;
_furniture = [];
_town = "";
_pos = [];
_housepos = [];

if(isMultiplayer or _startup == "LOAD") then {
	player remoteExec ["OT_fnc_loadPlayerData",2,false];
    waitUntil{sleep 0.5;player getVariable ["OT_loaded",false]};
	_newplayer = player getVariable ["OT_newplayer",true];

	if(isMultiplayer) then {
		//ensure player is in own group, not one someone else left
		_group = creategroup resistance;
		[player] joinSilent nil;
		[player] joinSilent _group;
	};

	if(!_newplayer) then {
		_housepos = player getVariable "home";
		if(isNil "_housepos") exitWith {_newplayer = true};
		_town = _housepos call OT_fnc_nearestTown;
		_pos = server getVariable _town;
		{
			if(_x call OT_fnc_hasOwner) then {
				if ((_x call OT_fnc_playerIsOwner) and !(_x isKindOf "LandVehicle") and !(_x isKindOf "Building")) then {
					_furniture pushback _x
				};
			};
		}foreach(_housepos nearObjects 50);
	};

	_recruits = server getVariable ["recruits",[]];
	_newrecruits = [];
	{
		_owner = _x select 0;
		_name = _x select 1;
		_civ = _x select 2;
		_rank = _x select 3;
		_loadout = _x select 4;
		_type = _x select 5;
		_xp = _x select 6;
		if(_owner == (getplayeruid player)) then {
			if(typename _civ == "ARRAY") then {
				_civ =  group player createUnit [_type,_civ,[],0,"NONE"];
				[_civ,getplayeruid player] call OT_fnc_setOwner;
				_civ setVariable ["OT_xp",_xp,true];
				_civ setVariable ["NOAI",true,true];
				_civ setRank _rank;
				if(_rank == "PRIVATE") then {_civ setSkill 0.1 + (random 0.3)};
				if(_rank == "CORPORAL") then {_civ setSkill 0.2 + (random 0.3)};
				if(_rank == "SERGEANT") then {_civ setSkill 0.3 + (random 0.3)};
				if(_rank == "LIEUTENANT") then {_civ setSkill 0.5 + (random 0.3)};
				if(_rank == "CAPTAIN") then {_civ setSkill 0.6 + (random 0.3)};
				if(_rank == "MAJOR") then {_civ setSkill 0.8 + (random 0.2)};
				[_civ, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _civ];
				[_civ, (OT_voices_local call BIS_fnc_selectRandom)] remoteExecCall ["setSpeaker", 0, _civ];
				_civ setUnitLoadout _loadout;
				_civ spawn OT_fnc_wantedSystem;
				_civ setName _name;

				[_civ] joinSilent nil;
				[_civ] joinSilent (group player);

				commandStop _civ;
			}else{
				if(_civ call OT_fnc_playerIsOwner) then {
					[_civ] joinSilent (group player);
				};
			};
		};
		_newrecruits pushback [_owner,_name,_civ,_rank,_loadout,_type];
	}foreach (_recruits);
	server setVariable ["recruits",_newrecruits,true];

	_squads = server getVariable ["squads",[]];
	_newsquads = [];
	_cc = 1;
	{
		_x params ["_owner","_cls","_group","_units"];
		if(_owner == (getplayeruid player)) then {
			if(typename _group != "GROUP") then {
				_name = _cls;
				if(count _x > 4) then {
					_name = _x select 4;
				}else{
					{
						if((_x select 0) == _cls) then {
							_name = _x select 2;
						};
					}foreach(OT_Squadables);
				};
				_group = creategroup resistance;
				_group setGroupIdGlobal [_name];
				{
					_x params ["_type","_pos","_loadout"];
					_civ = _group createUnit [_type,_pos,[],0,"NONE"];
					_civ setSkill 0.5 + (random 0.4);
					_civ setUnitLoadout _loadout;
					[_civ, (OT_faces_local call BIS_fnc_selectRandom)] remoteExecCall ["setFace", 0, _civ];
					[_civ, (OT_voices_local call BIS_fnc_selectRandom)] remoteExecCall ["setSpeaker", 0, _civ];
				}foreach(_units);
			};
			player hcSetGroup [_group,groupId _group,"teamgreen"];
			_cc = _cc + 1;
		};
		_newsquads pushback [_owner,_cls,_group,[]];
	}foreach (_squads);
	player setVariable ["OT_squadcount",_cc,true];
	server setVariable ["squads",_newsquads,true];
};

if (_newplayer) then {
    _clothes = (OT_clothes_guerilla call BIS_fnc_selectRandom);
	player forceAddUniform _clothes;
    player setVariable ["uniform",_clothes,true];
	private _money = 100;
	private _diff = server getVariable ["OT_difficulty",1];
	if(_diff == 0) then {
		_money = 1000;
	};
	if(_diff == 2) then {
		_money = 0;
	};
    player setVariable ["money",_money,true];
    [player,getplayeruid player] call OT_fnc_setOwner;
    if(!isMultiplayer) then {
        {
            if(_x != player) then {
             	deleteVehicle _x;
            };
        } foreach switchableUnits;
    };

    player setVariable ["rep",0,true];
    {
        player setVariable [format["rep%1",_x],0,true];
    }foreach(OT_allTowns);

    _town = server getVariable "spawntown";
    if(OT_randomSpawnTown) then {
        _town = OT_spawnTowns call BIS_fnc_selectRandom;
    };
	_house = _town call OT_fnc_getPlayerHome;
    _housepos = getpos _house;

    //Put a light on at home
    _light = "#lightpoint" createVehicle [_housepos select 0,_housepos select 1,(_housepos select 2)+2.2];
    _light setLightBrightness 0.11;
    _light setLightAmbient[.9, .9, .6];
    _light setLightColor[.5, .5, .4];

	//Free quad
	_pos = _housepos findEmptyPosition [5,100,"C_Quadbike_01_F"];
	if (count _pos > 0) then {
		_veh = "C_Quadbike_01_F" createVehicle _pos;
		[_veh,getPlayerUID player] call OT_fnc_setOwner;
		clearWeaponCargoGlobal _veh;
		clearMagazineCargoGlobal _veh;
		clearBackpackCargoGlobal _veh;
		clearItemCargoGlobal _veh;
		player reveal _veh;
	};

    [_house,getplayeruid player] call OT_fnc_setOwner;
    player setVariable ["home",_housepos,true];

    _furniture = (_house call OT_fnc_spawnTemplate) select 0;

    {
		if(typeof _x == OT_item_Storage) then {
            _x addItemCargoGlobal ["ToolKit", 1];
			_x addBackpackCargoGlobal ["B_AssaultPack_khk", 1];
			_x addItemCargoGlobal ["NVGoggles_INDEP", 1];
        };
        [_x,getplayeruid player] call OT_fnc_setOwner;
    }foreach(_furniture);
    player setVariable ["owned",[[_house] call OT_fnc_getBuildID],true];

};
_count = 0;
{
	if !(_x isKindOf "Vehicle") then {
		if(_x call OT_fnc_hasOwner) then {
			_x call OT_fnc_initObjectLocal;
		};
	};
	if(_count > 5000) then {
		_count = 0;
		titleText ["Loading... please wait", "BLACK FADED", 0];
	};
	_count = _count + 1;
}foreach((allMissionObjects "Building") + vehicles);

waitUntil {!isNil "OT_SystemInitDone"};
titleText ["Loading Session", "BLACK FADED", 0];
player setCaptive true;
player setPos _housepos;
titleText ["", "BLACK IN", 5];

player addEventHandler ["WeaponAssembled",{
	_me = _this select 0;
	_wpn = _this select 1;
	_pos = position _wpn;
	if(typeof _wpn in OT_staticMachineGuns) then {
		_wpn remoteExec["OT_fnc_initStaticMGLocal",0,_wpn];
	};
	if(typeof _wpn in OT_staticWeapons) then {
		if(_me call OT_fnc_unitSeen) then {
			_me setCaptive false;
		};
	};
	if(isplayer _me) then {
		[_wpn,getplayeruid player] call OT_fnc_setOwner;
	};
}];

player addEventHandler ["InventoryOpened", {
	_veh = _this select 1;
	_ret = false;
	if((_veh call OT_fnc_getOwner) != (getplayeruid player)) then {
		if(_veh getVariable ["OT_locked",false]) then {
			_ret = true;
			format["This inventory has been locked by %1",server getVariable "name"+(_veh call OT_fnc_getOwner)] call OT_fnc_notifyMinor;
		};
	};
	_ret;
}];

player addEventHandler ["GetInMan",{
	_unit = _this select 0;
	_position = _this select 1;
	_veh = _this select 2;
	_notified = false;

	call OT_fnc_notifyVehicle;
	private _isgen = call OT_fnc_playerIsGeneral;

	if(_position == "driver") then {
		if !(_veh call OT_fnc_hasOwner) then {
			[_veh, getplayeruid player] call OT_fnc_setOwner;
			_veh setVariable ["stolen",true,true];
			if((_veh getVariable ["ambient",false]) and (player call OT_fnc_unitSeenAny)) then {
				[(getpos player) call OT_fnc_nearestTown,-10,"Stolen vehicle"] call OT_fnc_standing;
			};
		}else{
			if !(_veh call OT_fnc_playerIsOwner) then {
				if(!_isgen and (_veh getVariable ["OT_locked",false])) then {
					moveOut player;
					format["This vehicle has been locked by %1",server getVariable "name"+(_veh call OT_fnc_getOwner)] call OT_fnc_notifyMinor;
				};
			};
		};
	};
	_g = _v getVariable ["vehgarrison",false];
	if(typename _g == "STRING") then {
		_vg = server getVariable format["vehgarrison%1",_g];
		_vg deleteAt (_vg find (typeof _veh));
		server setVariable [format["vehgarrison%1",_g],_vg,false];
		_veh setVariable ["vehgarrison",nil,true];
		{
			_x setCaptive false;
		}foreach(crew _veh);
		_veh spawn OT_fnc_revealToNATO;
	};
	_g = _v getVariable ["airgarrison",false];
	if(typename _g == "STRING") then {
		_vg = server getVariable format["airgarrison%1",_g];
		_vg deleteAt (_vg find (typeof _veh));
		server setVariable [format["airgarrison%1",_g],_vg,false];
		_veh setVariable ["airgarrison",nil,true];
		{
			_x setCaptive false;
		}foreach(crew _veh);
		_veh spawn OT_fnc_revealToNATO;
	};
}];

if(_newplayer) then {
	if!(player getVariable ["OT_tute",false]) then {
		createDialog "OT_dialog_tute";
		player setVariable ["OT_tute",true,true];
	};
};

{
	_pos = buildingpositions getVariable [_x,[]];
	if(count _pos == 0) then {
		_bdg = OT_centerPos nearestObject parseNumber _x;
		_pos = position _bdg;
		buildingpositions setVariable [_x,_pos,true];
	};
}foreach(player getvariable ["owned",[]]);

if(isMultiplayer) then {
	player addEventHandler ["Respawn",OT_fnc_respawnHandler];
};

_introcam cameraEffect ["Terminate", "BACK" ];
_introcam = nil;

OT_keyHandlerID = [21, [false, false, false], OT_fnc_keyHandler] call CBA_fnc_addKeyHandler;
[] spawn OT_fnc_setupPlayer;
