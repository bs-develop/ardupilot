--[[
   Blacksquare Hercules Airframe Parameters
   Declares the BS_* parameter block describing the airframe identity,
   its power/payload configuration and the expected environment.
   Version 1.0
--]]

-- Script Configuration
local SCRIPT_NAME = 'BS_Params'
local PARAM_TABLE_KEY = 120
local PARAM_TABLE_PREFIX = "BS_"

-- Severity levels for better message categorization
local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

-- bind a parameter to a variable given
local function bind_param(name)
    local p = Parameter()
    assert(p:init(name), string.format('could not find %s parameter', name))
    return p
end

-- add a parameter and bind it to a variable
local function bind_add_param(name, idx, default_value)
    assert(param:add_param(PARAM_TABLE_KEY, idx, name, default_value), string.format('could not add param %s', name))
    return bind_param(PARAM_TABLE_PREFIX .. name)
end

-- Message formatting with severity
local function gcs_msg(severity, txt)
    gcs:send_text(severity, string.format('%s: %s', SCRIPT_NAME, txt))
end

-- setup script specific parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 11), 'could not add param table')

--[[
  // @Param: SERIAL_NUM
  // @DisplayName: Serial Number
  // @Description: Unique hardware identifier. 
  // @Range: 0 16777215
  // @Increment: 1
  // @User: Advanced
--]]
local BS_SERIAL_NUM   = bind_add_param('SERIAL_NUM', 1, 0)

--[[
  // @Param: MODEL
  // @DisplayName: Drone Model
  // @Description: Select the specific Hercules drone model.
  // @User: Advanced
--]]
local BS_MODEL        = bind_add_param('MODEL', 2, 0)

--[[
  // @Param: FRAME_VER
  // @DisplayName: Frame Version
  // @Description: Specifies the hardware revision of the drone frame.
  // @Values: 0:1.0,1:2.0,2:2.1
  // @User: Advanced
--]]
local BS_FRAME_VER    = bind_add_param('FRAME_VER', 3, 0)

--[[
  // @Param: POWER_PLANT
  // @DisplayName: Power Plant Configuration
  // @Description: Defines the motor and ESC setup.
  // @User: Advanced
--]]
local BS_POWER_PLANT  = bind_add_param('POWER_PLANT', 4, 0)

--[[
  // @Param: PAYLOAD_TYPE
  // @DisplayName: Attached Payload Type
  // @Description: Identifies the primary payload carried by the drone.
  // @Values: 0:Mjolnir_Gimbal,1:Custom_Camera,2:LiDAR_Scanner,3:Cargo_Drop
  // @User: Standard
--]]
local BS_PAYLOAD_TYPE = bind_add_param('PAYLOAD_TYPE', 5, 0)

--[[
  // @Param: PAYLOAD_W
  // @DisplayName: Payload Weight (kg)
  // @Description: The weight of the attached payload in kilograms. 
  // @Range: 0 10
  // @Increment: 0.1
  // @User: Standard
--]]
local BS_PAYLOAD_W    = bind_add_param('PAYLOAD_W', 6, 0.0)

--[[
  // @Param: TAKEOFF_W
  // @DisplayName: Total Take-off Weight (kg)
  // @Description: The estimated total weight of the drone, including frame, batteries, and payload, at the point of take-off. 
  // @Increment: 0.1
  // @User: Standard
--]]
local BS_TAKEOFF_W    = bind_add_param('TAKEOFF_W', 7, 0.0)

--[[
  // @Param: BATT_SETUP
  // @DisplayName: Battery Configuration
  // @Description: Defines the battery cell count and parallel configuration. 
  // @User: Standard
--]]
local BS_BATT_SETUP   = bind_add_param('BATT_SETUP', 8, 0)

--[[
  // @Param: ENV_TEMP
  // @DisplayName: Ambient Temperature (degC)
  // @Description: The current ambient air temperature at the drone's location. 
  // @Units: degC
  // @Range: -50 70
  // @Increment: 0.1
  // @User: Standard
--]]
local BS_ENV_TEMP     = bind_add_param('ENV_TEMP', 9, 25.0)

--[[
  // @Param: ENV_WIND
  // @DisplayName: Wind Speed (m/s)
  // @Description: Estimated average wind speed at the drone's operating altitude.
  // @Units: m/s
  // @Range: 0 50
  // @Increment: 0.1
  // @User: Standard
--]]
local BS_ENV_WIND     = bind_add_param('ENV_WIND', 10, 0.0)

--[[
  // @Param: ENV_GUST
  // @DisplayName: Wind Gusts (m/s)
  // @Description: Estimated maximum wind gust speed. 
  // @Range: 0 70
  // @Increment: 0.1
  // @User: Standard
--]]
local BS_ENV_GUST     = bind_add_param('ENV_GUST', 11, 0.0)

gcs_msg(MAV_SEVERITY.INFO, string.format('loaded, serial %.0f model %.0f',
                                         BS_SERIAL_NUM:get(), BS_MODEL:get()))