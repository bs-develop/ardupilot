--[[
   Motor Safety Monitor Script
   Automatically stops motors if they fail to achieve necessary RPM
   Version 1.1
--]]

-- Script Configuration
local SCRIPT_NAME = 'MotorSafeStop'
local RUN_INTERVAL_MS = 250
local PARAM_TABLE_KEY = 61
local PARAM_TABLE_PREFIX = "MSAFE_"

-- Severity levels for better message categorization
local MAV_SEVERITY = {EMERGENCY=0, ALERT=1, CRITICAL=2, ERROR=3, WARNING=4, NOTICE=5, INFO=6, DEBUG=7}

--Settings : Motor configuration
local motor_functions = {33, 34, 35, 36}  -- Motor function numbers
local rpm_sensors = {1, 2, 3, 4}          -- ESC RPM sensor numbers

assert(#motor_functions == #rpm_sensors, "Motor functions and RPM sensors must match in count")


-- Parameter binding helpers
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

-- Read parameters
local ESC_HW_ENABLE = bind_param("ESC_HW_ENABLE")

-- setup script specific parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 4), 'could not add param table')

--[[
  // @Param: ENABLE
  // @DisplayName: Motor Safety Monitor Enable
  // @Description: Enable motor safety monitoring
  // @Values: 0:Disabled,1:Enabled
  // @User: Standard
--]]

PARAM_ENABLE = bind_add_param("ENABLE", 1, 0)

--[[
  // @Param: ARM_DELAY
  // @DisplayName: Arm Delay
  // @Description: Delay after arming before RPM checking starts, preventing immediately 
      disarming the vehicle, when armed but motors are not spinning yet (ms)
  // @Range: 1000 5000
  // @User: Standard
--]]
PARAM_ARM_DELAY = bind_add_param("ARM_DELAY", 2, 5000)

--[[
  // @Param: MIN_RPM
  // @DisplayName: Minimum RPM
  // @Description: Minimum RPM threshold for detecting blocked motor
  // @Range: 100 2000
  // @User: Standard
--]]
PARAM_MIN_RPM = bind_add_param("MIN_RPM", 3, 100)

--[[
  // @Param: MIN_PWM
  // @DisplayName: Minimum PWM
  // @Description: Minimum PWM threshold for RPM checking
  // @Range: 1000 2000
  // @User: Standard
--]]
PARAM_MIN_PWM = bind_add_param("MIN_PWM", 4, 1080)

-- State tracking
local state = {
    script_disabled = false,
    arming_time = 0,
    last_check_time = 0,
    motor_status = {} 
}
-- Initialize motor status tracking
for i = 1, #motor_functions do
    state.motor_status[i] = {
        last_rpm = 0,
        fault_count = 0,
        last_pwm = 0
    }
end


-- Logger setup for debugging and analysis
local function log_motor_data(motor_idx, pwm, rpm, status)
    logger.write('MSAFE', 'TimeUS,Instance,PWM,RPM,Status',
                 'QHHHB', 'F----', 'QBBBB',
                 micros():tofloat(), motor_idx, pwm, rpm, status)
end

-- Motor check function
local function check_motor(motor_idx)
    local motor_pwm = SRV_Channels:get_output_pwm(motor_functions[motor_idx])
    state.motor_status[motor_idx].last_pwm = motor_pwm
    
    if motor_pwm > PARAM_MIN_PWM:get() then
        local motor_rpm = esc_telem:get_rpm(rpm_sensors[motor_idx])
        state.motor_status[motor_idx].last_rpm = motor_rpm
        
        -- Log motor data
        log_motor_data(motor_idx, motor_pwm, motor_rpm, 0)
        
        if motor_rpm < PARAM_MIN_RPM:get() then
            state.motor_status[motor_idx].fault_count = state.motor_status[motor_idx].fault_count + 1
            gcs_msg(MAV_SEVERITY.CRITICAL, string.format("Motor %d low RPM: PWM=%d RPM=%d", 
                   motor_idx, motor_pwm, motor_rpm))
            return false
        end
    end
    return true
end

function update()
    -- First check if HobbyWing ESC telemetry is enabled
    if ESC_HW_ENABLE:get() ~= 1 then
        if not state.script_disabled then
            state.script_disabled = true
            gcs_msg(MAV_SEVERITY.ERROR, "Requires ESC_HW_ENABLE=1")
        end
        return update, RUN_INTERVAL_MS
    end

    if PARAM_ENABLE:get() ~= 1 then
        if not state.script_disabled then
            state.script_disabled = true
            gcs_msg(MAV_SEVERITY.INFO, "Monitoring disabled")
        end
        return update, RUN_INTERVAL_MS
    end

    -- Reset on disarm
    if not arming:is_armed() then
        state.script_disabled = false
        state.arming_time = 0
        for _, status in pairs(state.motor_status) do
            status.fault_count = 0
        end
        return update, RUN_INTERVAL_MS
    end

    -- Disable if likely flying
    if arming:is_armed() and vehicle:get_likely_flying() and not state.script_disabled then
        state.script_disabled = true
        gcs_msg(MAV_SEVERITY.INFO, "Monitoring disabled - Vehicle flying")
        return update, RUN_INTERVAL_MS
    end

    -- Start timer on arm
    if arming:is_armed() and not state.script_disabled and state.arming_time == 0 then
        state.arming_time = millis()
        gcs_msg(MAV_SEVERITY.INFO, "Waiting for motor spinup")
        return update, RUN_INTERVAL_MS
    end

    -- Check motors after delay
    if arming:is_armed() and not state.script_disabled and 
       (state.arming_time + PARAM_ARM_DELAY:get() < millis()) then
        
        local all_motors_ok = true
        for i = 1, #motor_functions do
            if not check_motor(i) then
                all_motors_ok = false
            end
        end

        if not all_motors_ok then
            arming:disarm()
            gcs_msg(MAV_SEVERITY.EMERGENCY, "Motor fault detected - disarming")
        end
    end

    return update, RUN_INTERVAL_MS
end

gcs_msg(MAV_SEVERITY.INFO, "Initialized.")
return update()