

| Tag | Area | Status |
|-----|------|--------|
| [GPS-LOG](#gps-log) | GPS debug logging + GPTH log message | **INACTIVE** |
| [DID-EMERGENCY](#did-emergency) | DroneID custom emergency conditions | **ACTIVE** |
| [DID-EU-CLASS](#did-eu-class) | DroneID EU classification type | **ACTIVE** |
| [DID-OP-LOC](#did-op-loc) | DroneID operator location warning suppressed | **ACTIVE** |
| [DID-DIRECTION](#did-direction) | DroneID direction threshold | **ACTIVE** |
| [DID-UTC](#did-utc) | DroneID UTC timestamp offset | **ACTIVE** |
| [DID-TAKEOFF-LOC](#did-takeoff-loc) | DroneID operator location = takeoff location | **ACTIVE** |
| [DID-RATE](#did-rate) | DroneID MAVLink message rate | **ACTIVE** |
| [BS-PARAMS](#bs-params) | Airframe identity BS_* params via Lua script | **ACTIVE** |

---

## GPS-LOG


### Raw GPS debug logging (`AP_GPS_DEBUG_LOGGING_ENABLED`)

When enabled, writes raw GPS serial bytes to files on the SD card (`gps1_XXX.log`, `gps2_XXX.log`).
These files are compatible with SITL `SIM_GPS_TYPE=7` for driver replay/debugging.
Does **not** affect the `.bin` dataflash log.

**To enable:**

`libraries/AP_GPS/GPS_Backend.h` line 34:
```c
// Change:
#define AP_GPS_DEBUG_LOGGING_ENABLED 0
// To:
#define AP_GPS_DEBUG_LOGGING_ENABLED 1
```

After a flight, check the SD card root for `gps1_001.log`.


### GPTH log message (GPS timing health)

Adds a `GPTH` message to the `.bin` dataflash log with CAN-bus GPS timing health fields:

| Field | Description |
|-------|-------------|
| `DlyC` | Count of delayed GPS frames (>2 = unhealthy) |
| `AvgDlt` | Rolling average GPS update delta in ms (normal limit: 215ms, RTK rover: 333ms) |
| `LagCnt` | Cumulative samples with >50ms extra lag |


**To enable — 4 places must all be changed:**

**1.** `libraries/AP_GPS/LogStructure.h` line 89 — struct definition:
```c
// Change:
#if 0
// To:
#if 1
```

**2.** `libraries/AP_GPS/LogStructure.h` line 11 — log ID registration:
```c
// Uncomment:
/* LOG_GPTH_MSG, */
// To:
LOG_GPTH_MSG,
```

**3.** `libraries/AP_GPS/LogStructure.h` lines 237-238 — log structure entry:
```c
// Uncomment:
/* { LOG_GPTH_MSG, sizeof(log_GPTH),
  "GPTH", "QBBfI", "TimeUS,I,DlyC,AvgDlt,LagCnt", "s#---", "F----", true }, */
// To:
{ LOG_GPTH_MSG, sizeof(log_GPTH),
  "GPTH", "QBBfI", "TimeUS,I,DlyC,AvgDlt,LagCnt", "s#---", "F----", true },
```

**4.** `libraries/AP_GPS/AP_GPS.cpp` line 1937 — write call:
```c
// Change:
#if 0
// To:
#if 1
```

Open the `.bin` log in Mission Planner and check for a `GPTH` message.

---

## DID-EMERGENCY


**File:** `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 374

Adds custom conditions that trigger `MAV_ODID_STATUS_EMERGENCY` in the DroneID location message,
on top of the standard ArduPilot emergency conditions:

| Condition | Trigger |
|-----------|---------|
| Flight mode = AltHold while armed | Mode 2 (Copter only) |
| Battery failsafe triggered while armed | `AP_BattMonitor::has_failsafed()` |
| No RC signal while armed | `rc().has_valid_input() == false` |
| No GCS signal for >5s | `last_system_update_ms` timeout |

**To disable:**
```c
// Change:
#if 1
// To:
#if 0
```

---

## DID-EU-CLASS

**Files:**
- `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 215
- `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 842

Forces `classification_type = MAV_ODID_CLASSIFICATION_TYPE_EU` on the system packet,
both when updating internally and when receiving a system message from a GCS.

---

## DID-OP-LOC


**File:** `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 294-295

Suppresses the `"ODID: lost operator location"` GCS warning.
Operator location is provided via the takeoff GPS fallback (see [DID-TAKEOFF-LOC](#did-takeoff-loc)),
so the warning would be a false alarm.

---

## DID-DIRECTION

**Files:**
- `libraries/AP_OpenDroneID/AP_OpenDroneID.h` line 59 — threshold define
- `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 411 — usage

Only sends a valid heading in the DroneID location message when ground speed exceeds `ODID_MIN_GROUND_SPEED` (0.3 m/s).
Below the threshold, `ODID_INV_DIR` is sent instead, avoiding unreliable direction data at rest.

---

## DID-UTC


**File:** `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 496

Converts GPS time to UTC by subtracting 18 leap seconds:
```c
timestamp = float(time_week_ms % (3600 * 1000)) * 0.001 - 18;
```

---

## DID-TAKEOFF-LOC

**File:** `libraries/AP_OpenDroneID/AP_OpenDroneID.cpp` line 559 (`send_system_update_message`)

Uses the drone's arm location as the operator location in the DroneID system update message.
This avoids requiring an external operator location source (e.g., GCS).

---

## DID-RATE


**File:** `libraries/AP_OpenDroneID/AP_OpenDroneID.h` lines 134-135

Sets the MAVLink DroneID message rates:
```c
const uint32_t _mavlink_dynamic_period_ms = 500;  // 2 Hz — location, system update
const uint32_t _mavlink_static_period_ms  = 500;  // 2 Hz — basic ID, system, self ID, operator ID
```

---

## BS-PARAMS

**Files:** `libraries/AP_HAL_ChibiOS/hwdef/*_C470OP/scripts/BS_Params.lua` (8 identical copies)

Declares the `BS_*` parameter block describing airframe identity, power/payload
configuration and expected environment: `BS_SERIAL_NUM`, `BS_MODEL`, `BS_FRAME_VER`,
`BS_POWER_PLANT`, `BS_PAYLOAD_TYPE`, `BS_PAYLOAD_W`, `BS_TAKEOFF_W`, `BS_BATT_SETUP`,
`BS_ENV_TEMP`, `BS_ENV_WIND`, `BS_ENV_GUST`.

Declarative only — no firmware code reads these back. They exist to identify the
airframe and record its configuration from the GCS and in dataflash logs.

There is deliberately no `BS_ENABLE` gate. Script parameters cannot use
ArduPilot's `AP_PARAM_FLAG_ENABLE` mechanism anyway (`param:add_param` takes no
flags and always creates `AP_PARAM_FLOAT`, while the hide-disabled-group logic in
`AP_Param.cpp:1811-1817` needs `AP_PARAM_INT8` carrying that flag), and a
hand-rolled equivalent would only have hidden eleven declarative parameters at
the cost of a reboot-required step. Adding parameters is the whole job here, so
the script always registers all eleven.

**Deployment:** copy to the SD card at `APM/scripts/`, same as `Hobbywing_DataLink.lua`
and `MotorSafeStop.lua`. Requires `SCR_ENABLE 1`, already set in `defaults.parm`.

**Param table key: 120.** Keys only collide between scripts running on the same
autopilot; ours run `Hobbywing_DataLink` (44), `MotorSafeStop` (61) and this one.
Upstream applets/drivers/examples claim 7-16, 31, 35-48, 51, 70-90, 101, 104, 106,
109, 117, 135-139, 170-176 and 193, so 120 is clear there too. A collision is not
silent — `param:add_table` returns false and the `assert` fails at boot.

Nothing in the firmware assigns meaning to key numbers: `add_table` checks only
that the key is 0-200, does not clash with a compiled-in parameter key, and
matches the stored prefix CRC (`AP_Param.cpp:3005-3028`). 120 is the top of the
101-120 band by internal convention.

### History and caveats

Originally a C++ library, `libraries/BS_Hercules/`, on branch `bs-copter-4.6`
(commits `a72b896e5d`, `932d14b370`, `4d4c734b43`). That branch is **not** an
ancestor of `bs-4.7.0` — their merge base is upstream `1ebd4d996e` — so the params
were absent here until this Lua reimplementation.

Two consequences of moving from C++ to a script:

1. **Storage keys differ.** The C++ version used `k_param_bsHercules` = 260.
   Dynamic script tables live at `AP_PARAM_DYNAMIC_KEY_BASE` (300) + 120 = 420.
   Airframes previously flashed from `bs-copter-4.6` will read defaults; their
   old values sit orphaned in storage and must be re-entered once.

   The table key must not change again after rollout: it *is* the storage
   address, so moving it orphans every stored value on every aircraft.

2. **All values are floats.** `param:add_param` has no integer variant, so
   `BS_SERIAL_NUM` (formerly `AP_Int32`) is exact only to 16777215. Serials above
   that round silently.

Also note the script lives under `hwdef/*/scripts/`, which `param_parse.py` does
not scan (it only walks `AP_Scripting/applets` and `AP_Scripting/drivers`). The
`@Param` metadata in the file is therefore documentation only — the GCS shows
these params without descriptions or value dropdowns. Moving the file to
`libraries/AP_Scripting/applets/` would enable that metadata, at the cost of
leaving the per-board layout.

Two metadata errors in the C++ original were corrected here: `BS_TAKEOFF_W` had
`@Range: 0 -20` (max below min), and `BS_FRAME_VER`'s comment claimed a default
of 3.0 when its values are 1.0/2.0/2.1.
