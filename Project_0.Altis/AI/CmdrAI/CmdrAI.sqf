// #define OOP_DEBUG
// #define OOP_INFO
// #define OOP_WARNING
// #define OOP_ERROR
// #define OOP_PROFILE

#include "common.hpp"

#define ACTION_SCORE_CUTOFF 0.001
#define REINF_MAX_DIST 4000

// Commander planning AI
CLASS("CmdrAI", "")
	VARIABLE("side");
	VARIABLE("activeActions");
	VARIABLE("planningCycle");

	METHOD("new") {
		params [P_THISOBJECT, P_SIDE("_side")];
		T_SETV("side", _side);
		T_SETV("activeActions", []);
		T_SETV("planningCycle", 0);
	} ENDMETHOD;

	METHOD("generateAttackActions") {
		params [P_THISOBJECT, P_STRING("_worldNow"), P_STRING("_worldFuture")];
		T_PRVAR(side);

		private _srcGarrisons = CALLM(_worldNow, "getAliveGarrisons", []) select { 
			// Must be on our side and not involved in another action
			// TODO: We should be able to redirect for QRFs. Perhaps it 
			if((GETV(_x, "side") != _side) or { CALLM(_x, "isBusy", []) }) then {
				false
			} else {
				// Not involved in another reinforce action
				//private _action = CALLM(_x, "getAction", []);
				//if(!IS_NULL_OBJECT(_action) and { OBJECT_PARENT_CLASS_STR(_action) == "ReinforceCmdrAction" }) exitWith {false};

				private _overDesiredEff = CALLM(_worldNow, "getOverDesiredEff", [_x]);

				// Must have at least a minimum strength of twice min efficiency
				//private _eff = GETV(_x, "efficiency");
				// !CALLM(_x, "isDepleted", []) and 
				EFF_GTE(_overDesiredEff, EFF_MIN_EFF)
			}
		};

		// Candidates are clusters that are still alive in the future.
		private _tgtClusters = CALLM(_worldFuture, "getAliveClusters", []);

		private _actions = [];
		{
			private _srcId = GETV(_x, "id");
			{
				private _params = [_srcId, GETV(_x, "id")];
				_actions pushBack (NEW("QRFCmdrAction", _params));
			} forEach _tgtClusters;
		} forEach _srcGarrisons;

		//OOP_INFO_MSG("Considering %1 QRF actions from %2 garrisons to %3 clusters", [count _actions ARG count _srcGarrisons ARG count _tgtClusters]);
		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""action_name"": ""QRF"", ""potential_action_count"": %2, ""src_garrisons"": %3, ""tgt_clusters"": %4}}", _side, count _actions, count _srcGarrisons, count _tgtClusters];
		OOP_INFO_MSG(_str, []);
		#endif

		_actions
	} ENDMETHOD;

	METHOD("generateReinforceActions") {
		params [P_THISOBJECT, P_STRING("_worldNow"), P_STRING("_worldFuture")];
		T_PRVAR(side);

		// Take src garrisons from now, we don't want to consider future resource availability, only current.
		private _srcGarrisons = CALLM(_worldNow, "getAliveGarrisons", []) select { 
			// Must be on our side and not involved in another action
			GETV(_x, "side") == _side and 
			{ !CALLM(_x, "isBusy", []) } and
			{
				// Not involved in another reinforce action
				//private _action = CALLM(_x, "getAction", []);
				//if(!IS_NULL_OBJECT(_action) and { OBJECT_PARENT_CLASS_STR(_action) == "ReinforceCmdrAction" }) exitWith {false};

				private _overDesiredEff = CALLM(_worldNow, "getOverDesiredEff", [_x]);

				// Must have at least a minimum strength of twice min efficiency
				//private _eff = GETV(_x, "efficiency");
				// !CALLM(_x, "isDepleted", []) and 
				EFF_GTE(_overDesiredEff, EFF_MIN_EFF)
			}
		};

		// Take tgt garrisons from future, so we take into account all in progress reinforcement actions.
		private _tgtGarrisons = CALLM(_worldFuture, "getAliveGarrisons", []) select { 
			// Must be on our side
			GETV(_x, "side") == _side and 
			{
				// Not involved in another reinforce action
				private _action = CALLM(_x, "getAction", []);
				IS_NULL_OBJECT(_action) or { OBJECT_PARENT_CLASS_STR(_action) != "ReinforceCmdrAction" }
			} and 
			{
				// Must be under desired efficiency by at least min reinforcement size
				// private _eff = GETV(_x, "efficiency");
				private _overDesiredEff = CALLM(_worldFuture, "getOverDesiredEff", [_x]);
				!EFF_GT(_overDesiredEff, EFF_MUL_SCALAR(EFF_MIN_EFF, -1))
			}
		};

		private _actions = [];
		{
			private _srcId = GETV(_x, "id");
			private _srcFac = GETV(_x, "faction");
			//private _srcPos = GETV(_x, "pos");
			{
				private _tgtId = GETV(_x, "id");
				private _tgtFac = GETV(_x, "faction");
				//private _tgtPos = GETV(_x, "pos");
				if(_srcId != _tgtId 
					and {_srcFac == _tgtFac}
					// and {_srcPos distance _tgtPos < REINF_MAX_DIST}
					) then {
					private _params = [_srcId, _tgtId];
					_actions pushBack (NEW("ReinforceCmdrAction", _params));
				};
			} forEach _tgtGarrisons;
		} forEach _srcGarrisons;

		OOP_INFO_MSG("Considering %1 Reinforce actions from %2 garrisons to %3 garrisons", [count _actions ARG count _srcGarrisons ARG count _tgtGarrisons]);

		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""action_name"": ""Reinforce"", ""potential_action_count"": %2, ""src_garrisons"": %3, ""tgt_garrisons"": %4}}", _side, count _actions, count _srcGarrisons, count _tgtGarrisons];
		OOP_INFO_MSG(_str, []);
		#endif

		_actions
	} ENDMETHOD;

	METHOD("generateRetreatActions") {
		params [P_THISOBJECT, P_STRING("_worldNow"), P_STRING("_worldFuture")];
		T_PRVAR(side);

		// Take src garrisons from future, we want to consider future resource availability.
		private _srcGarrisons = CALLM(_worldNow, "getAliveGarrisons", []) select { 
			// Must be on our side and not involved in another action
			GETV(_x, "side") == _side and 
			// Must be at a location
			{ !IS_NULL_OBJECT(CALLM(_x, "getLocation", [])) } and 
			{ !CALLM(_x, "isBusy", []) } and
			{
				private _overDesiredEff = CALLM(_worldNow, "getOverDesiredEff", [_x]);
				EFF_GTE(_overDesiredEff, EFF_MIN_EFF)
			}
		};

		// Take tgt garrisons from future, so we take into account all in progress reinforcement actions.
		private _tgtGarrisons = CALLM(_worldFuture, "getAliveGarrisons", []) select { 
			// Must be on our side
			GETV(_x, "side") == _side and 
			{
				// Not involved in another reinforce action
				private _action = CALLM(_x, "getAction", []);
				IS_NULL_OBJECT(_action) or { OBJECT_PARENT_CLASS_STR(_action) != "ReinforceCmdrAction" }
			} and 
			{
				// Must be under desired efficiency by at least min reinforcement size
				// private _eff = GETV(_x, "efficiency");
				private _overDesiredEff = CALLM(_worldFuture, "getOverDesiredEff", [_x]);
				!EFF_GT(_overDesiredEff, EFF_MUL_SCALAR(EFF_MIN_EFF, -1))
			}
		};

		private _actions = [];
		{
			private _srcId = GETV(_x, "id");
			private _srcFac = GETV(_x, "faction");
			//private _srcPos = GETV(_x, "pos");
			{
				private _tgtId = GETV(_x, "id");
				private _tgtFac = GETV(_x, "faction");
				//private _tgtPos = GETV(_x, "pos");
				if(_srcId != _tgtId 
					and {_srcFac == _tgtFac}
					// and {_srcPos distance _tgtPos < REINF_MAX_DIST}
					) then {
					private _params = [_srcId, _tgtId];
					_actions pushBack (NEW("ReinforceCmdrAction", _params));
				};
			} forEach _tgtGarrisons;
		} forEach _srcGarrisons;

		OOP_INFO_MSG("Considering %1 Reinforce actions from %2 garrisons to %3 garrisons", [count _actions ARG count _srcGarrisons ARG count _tgtGarrisons]);

		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""action_name"": ""Reinforce"", ""potential_action_count"": %2, ""src_garrisons"": %3, ""tgt_garrisons"": %4}}", _side, count _actions, count _srcGarrisons, count _tgtGarrisons];
		OOP_INFO_MSG(_str, []);
		#endif

		_actions
	} ENDMETHOD;

	METHOD("generateTakeOutpostActions") {
		params [P_THISOBJECT, P_STRING("_worldNow"), P_STRING("_worldFuture")];
		T_PRVAR(activeActions);
		T_PRVAR(side);

		// Take src garrisons from now, we don't want to consider future resource availability, only current.
		private _srcGarrisons = CALLM(_worldNow, "getAliveGarrisons", [["military"]]) select { 
			private _potentialSrcGarr = _x;
			// Must be not already busy 
			!CALLM(_potentialSrcGarr, "isBusy", []) and 
			// Must be at a location
			{ !IS_NULL_OBJECT(CALLM(_potentialSrcGarr, "getLocation", [])) } and 
			// Must not be source of another inprogress take location mission
			{ 
				T_PRVAR(activeActions);
				_activeActions findIf {
					GET_OBJECT_CLASS(_x) == "TakeLocationCmdrAction" and
					{ GETV(_x, "srcGarrId") == GETV(_potentialSrcGarr, "id") }
				} == NOT_FOUND
			} and
			// Must have minimum efficiency available
			{
				private _overDesiredEff = CALLM(_worldNow, "getOverDesiredEff", [_potentialSrcGarr]);
				// Must have at least a minimum available eff
				EFF_GTE(_overDesiredEff, EFF_MIN_EFF)
			}
		};

		// Take tgt locations from future, so we take into account all in progress actions.
		private _tgtLocations = CALLM(_worldFuture, "getLocations", []) select { 
			// Must not have any of our garrisons already present (or this would be reinforcement action)
			IS_NULL_OBJECT(CALLM(_x, "getGarrison", [_side]))
		};

		private _actions = [];
		{
			private _srcId = GETV(_x, "id");
			private _srcPos = GETV(_x, "pos");
			{
				private _tgtId = GETV(_x, "id");
				private _tgtPos = GETV(_x, "pos");
				private _tgtType = GETV(_x, "type");
				private _dist = _srcPos distance _tgtPos;
				if((_tgtType == LOCATION_TYPE_ROADBLOCK and _dist < 3000) or (_tgtType != LOCATION_TYPE_ROADBLOCK and _dist < 10000)) then {
					private _params = [_srcId, _tgtId];
					_actions pushBack (NEW("TakeLocationCmdrAction", _params));
				};
			} forEach _tgtLocations;
		} forEach _srcGarrisons;

		OOP_INFO_MSG("Considering %1 TakeOutpost actions from %2 garrisons to %3 locations", [count _actions ARG count _srcGarrisons ARG count _tgtLocations]);

		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""action_name"": ""TakeOutpost"", ""potential_action_count"": %2, ""src_garrisons"": %3, ""tgt_locations"": %4}}", _side, count _actions, count _srcGarrisons, count _tgtLocations];
		OOP_INFO_MSG(_str, []);
		#endif

		_actions
	} ENDMETHOD;

	METHOD("generatePatrolActions") {
		params [P_THISOBJECT, P_STRING("_worldNow"), P_STRING("_worldFuture")];
		T_PRVAR(activeActions);
		T_PRVAR(side);

		// Take src garrisons from now, we don't want to consider future resource availability, only current.
		private _srcGarrisons = CALLM(_worldNow, "getAliveGarrisons", [["military" ARG "police"]]) select { 
			private _potentialSrcGarr = _x;

			// Must be not already busy 
			!CALLM(_potentialSrcGarr, "isBusy", []) and 
			// Must be at a location
			{ 
				private _loc = CALLM(_potentialSrcGarr, "getLocation", []);
				!IS_NULL_OBJECT(_loc) and 
				{
					GETV(_loc, "type") in [LOCATION_TYPE_OUTPOST, LOCATION_TYPE_BASE]
				}
			} and 
			// Must not be source of another inprogress patrol mission
			{ 
				T_PRVAR(activeActions);
				_activeActions findIf {
					GET_OBJECT_CLASS(_x) == "PatrolCmdrAction" and
					{ GETV(_x, "srcGarrId") == GETV(_potentialSrcGarr, "id") }
				} == NOT_FOUND
			} and
			// Must have minimum patrol available
			{
				private _overEff = GETV(_potentialSrcGarr, "efficiency") - EFF_MIN_EFF;
				// CALLM(_worldNow, "getOverDesiredEff", [_potentialSrcGarr]);
				// Must have at least a minimum available eff
				EFF_GTE(_overEff, EFF_MIN_EFF)
			}
		};

		private _actions = [];
		{
			private _srcId = GETV(_x, "id");
			private _srcPos = GETV(_x, "pos");

			// Take tgt locations from future, so we take into account all in progress actions.
			private _tgtLocations = CALLM(_worldNow, "getNearestLocations", [_srcPos ARG 2000 ARG [LOCATION_TYPE_CITY]]) apply { 
				_x params ["_dist", "_loc"];
				[_srcPos getDir GETV(_loc, "pos"), GETV(_loc, "id")]
			};
			if(count _tgtLocations > 0) then {
				_tgtLocations sort ASCENDING;
				private _routeTargets = _tgtLocations apply {
					_x params ["_dir", "_locId"];
					[TARGET_TYPE_LOCATION, _locId]
				};
				private _params = [_srcId, _routeTargets];
				_actions pushBack (NEW("PatrolCmdrAction", _params));
			};
		} forEach _srcGarrisons;

		OOP_INFO_MSG("Considering %1 Patrol actions from %2 garrisons", [count _actions ARG count _srcGarrisons]);

		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""action_name"": ""Patrol"", ""potential_action_count"": %2, ""src_garrisons"": %3}}", _side, count _actions, count _srcGarrisons];
		OOP_INFO_MSG(_str, []);
		#endif

		_actions
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_world")];

		// Sync before update
		CALLM(_world, "sync", []);

		T_PRVAR(side);
		T_PRVAR(activeActions);

		OOP_DEBUG_MSG("- - - - - U P D A T I N G - - - - -   on %1 active actions", [count _activeActions]);

		// Update actions in real world
		{ 
			OOP_DEBUG_MSG("Updating action %1", [_x]);
			CALLM(_x, "update", [_world]);
		} forEach _activeActions;

		// Remove complete actions
		{ 
			OOP_DEBUG_MSG("Completed action %1, removing", [_x]);
			_activeActions deleteAt (_activeActions find _x);
			UNREF(_x);
		} forEach (_activeActions select { CALLM(_x, "isComplete", []) });

		OOP_DEBUG_MSG("- - - - - U P D A T I N G   D O N E - - - - -", []);

		#ifdef OOP_INFO
		private _str = format ["{""cmdrai"": {""side"": ""%1"", ""active_actions"": %2}}", _side, count _activeActions];
		OOP_INFO_MSG(_str, []);
		#endif
	} ENDMETHOD;

	STATIC_METHOD("getActionGlobalPriority") {
		params [P_THISCLASS, P_OOP_OBJECT("_action")];
		private _class = GET_OBJECT_CLASS(_action);
		switch(GET_OBJECT_CLASS(_action)) do {
			case "QRFCmdrAction": { 3 };
			case "ReinforceCmdrAction": { 2 };
			default { 1 };
		}
	} ENDMETHOD;
	
	METHOD("selectActions") {
		params [P_THISOBJECT, P_ARRAY("_actionFuncs"), P_NUMBER("_maxNewActions"), P_OOP_OBJECT("_world"), P_OOP_OBJECT("_simWorldNow"), P_OOP_OBJECT("_simWorldFuture")];

		CALLM(_simWorldNow, "resetScoringCache", []);
		CALLM(_simWorldFuture, "resetScoringCache", []);

		private _newActions = [];

		{
			_newActions = _newActions + T_CALLM(_x, [_simWorldNow ARG _simWorldFuture]);
		} forEach _actionFuncs;

		private _newActionCount = 0;
		while {(count _newActions > 0) and _newActionCount < _maxNewActions} do {

			OOP_DEBUG_MSG("Updating scoring for %1 new actions", [count _newActions]);
			PROFILE_SCOPE_START(UpdateScores)

			// Update scores of potential actions against the simworld state
			{
				CALLM(_x, "updateScore", [_simWorldNow ARG _simWorldFuture]);
			} forEach _newActions;

			PROFILE_SCOPE_END(UpdateScores, 0.1);

			// Sort the actions by their scores
			private _scoresAndActions = _newActions apply { 
				private _finalScore = CALLM(_x, "getFinalScore", []);
				//private _priority = if(_finalScore > ACTION_SCORE_CUTOFF) then { CALLSM("CmdrAI", "getActionGlobalPriority", [_x]) } else { 0 };
				[_finalScore, _x] 
			};

			_scoresAndActions sort DESCENDING;

			// _newActions = [_newActions, [], { CALLM(_x, "getFinalScore", []) }, "DECEND"] call BIS_fnc_sortBy;

			// Get the best scoring action
			(_scoresAndActions select 0) params ["_bestActionScore", "_bestAction"];

			// private _bestActionScore = // CALLM(_bestAction, "getFinalScore", []);
			
			// Some sort of cut off needed here, probably needs tweaking, or should be strategy based?
			// TODO: Should we maybe be normalizing scores between 0 and 1?
			if(_bestActionScore <= ACTION_SCORE_CUTOFF) exitWith {};

			OOP_DEBUG_MSG("Selected new action %1 (score %2), applying it to the simworlds", [_bestAction ARG _bestActionScore]);

			// Add the best action to our active actions list
			REF(_bestAction);

			T_PRVAR(activeActions);
			_activeActions pushBack _bestAction;

			// Remove it from the possible actions list
			_newActions deleteAt (_newActions find _bestAction);

			PROFILE_SCOPE_START(ApplyNewActionToSim);

			// Apply the new action effects to simworld, so next loop scores update appropriately
			// (e.g. if we just accepted a new reinforce action, we should update the source and target garrison
			// models in the sim so that other reinforce actions will take it into account in their scoring.
			// Probably other reinforce actions with the same source or target would have lower scores now).
			CALLM(_bestAction, "applyToSim", [_simWorldNow]);
			CALLM(_bestAction, "applyToSim", [_simWorldFuture]);

			PROFILE_SCOPE_END(ApplyNewActionToSim, 0.1);

			_newActionCount = _newActionCount + 1;
		};

		// Delete any remaining discarded actions
		{
			DELETE(_x);
		} forEach _newActions;
	} ENDMETHOD;

	METHOD("plan") {
		params [P_THISOBJECT, P_OOP_OBJECT("_world")];
		
		T_PRVAR(planningCycle);
		T_SETV("planningCycle", _planningCycle + 1);

		private _priority = switch true do {
			case (round (_planningCycle mod CMDR_PLANNING_RATIO_HIGH) == 0): { CMDR_PLANNING_PRIORITY_HIGH };
			case (round (_planningCycle mod CMDR_PLANNING_RATIO_NORMAL) == 0): { CMDR_PLANNING_PRIORITY_NORMAL };
			case (round (_planningCycle mod CMDR_PLANNING_RATIO_LOW) == 0): { CMDR_PLANNING_PRIORITY_LOW };
			default { -1 };
		};

		if(_priority != -1) then {
			T_CALLM("_plan", [_world ARG _priority]);
		};
	} ENDMETHOD;

	METHOD("_plan") {
		params [P_THISOBJECT, P_STRING("_world"), P_NUMBER("_priority")];

		OOP_DEBUG_MSG("- - - - - P L A N N I N G (priority %1) - - - - -", [_priority]);

		// Sync before planning
		CALLM(_world, "sync", []);
		// Update grids etc.
		CALLM(_world, "update", []);

		T_PRVAR(activeActions);

		OOP_DEBUG_MSG("Creating new simworlds from %1", [_world]);

		// Copy world to simworld, now and future
		private _simWorldNow = CALLM(_world, "simCopy", [WORLD_TYPE_SIM_NOW]);
		private _simWorldFuture = CALLM(_world, "simCopy", [WORLD_TYPE_SIM_FUTURE]);

		OOP_DEBUG_MSG("Applying %1 active actions to simworlds", [count _activeActions]);

		// Apply effects of active actions to the simworld
		PROFILE_SCOPE_START(ApplyActive);
		{
			CALLM(_x, "applyToSim", [_simWorldNow]);
			CALLM(_x, "applyToSim", [_simWorldFuture]);
		} forEach _activeActions;
		PROFILE_SCOPE_END(ApplyActive, 0.1);

		OOP_DEBUG_MSG("Generating new actions", []);

		private _maxNewActions = 2;
		private _generators = switch(_priority) do {
			case CMDR_PLANNING_PRIORITY_HIGH: {
				["generateAttackActions"]
			};
			case CMDR_PLANNING_PRIORITY_NORMAL: {
				["generateReinforceActions", "generatePatrolActions"]
			};
			case CMDR_PLANNING_PRIORITY_LOW: {
				["generateTakeOutpostActions"]
			};
		};

		T_CALLM("selectActions", [_generators ARG _maxNewActions ARG _world ARG _simWorldNow ARG _simWorldFuture]);

		DELETE(_simWorldNow);
		DELETE(_simWorldFuture);

		OOP_DEBUG_MSG("- - - - - P L A N N I N G   D O N E - - - - -", []);
	} ENDMETHOD;
	
ENDCLASS;
