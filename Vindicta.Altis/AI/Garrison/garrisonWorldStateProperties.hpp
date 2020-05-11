#define WSP_GAR_AWARE_OF_ENEMY								 0
#define WSP_GAR_ALL_VEHICLES_REPAIRED						 1
#define WSP_GAR_ALL_VEHICLES_CAN_MOVE						 2
#define WSP_GAR_ALL_HUMANS_HEALED							 3
#define WSP_GAR_ALL_INFANTRY_MOUNTED						 4
#define WSP_GAR_ALL_CREW_MOUNTED							 5
// Handling of vehicles and crew
#define WSP_GAR_ALL_VEHICLE_GROUPS_HAVE_DRIVERS				 6
#define WSP_GAR_ALL_VEHICLE_GROUPS_HAVE_TURRET_OPERATORS	 7
#define WSP_GAR_ALL_VEHICLES_HAVE_CREW_ASSIGNED				 8
#define WSP_GAR_ENGINEER_AVAILABLE							 9
#define WSP_GAR_MEDIC_AVAILABLE								10
#define WSP_GAR_ENOUGH_HUMANS_TO_DRIVE_ALL_VEHICLES			11
#define WSP_GAR_ENOUGH_HUMANS_TO_TURRET_ALL_VEHICLES		12
#define WSP_GAR_ENOUGH_VEHICLES_FOR_ALL_HUMANS				13
// Misc
#define WSP_GAR_POSITION									14 // Position or the current location this garrison is attached to
#define WSP_GAR_CARGO_POSITION								15 // <- this
#define WSP_GAR_VEHICLES_POSITION							16 // <- this
#define WSP_GAR_VEHICLE_GROUPS_MERGED						17
#define WSP_GAR_GROUPS_BALANCED								18
#define WSP_GAR_CLEARING_AREA								19
#define WSP_GAR_CARGO										20
#define WSP_GAR_HAS_CARGO									21
#define WSP_GAR_LOCATION									22 // <- this? Location the garrison is attached to
#define WSP_GAR_HAS_VEHICLES								23
#define WSP_GAR_COUNT										24


#define WSP_GARRISON_NAMES [ \
	"AWARE OF ENEMY", \
	"ALL VEH REPAIRED", \
	"ALL VEH CAN MOVE", \
	"ALL HUMANS HEALED", \
	"ALL INF MOUNTED", \
	"ALL CREW MOUNTED", \
	"ALL VEH GRPS HAVE DRIVERS", \
	"ALL VEH GRPS HAVE TURR OPERATORS", \
	"ALL VEH HAVE CREW ASSIGNED", \
	"ENGINEER AVAILABLE", \
	"MEDIC AVAILABLE", \
	"ENOUGH HUMANS TO DRIVE ALL VEHICLES",  \
	"ENOUGH HUMANS TO TURR ALL VEHICLES", \
	"ENOUGH VEHICLES FOR ALL HUMANS", \
	"POSITION", \
	"CARGO POSITION",  \
	"VEHICLES POSITION", \
	"VEH GROUPS MERGED", \
	"GROUPS BALANCED", \
	"CLEARING AREA", \
	"CARGO", \
	"HAS CARGO",  \
	"LOCATION", \
	"HAS VEHICLES" \
]


// ---- OLD ----

// Garrison moving
//#define WSP_GAR_MOVING									13


// Side ????

// Empty vehicles around are available
//#define WSP_GAR_EMPTY_VEHICLES_AVAILABLE				15

// Arrived at destination
//#define WSP_GAR_ARRIVED_AT_DESTINATION					14

// Need vehicles to reach destination
//#define WSP_GAR_NEED_VEHICLES_TO_REACH_DESTINATION		6
