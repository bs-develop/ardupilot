#pragma once

#include <AP_Param/AP_Param.h> // Include the ArduPilot parameter library

class BS_Hercules {
public:
    // Constructor: This is crucial! It initializes the parameter system for this object.
    BS_Hercules() {
        AP_Param::setup_object_defaults(this, var_info);
    }

    // Static member to hold the parameter group information.
    static const struct AP_Param::GroupInfo var_info[];

protected:
    // Declare the AP_Param types for each parameter.
    // Fixed / Non-editable (read-only in concept, still an AP_Param type)
    AP_Int32 _serial_number;

    // Editable enumerations (AP_Int8 is sufficient for most enum values 0-255)
    AP_Int8 _model;
    AP_Int8 _frame_version;
    AP_Int8 _power_plant;
    AP_Int8 _payload_type;
    AP_Int8 _battery_setup;

    // Editable numeric values (AP_Float for floating-point numbers)
    AP_Float _payload_weight;
    AP_Float _takeoff_weight;

    // Environmental variables (also floating-point)
    AP_Float _temperature;
    AP_Float _wind_speed;
    AP_Float _wind_gust;
};