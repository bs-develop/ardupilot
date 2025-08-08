#include "BS_Hercules.h" // Must include your own header file!

const AP_Param::GroupInfo BS_Hercules::var_info[] = {

    // @Param: SERIAL_NUM
    // @DisplayName: Serial Number
    // @Description: Unique hardware identifier (ASCII-encoded). Up to 15 characters.
    // @User: Advanced
    AP_GROUPINFO("SERIAL_NUM", 0, BS_Hercules, _serial_number, 0000),

    // @Param: MODEL
    // @DisplayName: Drone Model
    // @Description: Select the specific Hercules drone model. This helps the flight controller configure itself for the correct airframe.
    // @Values: 0:Hercules X4,1:Hercules X8,2:Hercules X4 Heavy,3:Hercules X8 Heavy
    // @User: Advanced
    AP_GROUPINFO("MODEL", 1, BS_Hercules, _model, 0), // Default to Hercules X4 (value 0)

    // @Param: FRAME_VER
    // @DisplayName: Frame Version
    // @Description: Specifies the hardware revision of the drone frame. Important for compatibility with certain components.
    // @Values: 0:1.0,1:2.0,2:2.1
    // @User: Advanced
    AP_GROUPINFO("FRAME_VER", 2, BS_Hercules, _frame_version, 0), // Default to 3.0 (value 0)

    // @Param: POWER_PLANT
    // @DisplayName: Power Plant Configuration
    // @Description: Defines the motor and ESC setup. Correct selection is vital for thrust calculations and motor limits.
    // @Values: 0:Power Plant 28,1:Power Plant 30
    // @User: Advanced
    AP_GROUPINFO("POWER_PLANT", 3, BS_Hercules, _power_plant, 0), // Default to Power Plant 28 (value 0)

    // @Param: PAYLOAD_TYPE
    // @DisplayName: Attached Payload Type
    // @Description: Identifies the primary payload carried by the drone. Can influence flight characteristics and mission planning.
    // @Values: 0:Mjolnir_Gimbal,1:Custom_Camera,2:LiDAR_Scanner,3:Cargo_Drop
    // @User: Standard
    AP_GROUPINFO("PAYLOAD_TYPE", 4, BS_Hercules, _payload_type, 0), // Default to Mjolnir_Gimbal (value 0)

    // @Param: PAYLOAD_W
    // @DisplayName: Payload Weight (kg)
    // @Description: The weight of the attached payload in kilograms. Crucial for accurate flight performance and battery consumption estimates.
    // @Units: kg
    // @Range: 0 10
    // @Increment: 0.1
    // @User: Standard
    AP_GROUPINFO("PAYLOAD_W", 5, BS_Hercules, _payload_weight, 0.0f), // Default to 0.0 kg

    // @Param: TAKEOFF_W
    // @DisplayName: Total Take-off Weight (kg)
    // @Description: The estimated total weight of the drone, including frame, batteries, and payload, at the point of take-off. Essential for flight envelope calculations.
    // @Units: kg
    // @Range: 0 -20
    // @Increment: 0.1
    // @User: Standard
    AP_GROUPINFO("TAKEOFF_W", 6, BS_Hercules, _takeoff_weight, 0.0f), // Default to 0.0 kg

    // @Param: BATT_SETUP
    // @DisplayName: Battery Configuration
    // @Description: Defines the battery cell count and parallel configuration. Affects voltage, capacity, and discharge rates.
    // @Values: 0:6S_2P,1:12S_1P,2:6S_4P,3:12S_2P
    // @User: Standard
    AP_GROUPINFO("BATT_SETUP", 7, BS_Hercules, _battery_setup, 0), // Default to 6S 2P (value 0)

    // Environmental Parameters (can be read-only or editable depending on source)
    // @Param: ENV_TEMP
    // @DisplayName: Ambient Temperature (°C)
    // @Description: The current ambient air temperature at the drone's location. Used for environmental compensation in some flight models.
    // @Range: -50 70
    // @Increment: 0.1
    // @User: Standard
    AP_GROUPINFO("ENV_TEMP", 8, BS_Hercules, _temperature, 25.0f), // Default to 25.0 °C

    // @Param: ENV_WIND
    // @DisplayName: Wind Speed (m/s)
    // @Description: Estimated average wind speed at the drone's operating altitude. Useful for flight planning and energy consumption estimates.
    // @Units: m/s
    // @Range: 0 50
    // @Increment: 0.1
    // @User: Standard
    AP_GROUPINFO("ENV_WIND", 9, BS_Hercules, _wind_speed, 0.0f), // Default to 0.0 m/s

    // @Param: ENV_GUST
    // @DisplayName: Wind Gusts (m/s)
    // @Description: Estimated maximum wind gust speed. Important for safety margins and flight performance limits.
    // @Units: m/s
    // @Range: 0 70
    // @Increment: 0.1
    // @User: Standard
    AP_GROUPINFO("ENV_GUST", 10, BS_Hercules, _wind_gust, 0.0f), // Default to 0.0 m/s

    AP_GROUPEND // Marks the end of the parameter group
};