#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR
#define OFSTREAM_FILE "Intel.rpt"
#include "..\OOP_Light\OOP_Light.h"
#include "..\Location\Location.hpp"
#include "InventoryItems.hpp"
#include "PersonalInventory.hpp"
#include "..\GlobalAssert.hpp"

/*
A class with static functions that initialized variables on objects that can have intel.
Author: Sparker 18.05.2019
*/

#define pr private

#define HAS_INTEL_VAR_NAME "__int"

CLASS("UnitIntel", "")

	STATIC_VARIABLE("eventHandlerAdded");

	/*
	Method: (static)initUnit
	Call it on server.
	It initializes intel on some unit

	Parameters: _unit

	_unit - Unit object

	Returns: nil
	*/
	STATIC_METHOD("initUnit") {
		params [P_THISCLASS, P_OOP_OBJECT("_unit")];

		ASSERT_GLOBAL_OBJECT(gPersonalInventory);

		// Civilians are not having any of the intel items for now
		pr _gar = CALLM0(_unit, "getGarrison");
		if (CALLM0(_gar, "getSide") == CIVILIAN) exitWith {};

		if (CALLM0(_unit, "isInfantry")) then {
			pr _group = CALLM0(_unit, "getGroup");
			pr _groupLeader = CALLM0(_group, "getLeader");
			// Only leaders have tablets with intel now
			if (true) then { //_unit == _groupLeader) then {
				// Get an inventory item class name
				pr _baseClass = selectRandom INTEL_INVENTORY_TABLET_CLASSES;
				pr _IDs = CALLM2(gPersonalInventory, "getInventoryClassIDs", _baseClass, 1);

				// Bail if we have failed to find a free inventory item class name
				if (count _IDs == 0) exitWith {};

				pr _gar = CALLM0(_unit, "getGarrison");
				pr _AI = CALLM0(_gar, "getAI");
				pr _dataSerial = CALLM0(_AI, "getUnitIntelDataSerial");
				CALLM3(gPersonalInventory, "setInventoryData", _baseClass, _IDs#0, _dataSerial);

				// Add to uniform
				pr _hO = CALLM0(_unit, "getObjectHandle");
				_hO addItemToUniform PERSONAL_INVENTORY_FULL_CLASS(_baseClass, _IDs#0);

				// Add event handler to free the used inventory items when the unit is destroyed
				_hO addEventHandler ["Deleted", { 
					params ["_entity"];
					pr _allItems = (uniformItems _entity) + (vestItems _entity) + (backpackItems _entity);
					// Find all inventory items which are of a certain class name
					pr _personalInventoryItems = _allItems select {
						pr _fullClassName = _x;
						pr _index = INTEL_INVENTORY_ALL_CLASSES findIf {(_fullClassName find _x) == 0 };
						_index != -1
					};

					{
						pr _classAndID = CALLSM1("PersonalInventory", "getBaseClassAndID", _x);
						_classAndID params ["_baseClass", "_ID"];
						// Reset the data to return the inventory item back to the pool of free classes
						CALLM3(gPersonalInventory, "setInventoryData", _baseClass, _ID, nil);
					} forEach _personalInventoryItems;
				}];
			};
		} else {
			// Get an inventory item class name
			pr _baseClass = selectRandom INTEL_INVENTORY_TABLET_CLASSES;
			pr _IDs = CALLM2(gPersonalInventory, "getInventoryClassIDs", _baseClass, 1);

			// Bail if we have failed to find a free inventory item class name
			if (count _IDs == 0) exitWith {};

			pr _gar = CALLM0(_unit, "getGarrison");
			pr _AI = CALLM0(_gar, "getAI");
			pr _dataSerial = CALLM0(_AI, "getUnitIntelDataSerial");
			CALLM3(gPersonalInventory, "setInventoryData", _baseClass, _IDs#0, _dataSerial);

			// Add to the cargo
			pr _hO = CALLM0(_unit, "getObjectHandle");
			_hO addMagazineCargoGlobal [PERSONAL_INVENTORY_FULL_CLASS(_baseClass, _IDs#0), 1];

			// Add event handler to free the used inventory items when the unit is destroyed
			_hO addEventHandler ["Deleted", { 
				params ["_entity"];
				pr _allItems = (getMagazineCargo _entity)#0;
				// Find all inventory items which are of a certain class name
				pr _personalInventoryItems = _allItems select {
					pr _fullClassName = _x;
					pr _index = INTEL_INVENTORY_ALL_CLASSES findIf {(_fullClassName find _x) == 0 };
					_index != -1
				};

				{
					pr _classAndID = CALLSM1("PersonalInventory", "getBaseClassAndID", _x);
					_classAndID params ["_baseClass", "_ID"];
					// Reset the data to return the inventory item back to the pool of free classes
					CALLM3(gPersonalInventory, "setInventoryData", _baseClass, _ID, nil);
				} forEach _personalInventoryItems;
			}];
		};

	} ENDMETHOD;

	/*
	Method: (static)updateUnit
	NOT USED RIGHT NOW
	Call it on server.
	It keeps intel inventory items of some unit up to date

	Parameters: _unit

	_unit - Unit object

	Returns: nil
	*/
	STATIC_METHOD("updateUnit") {
		params [P_THISCLASS, P_OOP_OBJECT("_unit")];

		// Get all inventory items of the unit which match the pattern
		pr _hO = CALLM0(_unit, "getObjectHandle");
		
		pr _allItems = (uniformItems _hO) + (vestItems _hO) + (backpackItems _hO);
		// Find all inventory items which are of a certain class name
		pr _personalInventoryItems = _allItems select {
			pr _fullClassName = _x;
			pr _index = INTEL_INVENTORY_ALL_CLASSES findIf {(_fullClassName find _x) == 0 };
			_index != -1
		};

		// Iterate through all personal inventory items and update their values
		pr _gar = CALLM0(_unit, "getGarrison");
		pr _intelArray = CALLM0(_gar, "getIntel");
		{
			pr _classAndID = CALLSM1("PersonalInventory", "getBaseClassAndID", _x);
			_classAndID params ["_baseClass", "_ID"];
			CALLM3(gPersonalInventory, "setInventoryData", _baseClass, _ID, _intelArray);
		} forEach _personalInventoryItems;

	} ENDMETHOD;

	/*
	Method: (static)initPlayer
	Call it on player's computer when he respawns to to add actions to player to take intel items

	Parameters: _hO

	_hO - player's object

	Returns: nil
	*/
	STATIC_METHOD("initPlayer") {
		params [P_THISCLASS];

		diag_log "--- initPlayer";

		//player removeAllEventHandlers "InventoryOpened";
		if (! GET_STATIC_VAR(_thisClass, "eventHandlerAdded") || !isMultiplayer) then { // In singleplayer event handler doesn't get magically on respawn transfered :/

			diag_log "--- adding event handler";

			/*
			// Old code which would examing intel when player would double click it
			player addEventHandler ["InventoryOpened", 
			{

				diag_log "--- Inventory opened event handler!";

				[{!isNull (findDisplay 602)}, {
					
					{ // forEach [619, 633, 638];

						(finddisplay 602 displayctrl _x) ctrlAddEventHandler ["LBDblClick", {

							params ["_control", "_selectedIndex"];
							_data = _control lbData _selectedIndex;
							diag_log format ["Dbl click: index: %1, data: %2", _selectedIndex, _data];
							
							// Check if the class name of this item belongs to one of the predefined class names
							pr _index = INTEL_INVENTORY_ALL_CLASSES findIf {
								(_data find _x) == 0
							};

							if (_index != -1) then { // If it's the document item, delete it and 'inspect' it
								// Call code to inspect the intel item
								CALLSM1("UnitIntel", "inspectIntel", _data);

								// Delete this document item from inventory
								[{ // call CBA_fnc_waitAndExecute
									params ["_IDC", "_data"];
									//diag_log format ["Inside waitAndExecute: %1", _this];
									switch (_IDC) do {
										case 619: {diag_log "Backpack"; player removeItemFromBackpack _data;};
										case 633: {diag_log "Uniform"; player removeItemFromUniform _data;};
										case 638: {diag_log "Vest"; player removeItemFromVest _data;};
									};
								}, [ctrlIDC _control, _data], 0] call CBA_fnc_waitAndExecute; // Can't remove the item right in this frame because it will crash the game
							
							}; // if (_data == ...)

						} ]; // ctrlAddEventHandler

					} forEach [619, 633, 638]; // These are IDCs of the uniform, vest and backpack containers

				}, []] call CBA_fnc_waitUntilAndExecute;

			}]; // Add event handler
			
			// 633 - uniform
			// 619 - backpack
			// 638 - vest

			*/


			private _ehid = player addEventHandler ["Take", 
			{
				params ["_unit", "_container", "_item"];

				// Check if the class name of this item belongs to one of the predefined class names
				pr _index = INTEL_INVENTORY_ALL_CLASSES findIf {
					(_item find _x) == 0
				};

				if (_index != -1) then { // If it's the document item, delete it and 'inspect' it
					// Call code to inspect the intel item
					CALLSM1("UnitIntel", "inspectIntel", _item);

					// Delete this document item from inventory
					[{ // call CBA_fnc_waitAndExecute
						params ["_item"];
						//diag_log format ["Inside waitAndExecute: %1", _this];
						player removeItemFromBackpack _item;
						player removeItemFromUniform _item;
						player removeItemFromVest _item;
					}, [_item], 0] call CBA_fnc_waitAndExecute; // Can't remove the item right in this frame because it will crash the game
				
				};
			}];
			player setVariable ["UnitIntel_take_EH", _ehid];

			SET_STATIC_VAR("UnitIntel", "eventHandlerAdded", true);
		};
		
	} ENDMETHOD;

	// Called on player's computer when he picks up the intel item
	STATIC_METHOD("inspectIntel") {
		params ["_thisObject", ["_fullClassName", "", [""]] ];

		// Get base class name and ID of this intel item
		pr _classAndID = CALLSM1("PersonalInventory", "getBaseClassAndID", _fullClassName);
		_classAndID params ["_baseClass", "_ID"];

		// Tell to commander! He must know about it :D !
		pr _playerCommander = CALLSM1("AICommander", "getCommanderAIOfSide", playerSide);
		//CALLM2(_playerCommander, "postMethodAsync", "getRandomIntelFromEnemy", [clientOwner]);
		CALLM2(_playerCommander, "postMethodAsync", "getIntelFromInventoryItem", [_baseClass ARG _ID ARG clientOwner]);
		//REMOTE_EXEC_CALL_METHOD(_playerCommander, "getIntelFromInventoryItem", [_baseClass ARG _ID ARG clientOwner], 2);

		private _inst = CALLSM0("TacticalTablet", "newInstance");

		private _tipOfTheDay = 	[	"Always wear a helmet, even at base!",
									"Have you checked your ammo?",
									"Stay alert when on patrol!",
									"Ensure your radio frequency and channel!",
									"Never do a selfie in fight!",
									"Remember to stay in formation, ... but not too close!",
									"Remember to check fuel of your vehicles!",
									"Find your gun safety switch before fight!"];

		// Make us some time while we are waiting for server response...
		CALLM2(_inst,"appendTextDelay", "Welcome to TactiCool OS v28.3!\nDetected 128 GB RAM, 16 TB SSD\n", 0.1);
		pr _text = format ["System date: %1, grid: %2\n", date, mapGridPosition player];
		CALLM2(_inst,"appendTextDelay", _text, 0.2);
		pr _text = format ["User class: %1\n", typeof player];
		CALLM2(_inst,"appendTextDelay", _text, 0.2);

		CALLM2(_inst,"appendTextDelay", "\nTip of the day:\n",  0.1 + random 0.2);
		CALLM2(_inst,"appendTextDelay", selectrandom _tipOfTheDay, 0);
		CALLM2(_inst,"appendTextDelay", "\n", 0);

		CALLM2(_inst,"appendTextDelay", "\nConnecting to TactiCommNetwork server...\n",  0.15 + random 0.2);
		CALLM2(_inst,"appendTextDelay", "Tx SYN\n",  0.2 + random 0.2);
		CALLM2(_inst,"appendTextDelay", "Rx SYN-ACK\nTx ACK\n",  0.2 + random 0.2);
		//CALLM2(_inst,"appendTextDelay", ".", 0.3);
		//CALLM2(_inst,"appendTextDelay", ".", 0.3);
		//CALLM2(_inst,"appendTextDelay", ".", 0.1);
		CALLM2(_inst,"appendTextDelay", "Tx RQ-DATA\n", 0.2);
		CALLM2(_inst,"appendTextDelay", "Rx INTEL_CMDR_ACTION\n", 0.2);
		CALLM2(_inst,"appendTextDelay", "\nConnection established!\n", 0.1);

		CALLM2(_inst, "setTextDelay", "Logged in Altis Armed Forces TactiCommNetWork\n", 0.4);

		/*
		pr _intelDataSerial = CALLM2(gPersonalInventory, "getInventoryData", _baseClass, _ID);
		{
			CALLM2(_inst,"appendTextDelay", str _x, 0);
			CALLM2(_inst,"appendTextDelay", "\n", 0);
		} forEach _intelDataSerial;
		*/

	} ENDMETHOD;

ENDCLASS;

SET_STATIC_VAR("UnitIntel", "eventHandlerAdded", false);