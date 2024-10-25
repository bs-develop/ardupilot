-- Safety function to stop all motors if they are no able to pick up neccessary RPM (aka blocked)
-- by EOSBandi 2024
-- Version 1.0

local SCRIPT_NAME     = 'MotorSafeStop.lua'
local RUN_INTERVAL_MS = 250

--Settings : Enter motor functions here in the order as motors are configured 
local motor_functions = {33, 34, 35, 36}
-- Enter ESCx_RPM sensor numberd here in the order as motors are configured
local rpm_sensors     = {1,2,3,4}



-- the table key must be used by only one script on a particular flight
-- controller. If you want to re-use it then you need to wipe your old parameters
-- the key must be a number between 0 and 200. The key is persistent in storage
local PARAM_TABLE_KEY = 75
local PARAM_TABLE_PREFIX = "KILL_"

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

-- format GCS output
local function gcs_msg(severity, txt)
    gcs:send_text(severity, string.format('%s: %s', SCRIPT_NAME, txt))
end


-- setup script specific parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 3), 'could not add param table')

-- Delay after arm to check for RPM, this is the motor spinup time,  , when armed but motors are 
-- not spinning yet (in milliseconds)
PARAM_ARM_DELAY = bind_add_param("ARM_DELAY", 1, 2000)
-- mimum rpm, is the rpm is below this number we assume that the motor is blocked and disarm the vehicle
PARAM_MIN_RPM = bind_add_param("MIN_RPM", 2, 100)
-- minimum PWM where the motor should rotate
PARAM_MIN_PWM = bind_add_param("MIN_PWM", 3, 1080)

-- Local variables for the script, do not change!
local script_disabled = false
local arming_time = 0

function update()

 -- if we we are disarmed and script is disabled then enable script 
if (not arming:is_armed()) then
    script_disabled = false
    arming_time = 0
    return update, 250
end

-- if we armed and likely flying and the script is enabled then disable the script 
 if arming:is_armed() and vehicle:get_likely_flying() and (not script_disabled) then
    script_disabled = true
    -- gcs:send_text(0, "Disable script")
    return update, 250
end

 -- At arm start timer for spinup
if (arming:is_armed() and (not script_disabled)) and arming_time == 0 then
    arming_time = millis()
    -- gcs:send_text(0, "Wait for spinup")
    return update, 250
end
-- if we are armed and script is enabled then check for motor RPM
if arming:is_armed() and (not script_disabled) and (arming_time + PARAM_ARM_DELAY:get() < millis()) then
    -- gcs:send_text(0, "Checking motors")
    for i = 1, #motor_functions do
        local motor_pwm = SRV_Channels:get_output_pwm(motor_functions[i])
        -- gcs:send_text(0, "Motor "..i.." PWM: "..motor_pwm)
        if motor_pwm > PARAM_MIN_PWM:get() then
            local motor_rpm = esc_telem:get_rpm(rpm_sensors[i])
            -- gcs:send_text(0, "Motor "..i.." RPM: ".. motor_rpm)
            if motor_rpm < PARAM_MIN_RPM:get() then
                arming:disarm()
                gcs_msg(0,"Motor "..i.." lock, disarming.")
            end
        end
    end
end

return update, RUN_INTERVAL_MS
end
gcs_msg(6, "Initialized.")
return update()