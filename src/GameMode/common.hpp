#define OFSTREAM_FILE "GameMode.rpt"

#include "..\common.h"
#include "..\Message\Message.hpp"
#include "..\CriticalSection\CriticalSection.hpp"
#include "..\AI\Commander\AICommander.hpp"
#include "..\AI\Commander\LocationData.hpp"
#include "..\AI\parameterTags.hpp"
#include "..\Group\Group.hpp"
#include "..\Garrison\Garrison.hpp"
#include "..\Location\Location.hpp"
#include "..\CivilianPresence\CivilianPresence.hpp"
#include "..\Undercover\UndercoverMonitor.hpp"

#define CITY_STATE_NEUTRAL 0
#define CITY_STATE_FRIENDLY_CONTROL 1
#define CITY_STATE_ENEMY_CONTROL 2
