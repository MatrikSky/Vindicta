#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR
#define OOP_DEBUG
//#define NAMESPACE uiNamespace
#include "..\..\OOP_Light\OOP_Light.h"
#include "..\..\AI\Commander\LocationData.hpp"
#include "..\Resources\MapUI\MapUI_Macros.h"
#include "..\..\Location\Location.hpp"


/*
Class: ClientMapUI
Singleton class that performs things related to map user interface
*/

#define CLASS_NAME "ClientMapUI"
#define pr private

// Common colors
CMUI_ColorWEST = [0,0.3,0.6,1];
CMUI_ColorEAST = [0.5,0,0,1];
CMUI_ColorIND = [0,0.5,0,1];
CMUI_ColorUnknown = [0.4,0,0.5,1];

CLASS(CLASS_NAME, "")

	// Arrays of LOCATION_DATA structures
	STATIC_VARIABLE("locationDataWest"); // What client's side knows about West knowledge about locations
	STATIC_VARIABLE("locationDataEast");
	STATIC_VARIABLE("locationDataInd");

	STATIC_METHOD("updateLocationData") {
		params [["_thisObject", "", [""]], ["_locationData", [], [[]]], ["_side", CIVILIAN]];

		OOP_INFO_0("UPDATE LOCATION DATA");
		OOP_INFO_1("location data: %1", _locationData);
		OOP_INFO_2("side: %1   didJip: %2", _side, didJIP);


		pr _varName = switch (_side) do {
			case WEST: {"locationDataWest"};
			case EAST: {"locationDataEast"};
			case INDEPENDENT: {"locationDataInd"};
			default {"ERROR_UNKNOWN_SIDE"};
		};
		pr _ldOld = GET_STATIC_VAR(CLASS_NAME, _varName);

		//Move references for MapMarkers from old location data to new location data
		{ // foreach _ldOld
			pr _oldPos = _x select CLD_ID_POS;
			pr _index = _locationData findIf {
				pr _newPos = _x select CLD_ID_POS;
				_oldPos isEqualTo _newPos
			};
			// If location exists both in new and old array
			if (_index != -1) then {
				pr _mrk = _x select CLD_ID_MARKER;
				(_locationData select _index) set [CLD_ID_MARKER, _mrk];
			} else {
				// If location doesn't exist in new array, delete its marker
				DELETE(_mrk);
			};
		} forEach _ldOld;

		// Now create new markers for locations that are added right now
		{
			pr _mrk = _x select CLD_ID_MARKER;
			if (_mrk == "") then {
				_mrk = NEW("MapMarkerLocation", []);
				_x set [CLD_ID_MARKER, _mrk];
			};

			// Set/update marker properties
			pr _args = [_mrk, _x];
			CALL_STATIC_METHOD(CLASS_NAME, "setLocationMarkerProperties", _args);
		} forEach _locationData;

		SET_STATIC_VAR(CLASS_NAME, _varName, _locationData);
	} ENDMETHOD;

	// Sets text, color, position, and other properties of a marker attached to certain location
	STATIC_METHOD("setLocationMarkerProperties") {
		params ["_thisClass", ["_mapMarker", "", [""]], ["_cld", [], [[]]]];
		pr _type = _cld select CLD_ID_TYPE;
		pr _pos = _cld select CLD_ID_POS;
		pr _side = _CLD select CLD_ID_SIDE;
		pr _text = if (_type != LOCATION_TYPE_UNKNOWN) then {
			pr _t = CALL_STATIC_METHOD("ClientMapUI", "getNearestLocationName", [_pos]);
			if (_t == "") then { // Check if we have got an empty string
				format ["%1 %2", _side, _type]
			} else {
				_t
			};
		} else {
			"??"
		};

		pr _color = switch(_side) do {
			case WEST: {CMUI_ColorWEST};
			case EAST: {CMUI_ColorEAST};
			case INDEPENDENT: {CMUI_ColorInd};
			default {CMUI_ColorUnknown};
		};

		CALLM1(_mapMarker, "setPos", _pos);
		CALLM1(_mapMarker, "setText", _text);
		CALLM1(_mapMarker, "setColor", _color);
	} ENDMETHOD;

	STATIC_METHOD("getLocationData") {
		params ["_thisClass", ["_pos", [], [[]]], ["_side", CIVILIAN]];

		_pos resize 2;

		if (_side == CIVILIAN) then {
			_side = side group player;
		};
		diag_log format ["Searching for location data at pos: %1, side :2", _pos, _side];
		pr _varName = switch (_side) do {
			case WEST: {"locationDataWest"};
			case EAST: {"locationDataEast"};
			case INDEPENDENT: {"locationDataInd"};
		};
		pr _ld = GET_STATIC_VAR(CLASS_NAME, _varName);

		// Find this location in client's database
		pr _index = _ld findif {
			pr _locPos = _x select CLD_ID_POS;

			_pos isEqualTo _locPos;
		};

		if (_index == -1) then {
			diag_log format ["Location data was not found!"];
			[]
		} else {
			diag_log format ["Location data was found: %1", _ld select _index];
			_ld select _index
		};

	} ENDMETHOD;

	// Formats location data and shows it on the location data panel
	STATIC_METHOD("updateLocationDataPanel") {
		params ["_thisClass", ["_intel", "", [""]]];

		pr _typeText = "...";
		pr _timeText = "...";
		pr _compositionText = "...";
		pr _sideText = "...";
		private _listNamePlayersText = "";

		// Did we find a location in the database?
		if (CALLM1(gIntelDatabaseClient, "isIntelAdded", _intel)) then {

			diag_log format ["Location data was found in the database"];

			_typeText = switch (GETV(_intel, "type")) do {
				case LOCATION_TYPE_OUTPOST: {"Outpost"};
				case LOCATION_TYPE_CAMP: {"Camp"};
				case LOCATION_TYPE_BASE: {"Base"};
				case LOCATION_TYPE_UNKNOWN: {"<Unknown>"};
			};
			
			_timeText = str GETV(_intel, "timeUpdated");
			_sideText = str GETV(_intel, "side");

			pr _ua = GETV(_intel, "unitData");
			if (count _ua > 0) then {
				_compositionText = "";
				// Amount of infrantry
				pr _ninf = 0;
				{_ninf = _ninf + _x;} forEach (_ua select T_INF);
				_compositionText = _compositionText + (format ["Soldiers: %1\n", _ninf]);
				// Count vehicles
				pr _uaveh = _ua select T_VEH;
				{
					// If there are some vehicles of this subcategory
					if (_x > 0) then {
						pr _subcatID = _forEachIndex;
						pr _vehName = T_NAMES select T_VEH select _subcatID;
						pr _str = format ["%1: %2\n", _vehName, _x];
						_compositionText = _compositionText + _str;
					};
				} forEach _uaveh;
			} else {
				_compositionText = "<Unknown>";
			};
			diag_log format ["Composition text: %1", _compositionText];
		} else {
			diag_log format ["Location data was NOT found in the database"];
		};

		// Apply new text for GUI elements
		((finddisplay 12) displayCtrl IDC_LD_TYPE) ctrlSetText ("Type: " + _typeText);
		((finddisplay 12) displayCtrl IDC_LD_SIDE) ctrlSetText ("Side: " + _sideText);
		((finddisplay 12) displayCtrl IDC_LD_TIME) ctrlSetText ("Time: " + _timeText);
		((finddisplay 12) displayCtrl IDC_LD_COMPOSITION) ctrlSetText ("Composition:\n" + _compositionText);
		{((finddisplay 12) displayCtrl _x) ctrlCommit 0;} forEach [IDC_LD_TYPE, IDC_LD_SIDE, IDC_LD_TIME, IDC_LD_COMPOSITION, IDC_PL_LISTPLAYERS];
	} ENDMETHOD;

	STATIC_METHOD("showLocationDataPanel") {
		params ["_thisClass", ["_show", true]];

		pr _idcs = [];
	} ENDMETHOD;

	// Returns marker text of closest marker
	STATIC_METHOD("getNearestLocationName") {
		params ["_thisClass", "_pos"];
		pr _return = "";

		{
     		if(((getPos _x) distance _pos) < 100) exitWith {
          		_return =  _x getVariable ["Name", ""];
     		};
		} forEach entities "Project_0_LocationSector";

		_return
	} ENDMETHOD;

ENDCLASS;

// Initialize static variable values
{
	// Make sure we don't override a JIP value
	pr _val = GET_STATIC_VAR(CLASS_NAME, _x);
	if (isNil "_val") then {
		SET_STATIC_VAR(CLASS_NAME, _x, []);
	};
} forEach ["locationDataWest", "locationDataEast", "locationDataInd"];

