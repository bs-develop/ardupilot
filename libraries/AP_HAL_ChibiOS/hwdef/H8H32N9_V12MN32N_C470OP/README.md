# H8H32N9_V12MN32N_C470OP — OctaQuad X8 Custom Firmware Target

**Hardware:** CubePilot CubeOrange+ (STM32H757xx)
**Frame:** OctaQuad X — 8 motors
**Powerplant:** TMotor MN8017 KV120 + V120A CAN ESC + 32" propellers
**Firmware base:** ArduCopter 4.6.x
**Full hardware docs:** [Cube Module Overview](https://docs.cubepilot.org/user-guides/autopilot/the-cube-module-overview)
**Pinout reference:** `CubeOrange-pinout.svg`

---

## Hardware Summary

| Component | Detail |
|---|---|
| FMU | STM32H757 |
| IOMCU | STM32F103 |
| IMUs | ICM42688, ICM20948, ICM20649 (first two vibration-isolated) |
| Barometers | 2× MS5611 |
| Magnetometer | AK09916 (built into ICM20948) |
| IMU heater | `BRD_HEAT_TARG` [°C] — set to 45 |
| Storage | microSD |
| Interfaces | 2× CAN, 5× UART + USB, I2C, Spektrum satellite |
| PWM outputs | 14 total (8 MAIN via IOMCU, 6 AUX via FMU) |
| Power monitors | 2× 6-pin ports |

---

## UART Mapping

| Serial | Port | Use |
|---|---|---|
| SERIAL0 | USB | GCS / MAVLink |
| SERIAL1 | UART2 — Telem1 | RFD / DoodleLabs telemetry (MAVLink2, 57600) |
| SERIAL2 | UART3 — Telem2 | HereLink (MAVLink2, 115200) |
| SERIAL3 | UART4 | Parachute (MAVLink2, 115200) |
| SERIAL4 | UART8 | Gremsy Gimbal (MAVLink2, 115200) |
| SERIAL5 | UART7 — CONS | ADS-B uAvionix (MAVLink2, 57600) |

---

## PWM Outputs

**MAIN 1–8** (IOMCU): PWM only, no DShot — motor outputs 1–8

| Group | Channels |
|---|---|
| Group 1 | MAIN 1–2 |
| Group 2 | MAIN 3–4 |
| Group 3 | MAIN 5–8 |

**AUX 1–6** (FMU): PWM + DShot capable

| Group | Channels |
|---|---|
| Group 1 | AUX 1–4 |
| Group 2 | AUX 5–6 |

> All channels in the same group must use the same output rate/type.

---

## AUX GPIO Pin Numbers

| AUX | GPIO |
|---|---|
| AUX1–AUX5 | 50–54 |
| AUX6 | 55 — `RELAY1_PIN 55` (Mjolnir trigger) |

---

## Loading Firmware

Board ships with ArduPilot-compatible bootloader. Load `.apj` via Mission Planner or QGroundControl.
