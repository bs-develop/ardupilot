#!/bin/bash
set -e

# Use GCC 10 (official ArduPilot 4.6.x toolchain) to avoid WDG from larger GCC 13 stack frames
export PATH="$HOME/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"

BOARDS=("H4H32N9_A6U828N_C463OP" "H8H32N9_A6U828N_C463OP")
OUTPUT_DIR="$(pwd)/output_fw"

mkdir -p "$OUTPUT_DIR"

echo "=== Cleaning build directory ==="
rm -rf build/
echo "Done."

# Build all bootloaders first to avoid waf config conflicts between boards
echo ""
echo "================================================================"
echo "  Building all bootloaders"
echo "================================================================"
for BOARD in "${BOARDS[@]}"; do
    echo "--- Bootloader: $BOARD ---"
    python3 Tools/scripts/build_bootloaders.py "$BOARD"
    rm -rf build/
done

# Now build all copter firmware
for BOARD in "${BOARDS[@]}"; do
    echo ""
    echo "================================================================"
    echo "  Building Copter: $BOARD"
    echo "================================================================"

    echo "--- Configure for Copter ---"
    ./waf configure --board "$BOARD" --no-submodule-update

    echo "--- Build Copter ---"
    ./waf copter

    echo "--- Copying outputs ---"
    cp "build/$BOARD/bin/arducopter.apj"  "$OUTPUT_DIR/${BOARD}.apj"
    cp "build/$BOARD/bin/arducopter.bin"  "$OUTPUT_DIR/${BOARD}.bin"
    cp "build/$BOARD/bin/arducopter_with_bl.hex" "$OUTPUT_DIR/${BOARD}_with_bl.hex"
    cp "Tools/bootloaders/${BOARD}_bl.bin" "$OUTPUT_DIR/${BOARD}_bl.bin"
    cp "Tools/bootloaders/${BOARD}_bl.hex" "$OUTPUT_DIR/${BOARD}_bl.hex"

    echo "Done: $BOARD"
done

echo ""
echo "================================================================"
echo "  All builds complete. Output files:"
echo "================================================================"
ls -lh "$OUTPUT_DIR/"
