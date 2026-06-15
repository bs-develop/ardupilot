

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
